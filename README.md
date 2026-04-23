<div align="center">

# 🩸 Non-Invasive Smart Blood Glucose Monitoring System
### Using Optical Sensors and Machine Learning

**Painless. Needle-free. Embedded AI. Empowering patients with real-time glucose insights — no blood required.**

</div>

---

## 📖 Overview

The **Non-Invasive Smart Blood Glucose Monitoring System** is a wearable embedded healthcare device that estimates blood glucose levels without any finger-prick or blood sampling. Using **photoplethysmography (PPG)**, infrared and red light are emitted into the fingertip through the **MAX30102 optical sensor**, and the reflected signal is processed to extract physiological features that correlate with blood glucose concentration.

A **machine learning regression model** runs directly on the **ESP32 microcontroller**, delivering real-time glucose predictions with personalized calibration — entirely offline, no cloud required.

> 🎬 **[Watch Video Demo →](YOUR_VIDEO_LINK_HERE)**

---

## 📸 Prototype

<div align="left">

<img width="350" height="450" alt="GlucoTrack Prototype" src="https://github.com/user-attachments/assets/0eb1def8-a7f4-4132-a822-81c77b1a6261" />

<br><br>

*The wearable device displaying a real-time reading: **100 mg/dL (ELEVATED)** — HR: 108 bpm · SpO₂: 98%*

</div>

---

## 🔍 Problems We Solve

| # | Problem |
|---|---------|
| 1 | Painful daily finger-prick tests creating a psychological barrier to consistent glucose monitoring |
| 2 | Ongoing cost and medical waste from disposable lancets and test strips |
| 3 | Skipped readings due to monitoring friction, leading to poor glucose control |
| 4 | Lack of accessible, affordable monitoring tools for diabetic patients in developing regions |
| 5 | Inter-subject variability making one-size-fits-all models unreliable for real users |

---

## ✨ Core Features

### 🤖 AI & Signal Processing Capabilities

| Feature | Description |
|---|---|
| 📡 **PPG Signal Acquisition** | Real-time optical signal capture from the MAX30102 sensor (IR 880nm + Red 660nm) |
| 🔧 **Noise Filtering** | Adaptive preprocessing to remove motion artifacts and baseline drift |
| 🧪 **Feature Extraction** | Derives IR Peak Amplitude, SDPPG b/a Ratio, and AC/DC Ratio from the waveform |
| 📐 **Feature Engineering** | Polynomial expansion to model nonlinear PPG-glucose relationships |
| 🧠 **ML Glucose Prediction** | Ridge Regression model trained and validated for real-time glucose estimation |
| 🎯 **Personalized Calibration** | Per-user offset correction converging after ~4–5 paired reference readings |
| 📊 **Performance Evaluation** | Validated using MAE, R² Score, and cross-validation across subjects |

### ⚙️ System Capabilities

- 🔬 Real-time glucose estimation on embedded hardware (no cloud, no internet)
- 🩸 Glucose classification — HYPO / NORMAL / ELEVATED / HIGH with range feedback
- 📈 Trend tracking — Rising / Stable / Falling based on sequential readings
- 🖥️ OLED display for instant on-device result feedback
- 💾 Local data logging via EEPROM (up to 194 records stored on-device)
- 🔋 Portable battery-powered operation (~10–15 hours per charge)

---

## 🔬 Machine Learning Pipeline

The AI pipeline is the core of the system, designed and implemented entirely for embedded real-time deployment.

### Extracted Features

| Feature | Description |
|---|---|
| **IR Peak Amplitude** | Strength of the pulsatile signal component |
| **SDPPG b/a Ratio** | Shape descriptor from the second derivative of the PPG wave |
| **AC/DC Ratio** | Pulsatile component relative to the DC baseline |

### Model

| Model | Role |
|---|---|
| **Ridge Regression** *(primary)* | Main prediction model — regularized linear regression with polynomial features |
| Random Forest | Comparison baseline |
| Support Vector Regression | Comparison baseline |
| Gradient Boosting | Comparison baseline |

### Evaluation Metrics

- **Mean Absolute Error (MAE)** — average prediction error in mg/dL
- **R² Score** — explained variance of the model
- **Cross-validation error** — generalization across different subjects

---

## 🩸 Glucose Classification

| Label | Range | Meaning |
|---|---|---|
| 🔵 **HYPO** | < 70 mg/dL | Hypoglycaemic — low blood sugar |
| 🟢 **NORMAL** | 70–100 mg/dL | Normal fasting range |
| 🟡 **ELEVATED** | 100–126 mg/dL | Pre-diabetic or post-meal range |
| 🔴 **HIGH** | > 126 mg/dL | Diabetic range or post-meal peak |

---

## 🛠️ Hardware

| Component | Details |
|---|---|
| 🧠 Microcontroller | ESP32 (dual-core, Wi-Fi/BLE capable) |
| 💡 Optical Sensor | MAX30102 (IR 880nm + Red 660nm dual LED) |
| 🖥️ Display | OLED Display (real-time result feedback) |
| 🔋 Battery | LiPo Battery + TP4056 Charging Module (~10–15 hrs) |
| 💾 Storage | EEPROM — calibration data & local reading log |

---

## 📊 Challenges & Solutions

| Challenge | Solution |
|---|---|
| Signal noise and motion artifacts affecting PPG quality | Robust adaptive preprocessing and filtering algorithms |
| Nonlinear relationship between PPG features and glucose levels | Ridge Regression with polynomial feature expansion |
| Inter-subject physiological variability | Personalized user-level calibration using paired reference readings |
| Embedded hardware resource constraints | Lightweight, optimized ML model for real-time ESP32 deployment |

---

## 🚀 Implementation Plan

1. **Literature Review & Requirement Analysis** — Study existing PPG-glucose research and define system specs
2. **Hardware Design & Procurement** — Assemble ESP32, MAX30102, OLED, and power circuit
3. **Data Collection** — Acquire PPG signals paired with reference glucometer readings
4. **Signal Processing** — Implement filtering, feature extraction, and polynomial engineering pipeline
5. **ML Model Training** — Train, compare, and validate regression models; select best performer
6. **Calibration System** — Implement and test the personalized per-user calibration mechanism
7. **Embedded Deployment** — Port optimized model to ESP32 for real-time inference
8. **Testing & Validation** — Evaluate accuracy, stability, and system performance end-to-end

---

## 🎯 Objectives

- ✅ Eliminate the need for painful invasive glucose tests
- ✅ Deliver real-time embedded AI inference with no cloud dependency
- ✅ Achieve practical glucose estimation accuracy using PPG-based ML
- ✅ Handle inter-subject variability through personalized calibration
- ✅ Produce a low-cost, portable prototype suitable for widespread use

---

## 🌍 Applications

- Home healthcare and self-monitoring for diabetic patients
- Clinic screening and patient triage workflows
- Wearable medical IoT devices
- Research platform for non-invasive biosensing

---

## ⚠️ Disclaimer

This system is a **research prototype** developed for academic and educational purposes. It has not been evaluated or certified by any medical regulatory authority. Glucose estimates must **never** be used to make clinical decisions, adjust medication, or replace laboratory testing. Always consult a qualified healthcare professional.

---

<div align="center">
  Made with ❤️ for better healthcare · Egypt 🇪🇬
</div>
