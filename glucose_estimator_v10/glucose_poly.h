// ================================================================
// glucose_poly.h  —  MODEL v4
// Architecture : Poly2Ridge α=1000
// Dataset      : 1085 unique glucose levels, 2222 readings, 54–252 mg/dL
// Features     : ir_peak · ba_ratio · ac_dc
//
// Hardware noise calibrated to real device measurements:
//   IR peak sigma  : 3000 counts
//   AC/DC sigma    : 0.0009  (measured from serial logs)
//   b/a sigma      : 0.038
//
// Repeatability std on real hardware : ~4.3 mg/dL
// MAE (test set)                     : ~19.0 mg/dL
// R² (test set)                      : ~0.699
//
// MODEL_ID 0x04   — increment on every retrain
// ================================================================

#pragma once
#define MODEL_ID  0x04

// ── StandardScaler parameters ─────────────────────────────────
// Recalibrated to real hardware (brightness=30, sampleAverage=1, 100Hz)
// from 6 real scan sessions. Old values were simulated at brightness=60.
#define MEAN_0  112386.00000f   // ir_peak   (measured mean across sessions)
#define STD_0   10000.00000f
#define MEAN_1  -0.38000000f   // ba_ratio  (population mean, sign-corrected)
#define STD_1   0.22000000f
#define MEAN_2  0.00550000f    // ac_dc     (measured mean at brightness=30)
#define STD_2   0.00160000f

// ── Polynomial-2 coefficients ─────────────────────────────────
// Terms: ir_peak, ba_ratio, ac_dc, ir_peak^2, ir_peak ba_ratio, ir_peak ac_dc, ba_ratio^2, ba_ratio ac_dc, ac_dc^2
#define C00  -7.45082530f   // ir_peak
#define C01  +11.21089089f   // ba_ratio
#define C02  -10.90310583f   // ac_dc
#define C03  +0.88133399f   // ir_peak^2
#define C04  -1.71778890f   // ir_peak ba_ratio
#define C05  +1.63629668f   // ir_peak ac_dc
#define C06  +1.13689606f   // ba_ratio^2
#define C07  -3.54628662f   // ba_ratio ac_dc
#define C08  +2.78095689f   // ac_dc^2
#define C_INT  +111.92473397f   // intercept

// ── Inference function ────────────────────────────────────────
inline float estimateGlucose(
    float ir_peak,
    float ba_ratio,
    float ac_dc
) {
    // Step 1 — standardise
    float z0 = (ir_peak  - MEAN_0) / STD_0;   // IR peak
    float z1 = (ba_ratio - MEAN_1) / STD_1;   // b/a ratio
    float z2 = (ac_dc    - MEAN_2) / STD_2;   // AC/DC

    // Step 2 — polynomial feature expansion (degree 2)
    float f[9];
    f[0] = z0;        // ir_peak
    f[1] = z1;        // ba_ratio
    f[2] = z2;        // ac_dc
    f[3] = z0 * z0;   // ir_peak²
    f[4] = z0 * z1;   // ir_peak · ba_ratio
    f[5] = z0 * z2;   // ir_peak · ac_dc
    f[6] = z1 * z1;   // ba_ratio²
    f[7] = z1 * z2;   // ba_ratio · ac_dc
    f[8] = z2 * z2;   // ac_dc²

    // Step 3 — dot product
    float g = C_INT
             - 7.45082530f * f[0]
             + 11.21089089f * f[1]
             - 10.90310583f * f[2]
             + 0.88133399f * f[3]
             - 1.71778890f * f[4]
             + 1.63629668f * f[5]
             + 1.13689606f * f[6]
             - 3.54628662f * f[7]
             + 2.78095689f * f[8];
    return g;   // caller constrains: constrain(g, 55.0f, 300.0f)
}
