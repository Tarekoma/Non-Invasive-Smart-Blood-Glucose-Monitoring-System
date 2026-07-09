"""
retrain.py — PPG Glucometer model retraining script
Compatible with glucose_estimator_v10 / glucose_poly.h

Features used by the current model:
  ir_peak   — average IR peak amplitude per beat  (~107k-122k counts)
  ba_ratio  — SDPPG b/a ratio per beat            (~-0.85 to 0.05)
  ac_dc     — AC/DC ratio per beat                (~0.002 to 0.015)

THREE MODES:

  1. Retrain on synthetic base dataset only (no real data yet):
       python retrain.py

  2. Retrain on your own real collected data only:
       python retrain.py --data my_data.csv

  3. Blend real data with synthetic prior (recommended when
     you have 20-50 real readings):
       python retrain.py --data my_data.csv --blend

REAL DATA CSV FORMAT:
  Two possible sources:

  A) Exported from device (DATA LOG -> EXPORT DATA):
       subject_id,ir_peak,ba_ratio,ac_dc,bpm,true_glucose
       01,114181.7,-0.5793,0.00543,96.1,127.0

  B) Manually assembled from Serial output + fingerstick:
       ir_peak,ba_ratio,ac_dc,true_glucose
       114181.7,-0.5793,0.00543,127.0

  The script accepts both formats automatically.
  Column 'true_glucose' must be the fingerstick value (exact, not a range).

COLLECTION GUIDELINES:
  - Minimum useful: 15-20 readings
  - Recommended: 40-50 readings over 3-4 weeks
  - Essential: spread across fasting (~80-95) and post-meal (~120-160)
  - Each reading: fingerstick first, then immediately scan within 2 min
  - Same finger, same placement every time
  - Do NOT include readings from sessions with poor waveform quality

AFTER RETRAINING:
  - Copy new glucose_poly.h to your Arduino sketch folder
  - Recompile and flash
  - Reset calibration (Menu -> Reset Cal) -- new model has different offset
  - Recalibrate with 3+ fresh paired readings

Requirements:
  pip install scikit-learn pandas numpy
"""

import argparse
import os
import sys
import numpy as np
import pandas as pd
from sklearn.linear_model import Ridge
from sklearn.preprocessing import PolynomialFeatures, StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import mean_absolute_error, r2_score
import warnings
warnings.filterwarnings('ignore')

# ================================================================
#  CONFIGURATION
# ================================================================
MODEL_ID_BASE   = 0x05          # increment manually on each retrain
OUTPUT_FILE     = "glucose_poly.h"
SYNTHETIC_FILE  = "dataset_v4.csv"
FEATURES        = ['ir_peak', 'ba_ratio', 'ac_dc']
TARGET          = 'glucose'
RIDGE_ALPHA     = 1000.0
POLY_DEGREE     = 2

# ================================================================
#  ARGUMENT PARSING
# ================================================================
parser = argparse.ArgumentParser(
    description='Retrain PPG glucose model (v10 compatible)',
    formatter_class=argparse.RawDescriptionHelpFormatter
)
parser.add_argument('--data',      type=str,   default=None)
parser.add_argument('--blend',     action='store_true')
parser.add_argument('--subject',   type=str,   default=None)
parser.add_argument('--alpha',     type=float, default=RIDGE_ALPHA)
parser.add_argument('--output',    type=str,   default=OUTPUT_FILE)
parser.add_argument('--model-id',  type=int,   default=MODEL_ID_BASE,
                    dest='model_id')
args = parser.parse_args()

# ================================================================
#  LOAD DATA
# ================================================================
def load_real_data(path, subject_filter=None):
    df = pd.read_csv(path)
    if 'true_glucose' in df.columns and 'glucose' not in df.columns:
        df = df.rename(columns={'true_glucose': 'glucose'})
    if subject_filter is not None and 'subject_id' in df.columns:
        df = df[df['subject_id'].astype(str).str.zfill(2) == str(subject_filter).zfill(2)]
        if len(df) == 0:
            orig = pd.read_csv(path)
            print(f"ERROR: subject '{subject_filter}' not found.")
            print(f"Available: {orig['subject_id'].unique()}")
            sys.exit(1)
        print(f"  Filtered to subject {subject_filter}: {len(df)} rows")
    missing = [f for f in FEATURES + ['glucose'] if f not in df.columns]
    if missing:
        print(f"ERROR: Missing columns: {missing}")
        sys.exit(1)
    return df[FEATURES + ['glucose']].dropna()

def load_synthetic(path):
    if not os.path.exists(path):
        print(f"ERROR: {path} not found. Place dataset_v4.csv in same folder.")
        sys.exit(1)
    df = pd.read_csv(path)
    df = df.rename(columns={'ac_dc_ratio':'ac_dc','true_glucose':'glucose'})
    missing = [f for f in FEATURES + ['glucose'] if f not in df.columns]
    if missing:
        print(f"ERROR: Synthetic dataset missing columns: {missing}")
        sys.exit(1)
    return df[FEATURES + ['glucose']].dropna()

print("\n" + "="*60)
print("PPG Glucometer — Model Retraining (v10)")
print("="*60)

if args.data is not None:
    print(f"\nLoading real data: {args.data}")
    df_real = load_real_data(args.data, args.subject)
    print(f"  Rows:    {len(df_real)}")
    print(f"  Glucose: {df_real['glucose'].min():.1f} - {df_real['glucose'].max():.1f} mg/dL")
    if len(df_real) < 10:
        print(f"  WARNING: only {len(df_real)} readings - minimum recommended is 15")
    if args.blend:
        print(f"\nLoading synthetic prior: {SYNTHETIC_FILE}")
        df_synth = load_synthetic(SYNTHETIC_FILE)
        df_real_w = pd.concat([df_real]*5, ignore_index=True)
        df = pd.concat([df_synth, df_real_w], ignore_index=True).sample(
             frac=1, random_state=42).reset_index(drop=True)
        mode_label = f"BLEND ({len(df_synth)} synth + {len(df_real)}x5 real)"
    else:
        df = df_real
        mode_label = f"REAL ONLY ({len(df_real)} readings)"
else:
    print(f"\nLoading synthetic base: {SYNTHETIC_FILE}")
    df = load_synthetic(SYNTHETIC_FILE)
    mode_label = f"SYNTHETIC ({len(df)} rows)"

print(f"\nMode:  {mode_label}")
print(f"Total: {len(df)} samples  Alpha: {args.alpha}")

print(f"\nFeature correlations with glucose:")
for f in FEATURES:
    r = df[f].corr(df['glucose'])
    bar = ('+'if r>=0 else '-')*int(abs(r)*30)
    print(f"  {f:<12}  r={r:+.4f}  {bar}")

# ================================================================
#  TRAIN
# ================================================================
X = df[FEATURES].values.astype(float)
y = df['glucose'].values.astype(float)
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=42)

pipe = Pipeline([
    ('sc',   StandardScaler()),
    ('poly', PolynomialFeatures(degree=POLY_DEGREE, include_bias=False)),
    ('r',    Ridge(alpha=args.alpha))
])
pipe.fit(X_tr, y_tr)

y_pred  = np.clip(pipe.predict(X_te), 40, 400)
mae_val = mean_absolute_error(y_te, y_pred)
r2_val  = r2_score(y_te, y_pred)
cv_mae  = -cross_val_score(pipe, X, y, cv=5,
              scoring='neg_mean_absolute_error').mean()

print(f"\nPerformance:")
print(f"  MAE (test):  {mae_val:.2f} mg/dL")
print(f"  MAE (5-CV):  {cv_mae:.2f} mg/dL")
print(f"  R2:          {r2_val:.4f}")
print(f"  Range:       {y_pred.min():.0f} - {y_pred.max():.0f} mg/dL")

print(f"\nPer-zone MAE:")
for lo, hi, name in [(40,70,'Hypo'),(70,100,'Normal'),(100,126,'Elevated'),
                      (126,180,'High'),(180,400,'Very High')]:
    mask = (y_te>=lo)&(y_te<hi)
    if mask.sum()>0:
        print(f"  {name:<12}: {mean_absolute_error(y_te[mask],y_pred[mask]):>6.1f} mg/dL  (n={mask.sum()})")

# ================================================================
#  EXPORT glucose_poly.h
# ================================================================
sc        = pipe.named_steps['sc']
poly      = pipe.named_steps['poly']
ridge     = pipe.named_steps['r']
means     = sc.mean_
stds      = sc.scale_
coefs     = ridge.coef_
intercept = float(ridge.intercept_)
feat_names = poly.get_feature_names_out(FEATURES)
model_id  = args.model_id

lines = [
    "// ================================================================",
    "// glucose_poly.h",
    "// Auto-generated by retrain.py — DO NOT EDIT MANUALLY",
    "//",
    f"// Mode     : {mode_label}",
    f"// Samples  : {len(df)}",
    f"// Glucose  : {df['glucose'].min():.0f} - {df['glucose'].max():.0f} mg/dL",
    f"// MAE      : {mae_val:.2f} mg/dL (test)   {cv_mae:.2f} mg/dL (CV)",
    f"// R2       : {r2_val:.4f}",
    f"// Alpha    : {args.alpha}  Poly: {POLY_DEGREE}",
    "//",
    "// Features: ir_peak, ba_ratio, ac_dc",
    f"// MODEL_ID 0x{model_id:02X}",
    "// ================================================================",
    "",
    "#pragma once",
    f"#define MODEL_ID  0x{model_id:02X}",
    "",
    "// StandardScaler",
]
for i, f in enumerate(FEATURES):
    lines.append(f"#define MEAN_{i}  {means[i]:.8f}f   // {f}")
    lines.append(f"#define STD_{i}   {stds[i]:.8f}f")

lines += ["", "// Poly-2 Ridge coefficients"]
for i, (fn, c) in enumerate(zip(feat_names, coefs)):
    lines.append(f"#define C{i:02d}  {c:+.8f}f   // {fn}")
lines.append(f"#define C_INT  {intercept:+.8f}f   // intercept")

lines += [
    "",
    "inline float estimateGlucose(",
    "    float ir_peak,",
    "    float ba_ratio,",
    "    float ac_dc",
    ") {",
    "    float z0 = (ir_peak  - MEAN_0) / STD_0;",
    "    float z1 = (ba_ratio - MEAN_1) / STD_1;",
    "    float z2 = (ac_dc    - MEAN_2) / STD_2;",
    "    float f[9];",
    "    f[0]=z0; f[1]=z1; f[2]=z2;",
    "    f[3]=z0*z0; f[4]=z0*z1; f[5]=z0*z2;",
    "    f[6]=z1*z1; f[7]=z1*z2; f[8]=z2*z2;",
    "    return C_INT",
]
for i in range(min(9, len(coefs))):
    sign = "+" if coefs[i] >= 0 else "-"
    lines.append(f"         {sign} C{i:02d}*f[{i}]")
lines[-1] += ";"
lines.append("}")

with open(args.output, "w") as fh:
    fh.write("\n".join(lines) + "\n")

print(f"\n{'='*60}")
print(f"Exported : {args.output}  (MODEL_ID 0x{model_id:02X})")
print(f"{'='*60}")
print(f"\nNext steps:")
print(f"  1. Copy {args.output} to Arduino sketch folder")
print(f"  2. Recompile and flash")
print(f"  3. Menu -> Reset Cal  (model changed, recalibrate)")
print(f"  4. Do 3+ paired readings to recalibrate")
if args.data is None:
    print(f"\n  When you have real data:")
    print(f"    python retrain.py --data device_export.csv --blend")
    print(f"  For one subject only:")
    print(f"    python retrain.py --data device_export.csv --subject 01")
