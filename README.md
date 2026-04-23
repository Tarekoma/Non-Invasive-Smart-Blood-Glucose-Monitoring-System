<div align="center">

# 💉 Non-Invasive Smart Blood Glucose Monitoring System
**Painless. Needle-free. Fully offline. Empowering patients and clinics with real-time glucose insights.**

</div>

---

## 📖 Overview

**GlucoTrack** is a wearable health device paired with a Flutter mobile application that estimates blood glucose levels without a single needle. Using photoplethysmography (PPG), infrared and red light pass through the fingertip and the reflected signal is analyzed to extract physiological features that correlate with blood glucose concentration.

The hardware is built around an **ESP32-C3 Mini** microcontroller and a **MAX30102** optical sensor, communicating wirelessly with the app over **Bluetooth Low Energy**. Everything runs completely offline — no internet, no cloud, no subscription.

> 🎬 **[Watch Video Demo →](https://1drv.ms/v/c/47438efdb3ee2559/IQA0FAMxoAtWQqJQIaDrOJIxAU9L4il1BBElhhdxh0lofC8?e=2vuCNs)**

---

## 🔍 Problems We Solve

| # | Problem |
|---|---------|
| 1 | Painful daily fingerstick tests creating a psychological barrier to consistent glucose monitoring |
| 2 | Ongoing cost and medical waste from disposable lancets and test strips |
| 3 | Skipped readings due to monitoring friction, leading to poor glucose control |
| 4 | Lack of accessible, affordable continuous monitoring tools for diabetic patients |
| 5 | No fast multi-patient workflow tool for clinic nurses to screen glucose at scale |

---

## ✨ Core Features

### 🔬 Measurement Capabilities

| Metric | Range | Method |
|---|---|---|
| 🩸 **Blood Glucose** | 40–400 mg/dL | Ridge Regression on 3 PPG features |
| ❤️ **Heart Rate** | 40–190 BPM | Inter-beat interval detection |
| 🫁 **SpO₂** | 0–100% | Red/IR ratio (R-ratio method) |
| 📈 **Glucose Trend** | Rising / Stable / Falling | Median-smoothed linear regression |

### 📱 App Capabilities

- 🔵 Real-time BLE streaming from ESP32-C3 + MAX30102 sensor
- 🩸 Glucose classification — HYPO / NORMAL / ELEVATED / HIGH with trend arrow
- 📊 History charts with trend analysis across the last 5 readings
- 🏥 Dual app modes — Personal (patient self-monitoring) and Clinic (nurse-operated)
- 📄 PDF report export with full reading history
- 🌙 Full dark mode support on every screen
- 🌐 Arabic RTL and English with complete i18n support
- 💾 100% offline — all data stored locally, nothing leaves the device

---

## 🩸 Glucose Classification

| Label | Range | Meaning |
|---|---|---|
| 🔵 **HYPO** | < 70 mg/dL | Hypoglycaemic — low blood sugar |
| 🟢 **NORMAL** | 70–100 mg/dL | Normal fasting range |
| 🟡 **ELEVATED** | 100–126 mg/dL | Pre-diabetic range or post-meal |
| 🔴 **HIGH** | > 126 mg/dL | Diabetic range or post-meal peak |

---

## 🖥️ App Modes

| Mode | Users | Description |
|---|---|---|
| 👤 **Personal** | Patients | 5-tab navigation — dashboard, history, scan, reports, settings |
| 🏥 **Clinic** | Nurses / Medical Staff | Multi-patient workflow, fast scan-and-assign, per-patient history |

---

## ⚙️ How It Works

The MAX30102 sensor emits infrared (880nm) and red (660nm) light into the fingertip. Three features are extracted from the reflected waveform and fed into a trained regression model:

1. **IR Peak Amplitude** — strength of the pulsatile signal
2. **SDPPG b/a Ratio** — shape feature from the second derivative of the PPG wave
3. **AC/DC Ratio** — pulsatile component relative to the DC baseline

A **personal calibration step** corrects the systematic offset between the model's raw output and the user's true glucose level. Calibration converges to stable accuracy after 4–5 paired readings with a standard fingerstick glucometer.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| 📱 Framework | Flutter 3.x |
| 🏗️ Architecture | Feature-First MVVM |
| 🔄 State Management | Riverpod 2.x (AsyncNotifier / Notifier) |
| 🗄️ Database | sqflite + path (local only) |
| ⚙️ Settings | shared_preferences |
| 🔵 BLE | flutter_blue_plus |
| 📊 Charts | fl_chart |
| 📄 PDF | pdf + printing (compute isolate) |
| 📐 Responsive UI | flutter_screenutil |
| 🧭 Navigation | go_router |
| 🌐 i18n | intl (Arabic RTL + English) |

---

## 🔧 Hardware

| Component | Details |
|---|---|
| 🧠 Microcontroller | ESP32-C3 Mini (RISC-V, 160MHz, 400KB SRAM) |
| 💡 Sensor | MAX30102 (IR 880nm + Red 660nm dual LED) |
| 🖥️ Display | SSD1306 0.96" OLED 128×64 |
| 🔋 Battery | 220mAh LiPo + TP4056 charger (~10–15 hrs) |
| 🔌 Charging | USB-C via TP4056 module (30–45 min) |
| 💾 Storage | 4KB EEPROM — calibration + data log (up to 194 records) |

---

## 🚀 Development Phases

1. **Project Setup** — theme, router, DB schema, app skeleton
2. **BLE Layer** — mock + real hardware scan flow, BLE service abstraction
3. **Readings Feature** — model, repository, provider, all views
4. **Clinic Mode** — patient management, sessions, fast workflow
5. **Reports & Charts** — PDF export, history charts, trend engine
6. **i18n & Polish** — Arabic RTL, dark mode audit, final QA

---

## 🎯 Architecture Rules

- ✅ No backend, no Firebase, no REST API, no cloud — 100% on-device
- ✅ Every DB call is async/await — never synchronous
- ✅ BLE uses streams only — never `Timer.periodic` polling
- ✅ PDF always runs in a `compute()` isolate — UI never blocks
- ✅ Colors from `Theme.of(context).colorScheme` — never hardcoded
- ✅ Sizes via `.h` / `.w` / `.sp` — never hardcoded px values
- ✅ Zero business logic inside any `build()` method

---

## 👥 Team

| Name | Name (Arabic) |
|---|---|
| Ahmed Bahaa-Eldein Naoman | أحمد بهاء الدين نعمان |

> 👨‍🏫 **Supervised by:** Dr. [Supervisor Name]

---

## ⚠️ Disclaimer

This device is a **research prototype** developed for academic and educational purposes. It has not been evaluated or certified by any medical regulatory authority. Glucose estimates should **never** be used to make medical decisions, adjust medication, or replace clinical laboratory testing. Always consult a qualified healthcare professional.

---

<div align="center">
  Made with ❤️ for better healthcare · Egypt 🇪🇬
</div>
