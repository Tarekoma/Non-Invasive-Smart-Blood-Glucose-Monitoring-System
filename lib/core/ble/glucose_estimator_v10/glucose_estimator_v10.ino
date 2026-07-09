#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <EEPROM.h>
#include "MAX30105.h"
#include "glucose_poly.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ================================================================
//  ENUMS & STRUCTS — must be first, before any function that uses
//  them, because the Arduino IDE inserts auto-generated prototypes
//  at the very top of the translation unit.
// ================================================================
#define BTN_SHORT_MAX_MS   500
#define BTN_LONG_MIN_MS   1500
#define BTN_DOUBLE_GAP_MS  400
enum BtnEvent { BTN_NONE, BTN_SHORT, BTN_DOUBLE, BTN_LONG };

enum DeviceState {
  ST_SPLASH, ST_IDLE, ST_FINGER_CHECK, ST_SCANNING,
  ST_ABORTED, ST_REJECTED, ST_RESULT, ST_MENU,
  ST_CAL_PROMPT, ST_CAL_RANGE, ST_CAL_CONFIRM, ST_CAL_SAVED,
  ST_LOG_PROMPT, ST_LOG_SCAN,
  ST_LOG_D1, ST_LOG_D2, ST_LOG_D3, ST_LOG_CONFIRM, ST_LOG_SAVED,
  ST_SUBJ_D1, ST_SUBJ_D2, ST_SUBJ_CONFIRM, ST_SUBJ_SAVED
};

// ================================================================
//  HARDWARE
// ================================================================
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT  64
#define BTN_PIN        10
#define EEPROM_SIZE   4096

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
MAX30105          particleSensor;

// ================================================================
//  BLUETOOTH LE  — GlucoTrack app protocol
//  Service:      00001523-1212-efde-1523-785feabcd123
//  Cmd char:     00001524-...  WRITE  — app writes 0x01 to start a scan
//  Result char:  00001525-...  NOTIFY — pushed once, only from finalizeScan()
//  These UUIDs must match lib/core/ble/glucose_estimator_v10/real_ble_service.dart
// ================================================================
#define BLE_SERVICE_UUID "00001523-1212-efde-1523-785feabcd123"
#define BLE_CMD_UUID     "00001524-1212-efde-1523-785feabcd123"
#define BLE_RESULT_UUID  "00001525-1212-efde-1523-785feabcd123"

BLEServer*         bleServer          = nullptr;
BLECharacteristic* bleResultChar      = nullptr;
BLECharacteristic* bleCmdChar         = nullptr;
bool               bleClientConnected = false;
// Set only from the BLE write callback (runs on the BLE stack's own task);
// consumed from loop() so state transitions / I2C / display access stay
// on the main task, same as button-driven transitions.
volatile bool      bleStartRequested  = false;

class GlucoTrackServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* server) override {
    bleClientConnected = true;
    Serial.println("BLE: client connected");
  }
  void onDisconnect(BLEServer* server) override {
    bleClientConnected = false;
    Serial.println("BLE: client disconnected");
    BLEDevice::startAdvertising();   // allow reconnect without a reboot
    Serial.println("BLE: advertising restarted");
  }
};

class GlucoTrackCmdCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    std::string v = c->getValue();
    if (!v.empty() && (uint8_t)v[0] == 0x01) {
      Serial.println("BLE: measurement command received");
      bleStartRequested = true;
    }
  }
};

void setupBLE() {
  BLEDevice::init("GlucoTrack");
  bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new GlucoTrackServerCallbacks());

  BLEService* svc = bleServer->createService(BLE_SERVICE_UUID);

  bleCmdChar = svc->createCharacteristic(
      BLE_CMD_UUID, BLECharacteristic::PROPERTY_WRITE);
  bleCmdChar->setCallbacks(new GlucoTrackCmdCallbacks());

  bleResultChar = svc->createCharacteristic(
      BLE_RESULT_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  bleResultChar->addDescriptor(new BLE2902());

  svc->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(BLE_SERVICE_UUID);
  adv->setScanResponse(true);
  BLEDevice::startAdvertising();

  Serial.println("BLE: initialized");
  Serial.println("BLE: advertising started");
}

// Sends the just-completed finalizeScan() result to the app.
// Called exactly once per real measurement — never on a timer, never with
// synthetic data. No-ops silently if no phone is connected.
void bleSendResult(float glucose, float bpm, float spo2, uint8_t calState) {
  if (!bleClientConnected || bleResultChar == nullptr) {
    Serial.println("BLE: no client connected - result not sent");
    return;
  }
  char payload[96];
  snprintf(payload, sizeof(payload),
           "{\"g\":%.1f,\"hr\":%.1f,\"spo2\":%.1f,\"cal\":%d}",
           glucose, bpm, spo2, calState);
  bleResultChar->setValue((uint8_t*)payload, strlen(payload));
  bleResultChar->notify();
  Serial.print("BLE: sending glucose value: "); Serial.println(payload);
  Serial.println("BLE: notification sent");
}

// ================================================================
//  OLED AUTO-OFF
//  Screen turns off after 30s of no button activity.
//  First button press wakes screen only — action is swallowed.
//  Never dims during scanning or finger check (natural wait states).
// ================================================================
#define OLED_TIMEOUT_MS  30000UL

bool          oledOn         = true;
unsigned long lastActivityMs = 0;

// ================================================================
//  SENSOR POWER
//  Sensor runs only during ST_FINGER_CHECK, ST_SCANNING,
//  ST_LOG_SCAN. Shuts down in ST_IDLE to save battery.
//  Wake/sleep only called from loop() level — never from inside
//  finalizeScan() or processScan() to avoid I2C bus conflicts.
// ================================================================
bool sensorRunning = false;

void sensorWake() {
  if (!sensorRunning) {
    particleSensor.wakeUp();
    delay(10);            // brief settle — sensor needs ~10ms after wakeup
    sensorRunning = true;
  }
}

void sensorShutdown() {
  if (sensorRunning) {
    // Flush FIFO before shutdown so no stale data remains
    particleSensor.check();
    while (particleSensor.available()) particleSensor.nextSample();
    particleSensor.shutDown();
    sensorRunning = false;
  }
}

// ================================================================
//  SCAN PARAMETERS
// ================================================================
const unsigned long COLLECTION_MS      = 20000;
const unsigned long STABILIZE_MS       =  4000;
const float         MAX_BPM_DEV        =  35.0f;   // was 25 — more forgiving beat-to-beat variation
const int           MIN_BEATS          =     6;
const int           SAMPLE_RATE        =   100;

// ================================================================
//  BUTTON DRIVER
// ================================================================

DeviceState state     = ST_SPLASH;
DeviceState nextState = ST_SPLASH;   // used for timed transitions

unsigned long stateEnteredAt = 0;    // millis() when current state was entered

// ── transition helper ──────────────────────────────────────────
void goTo(DeviceState s) {
  // Shut sensor down as soon as scan results are ready —
  // ST_RESULT and ST_LOG_CONFIRM are the earliest safe points
  // (scan complete, I2C idle). Also shut down on ST_IDLE as fallback.
  if ((s == ST_IDLE || s == ST_RESULT || s == ST_LOG_CONFIRM) && sensorRunning) {
    sensorShutdown();
  }
  state          = s;
  stateEnteredAt = millis();
  lastActivityMs = millis();
}

unsigned long stateAge() { return millis() - stateEnteredAt; }

// ================================================================
//  BUTTON DRIVER  (enum declared at top — see above)
// ================================================================
BtnEvent readButton() {
  static bool          lastState    = HIGH;
  static unsigned long pressedAt   = 0;
  static unsigned long releasedAt  = 0;
  static int           pending     = 0;

  bool state_now = digitalRead(BTN_PIN);   // LOW = pressed
  unsigned long now = millis();
  BtnEvent evt = BTN_NONE;

  // Falling edge — press starts
  if (lastState == HIGH && state_now == LOW) {
    pressedAt = now;
  }

  // Rising edge — press ends
  if (lastState == LOW && state_now == HIGH) {
    unsigned long held = now - pressedAt;
    if (held >= BTN_LONG_MIN_MS) {
      evt     = BTN_LONG;
      pending = 0;
    } else {
      pending++;
      releasedAt = now;
    }
  }

  // Resolve pending short(s) once double-gap expires
  if (pending > 0 && state_now == HIGH && (now - releasedAt) > BTN_DOUBLE_GAP_MS) {
    evt     = (pending >= 2) ? BTN_DOUBLE : BTN_SHORT;
    pending = 0;
  }

  lastState = state_now;
  return evt;
}

// ================================================================
//  SCAN STATE  (unchanged from v5)
// ================================================================
long  lastBeatMs    = 0;
float bpmSum        = 0;
int   beatCount     = 0;
float lastBpm       = 0;
int   errorCounter  = 0;

int  xPos = 0, lastY = 30;
long minIR = 200000, maxIR = 0;

long  currentPeakIR   = 0;
long  currentValleyIR = 1000000L;
long  peakSampleIdx   = 0;
long  valleySampleIdx = 0;
long  beatStartMs     = 0;
int   beatSampleCount = 0;

#define BEAT_BUF_LEN 80
static long beatBuf[BEAT_BUF_LEN];
static int  beatBufLen = 0;

float sum_ir_peak  = 0;
float sum_ba_ratio = 0;
float sum_ac_dc    = 0;

// ── SpO2 — Red channel, read in parallel with IR ───────────────
// currentRedValue set in loop() from getFIFORed() before nextSample()
// Red peak/valley tracked per-beat same as IR, reset at same point
// R = avg(AC_red/DC_red) / avg(AC_ir/DC_ir)
// SpO2 ≈ 110 - 25*R  (empirical linear, clipped 80-100%)
long  currentRedValue  = 0;      // set each loop iteration from FIFO
long  currentPeakRed   = 0;
long  currentValleyRed = 1000000L;
float sum_red_ratio    = 0;
float lastSpO2         = -1.0f;  // shown on result screen, -1 = no data

unsigned long scanStartMs = 0;   // set in startNewScan()
bool          isCollecting = false;  // used by ST_LOG_SCAN only

// last completed scan result (for IDLE screen)
float lastGlucose  = -1;
float lastBpmFinal = -1;

// ================================================================
//  FINGER CHECK STATE
// ================================================================
#define FINGER_CONFIRM_N   5       // consecutive samples above threshold
#define FINGER_IR_THRESH   50000L
#define FINGER_TIMEOUT_MS  10000

int  fingerConfirmCount = 0;

// ================================================================
//  STEEP-DROP BEAT DETECTOR  (verbatim from v5)
// ================================================================
#define SLOPE_WIN    8
#define ADAPT_BEATS  8

static long  sd_buf[SLOPE_WIN];
static int   sd_idx = 0, sd_filled = 0;
static float sd_drops[ADAPT_BEATS];
static int   sd_drop_idx = 0, sd_drop_filled = 0;
const  float DROP_RATIO        = 0.30f;   // was 0.35 — fires on shallower drops
const  float SD_MIN_SLOPE      = 40.0f;   // was 60.0 — lower absolute floor
static unsigned long sd_last_beat_ms = 0;
const  unsigned long SD_REFRACTORY_MS = 400;   // was 500 — allows up to 150 BPM
static bool  sd_in_drop = false;

void sd_reset() {
  for (int i = 0; i < SLOPE_WIN;   i++) sd_buf[i]   = 0;
  for (int i = 0; i < ADAPT_BEATS; i++) sd_drops[i] = 0;
  sd_idx = sd_filled = sd_drop_idx = sd_drop_filled = 0;
  sd_last_beat_ms = 0;
  sd_in_drop = false;
}

bool sd_update(long irValue) {
  sd_buf[sd_idx] = irValue;
  sd_idx = (sd_idx + 1) % SLOPE_WIN;
  if (sd_filled < SLOPE_WIN) { sd_filled++; return false; }

  const int   N      = SLOPE_WIN;
  const float sum_x  = N * (N-1) / 2.0f;
  const float sum_x2 = N * (N-1) * (2*N-1) / 6.0f;
  const float denom  = N * sum_x2 - sum_x * sum_x;
  float sum_xy = 0, sum_y = 0;
  for (int i = 0; i < N; i++) {
    int bi = (sd_idx + i) % N;
    sum_xy += i * sd_buf[bi];
    sum_y  += sd_buf[bi];
  }
  float slope = (N * sum_xy - sum_x * sum_y) / denom;

  float avg_drop = 0;
  if (sd_drop_filled > 0) {
    int cnt = min(sd_drop_filled, ADAPT_BEATS);
    for (int i = 0; i < cnt; i++) avg_drop += sd_drops[i];
    avg_drop /= cnt;
  }
  float threshold = max(avg_drop * DROP_RATIO, SD_MIN_SLOPE);
  bool  dropping  = (slope < -threshold);
  bool  beat      = false;
  unsigned long now = millis();

  if (dropping && !sd_in_drop && (now - sd_last_beat_ms) > SD_REFRACTORY_MS) {
    beat            = true;
    sd_last_beat_ms = now;
    sd_drops[sd_drop_idx] = -slope;
    sd_drop_idx = (sd_drop_idx + 1) % ADAPT_BEATS;
    if (sd_drop_filled < ADAPT_BEATS) sd_drop_filled++;
  }
  sd_in_drop = dropping;
  return beat;
}

// ================================================================
//  SDPPG b/a RATIO  (verbatim from v5)
// ================================================================
float computeBA(long* buf, int n) {
  if (n < 6) return -0.38f;
  float minAmp = (float)(currentPeakIR - currentValleyIR) * 0.003f;

  float a_val = 0.0f;
  int   a_idx = 1;
  int   half  = n / 2;
  for (int i = 1; i < half; i++) {
    float d2 = (float)(buf[i+1] - 2L*buf[i] + buf[i-1]);
    if (d2 > a_val) { a_val = d2; a_idx = i; }
  }
  if (a_val < minAmp) return -0.38f;

  float b_val = 0.0f;
  for (int i = a_idx + 1; i < n - 1; i++) {
    float d2 = (float)(buf[i+1] - 2L*buf[i] + buf[i-1]);
    if (d2 < b_val) b_val = d2;
    if (i > a_idx + 3 && d2 > 0.0f) break;
  }
  return constrain(b_val / a_val, -0.85f, 0.05f);
}

// ================================================================
//  CALIBRATION  (EEPROM-backed, offset-only weighted average)
//  Linear calibration removed — the raw model output variance is
//  too small (~6 counts) to reliably fit a slope. Offset averaging
//  across multiple readings is more stable and honest.
// ================================================================
// EEPROM layout:
//   0      magic    0xCA
//   1      calState  0=uncalibrated  1=calibrated
//   2-5    calOffset float
//   6      calN      uint8  (readings accumulated, capped at 8)
//   7      CRC8 of bytes 0-6

#define CAL_MAGIC       0xCA
#define CAL_ADDR_MAGIC   0
#define CAL_ADDR_STATE   1
#define CAL_ADDR_OFFSET  2
#define CAL_ADDR_N       6
#define CAL_ADDR_CRC     7
#define CAL_TOTAL_BYTES  8

uint8_t calState  = 0;
float   calOffset = 0.0f;
uint8_t calN      = 0;

uint8_t crc8(uint8_t* data, int len) {
  uint8_t crc = 0xFF;
  for (int i = 0; i < len; i++) {
    crc ^= data[i];
    for (int b = 0; b < 8; b++)
      crc = (crc & 0x80) ? (crc << 1) ^ 0x31 : (crc << 1);
  }
  return crc;
}

void calWriteFloat(int addr, float v) {
  uint8_t* p = (uint8_t*)&v;
  for (int i = 0; i < 4; i++) EEPROM.write(addr + i, p[i]);
}

float calReadFloat(int addr) {
  float v; uint8_t* p = (uint8_t*)&v;
  for (int i = 0; i < 4; i++) p[i] = EEPROM.read(addr + i);
  return v;
}

void calSaveEEPROM() {
  EEPROM.write(CAL_ADDR_MAGIC,  CAL_MAGIC);
  EEPROM.write(CAL_ADDR_STATE,  calState);
  calWriteFloat(CAL_ADDR_OFFSET, calOffset);
  EEPROM.write(CAL_ADDR_N,      calN);
  uint8_t buf[CAL_TOTAL_BYTES - 1];
  for (int i = 0; i < CAL_TOTAL_BYTES - 1; i++) buf[i] = EEPROM.read(i);
  EEPROM.write(CAL_ADDR_CRC, crc8(buf, CAL_TOTAL_BYTES - 1));
  EEPROM.commit();
}

void calLoadEEPROM() {
  if (EEPROM.read(CAL_ADDR_MAGIC) != CAL_MAGIC) return;
  uint8_t buf[CAL_TOTAL_BYTES - 1];
  for (int i = 0; i < CAL_TOTAL_BYTES - 1; i++) buf[i] = EEPROM.read(i);
  if (crc8(buf, CAL_TOTAL_BYTES - 1) != EEPROM.read(CAL_ADDR_CRC)) return;

  calState  = EEPROM.read(CAL_ADDR_STATE);
  calOffset = calReadFloat(CAL_ADDR_OFFSET);
  calN      = EEPROM.read(CAL_ADDR_N);

  // Sanity check
  if (calState > 1 || fabsf(calOffset) > 150.0f) {
    calState = 0; calOffset = 0.0f; calN = 0;
    Serial.println("CAL: corrupt EEPROM reset");
  }
}

float applyCalibration(float raw) {
  if (calState == 0) return raw;
  return raw + calOffset;
}

// Weighted running average of offsets.
// New reading has weight 2, existing average has weight min(calN, 4).
// This means early readings are quickly overridden; later ones stabilize.
float lastRawGlucose = 0;

void calAddReading(float trueGlucose) {
  float raw = lastRawGlucose;
  if (raw < 40.0f || raw > 400.0f) {
    Serial.println("CAL: no valid scan — ignored"); return;
  }
  float newOffset = trueGlucose - raw;
  Serial.print("CAL: raw="); Serial.print(raw, 1);
  Serial.print(" true=");    Serial.print(trueGlucose, 1);
  Serial.print(" newOff=");  Serial.print(newOffset, 2);
  Serial.print(" calN=");    Serial.println(calN);

  if (calState == 0) {
    calOffset = newOffset;
    calN      = 1;
    calState  = 1;
  } else {
    float w_old = (float)min((int)calN, 4);
    float w_new = 2.0f;
    calOffset = (calOffset * w_old + newOffset * w_new) / (w_old + w_new);
    calN      = (uint8_t)min((int)calN + 1, 8);
  }
  Serial.print("CAL: offset="); Serial.print(calOffset, 2);
  Serial.print(" calN=");       Serial.println(calN);
  calSaveEEPROM();
}

// ================================================================
//  DATA LOG  (EEPROM-backed, serial CSV export)
// ================================================================
// EEPROM layout (starts at byte 8, right after calibration block):
//   8      log magic  0xDA
//   9      count_lo   uint8  (low byte of record count)
//   10     count_hi   uint8  (high byte)
//   11     subject_id uint8  (01-99)
//   12     header CRC8 of bytes 8-11
//   13+    records, 21 bytes each:
//            ir_peak  float  4
//            ba_ratio float  4
//            ac_dc    float  4
//            bpm      float  4
//            glucose  float  4  (exact user-entered value)
//            subj_id  uint8  1
//          total: 21 bytes/record × 194 records = 4074 bytes → fits in 4096

#define LOG_MAGIC        0xDA
#define LOG_ADDR_MAGIC    8
#define LOG_ADDR_CNT_LO   9
#define LOG_ADDR_CNT_HI  10
#define LOG_ADDR_SUBJ    11
#define LOG_ADDR_HDR_CRC 12
#define LOG_DATA_START   13
#define LOG_RECORD_SIZE  21
#define LOG_MAX_RECORDS  194   // (4096-13) / 21

uint16_t logCount   = 0;
uint8_t  subjId     = 1;       // default subject 01

void logWriteFloat(int addr, float v) {
  uint8_t* p = (uint8_t*)&v;
  for (int i = 0; i < 4; i++) EEPROM.write(addr + i, p[i]);
}

float logReadFloat(int addr) {
  float v; uint8_t* p = (uint8_t*)&v;
  for (int i = 0; i < 4; i++) p[i] = EEPROM.read(addr + i);
  return v;
}

void logSaveHeader() {
  EEPROM.write(LOG_ADDR_MAGIC,   LOG_MAGIC);
  EEPROM.write(LOG_ADDR_CNT_LO,  logCount & 0xFF);
  EEPROM.write(LOG_ADDR_CNT_HI,  (logCount >> 8) & 0xFF);
  EEPROM.write(LOG_ADDR_SUBJ,    subjId);
  // CRC over bytes 8-11
  uint8_t buf[4];
  for (int i = 0; i < 4; i++) buf[i] = EEPROM.read(LOG_ADDR_MAGIC + i);
  EEPROM.write(LOG_ADDR_HDR_CRC, crc8(buf, 4));
  EEPROM.commit();
}

void logLoadHeader() {
  if (EEPROM.read(LOG_ADDR_MAGIC) != LOG_MAGIC) {
    // Fresh — initialise
    logCount = 0; subjId = 1;
    logSaveHeader();
    return;
  }
  // Verify header CRC
  uint8_t buf[4];
  for (int i = 0; i < 4; i++) buf[i] = EEPROM.read(LOG_ADDR_MAGIC + i);
  if (crc8(buf, 4) != EEPROM.read(LOG_ADDR_HDR_CRC)) {
    logCount = 0; subjId = 1;
    logSaveHeader();
    Serial.println("LOG: corrupt header reset");
    return;
  }
  logCount = (uint16_t)EEPROM.read(LOG_ADDR_CNT_LO)
           | ((uint16_t)EEPROM.read(LOG_ADDR_CNT_HI) << 8);
  subjId   = EEPROM.read(LOG_ADDR_SUBJ);
}

// Save one record to EEPROM
bool logSaveRecord(float ir, float ba, float ac, float bpm, float glucose) {
  if (logCount >= LOG_MAX_RECORDS) return false;
  int addr = LOG_DATA_START + logCount * LOG_RECORD_SIZE;
  logWriteFloat(addr,      ir);
  logWriteFloat(addr +  4, ba);
  logWriteFloat(addr +  8, ac);
  logWriteFloat(addr + 12, bpm);
  logWriteFloat(addr + 16, glucose);
  EEPROM.write(addr + 20, subjId);
  logCount++;
  logSaveHeader();
  return true;
}

// Stream all records to Serial as CSV
void logExportCSV() {
  Serial.println("#PPG-GLUCOMETER-DATA-v1");
  Serial.println("#subject_id,ir_peak,ba_ratio,ac_dc,bpm,glucose");
  for (uint16_t i = 0; i < logCount; i++) {
    int addr = LOG_DATA_START + i * LOG_RECORD_SIZE;
    float ir  = logReadFloat(addr);
    float ba  = logReadFloat(addr + 4);
    float ac  = logReadFloat(addr + 8);
    float bpm = logReadFloat(addr + 12);
    float glu = logReadFloat(addr + 16);
    uint8_t sid = EEPROM.read(addr + 20);
    Serial.print("DATA,");
    Serial.print(sid < 10 ? "0" : ""); Serial.print(sid); Serial.print(",");
    Serial.print(ir,  1); Serial.print(",");
    Serial.print(ba,  4); Serial.print(",");
    Serial.print(ac,  5); Serial.print(",");
    Serial.print(bpm, 1); Serial.print(",");
    Serial.println(glu, 1);
  }
  Serial.print("#END "); Serial.print(logCount); Serial.println(" RECORDS");
}

void logClearAll() {
  logCount = 0;
  logSaveHeader();
}

// ── Pending scan features (set in finalizeScan, used by log) ───
float logPendingIR  = 0;
float logPendingBA  = 0;
float logPendingAC  = 0;
float logPendingBPM = 0;

// ================================================================
//  DIGIT ENTRY — shared by LOG and SUBJECT ID entry
// ================================================================
// logDigits[0]=hundreds  [1]=tens  [2]=units
// Used for both glucose entry (3 digits, 040-399)
// and subject ID entry (2 digits stored in [1],[2], range 01-99)
int  logDigits[3]   = {0, 0, 0};
int  logDigitPos    = 0;          // which digit is active
unsigned long holdStartMs = 0;   // for fast-scroll detection
bool holdScrolling  = false;
unsigned long lastScrollMs = 0;
#define HOLD_START_MS   600      // hold this long to start fast scroll
#define SCROLL_RATE_MS  150      // interval between auto-increments

int dataLogMenuIdx = 0;   // cursor in data log submenu

// Advance current digit by 1, wrap 0-9. Called on short press or fast scroll.
// maxVal lets hundreds digit of glucose be capped at 3 (max 399).
void digitIncrement(int maxVal = 9) {
  logDigits[logDigitPos] = (logDigits[logDigitPos] + 1) % (maxVal + 1);
}

// Decrement current digit (double press)
void digitDecrement(int maxVal = 9) {
  logDigits[logDigitPos] = (logDigits[logDigitPos] + maxVal) % (maxVal + 1);
}

// Handle hold-to-fast-scroll. Call every loop iteration during digit states.
// Returns true if a scroll tick happened (so caller can redraw).
// Sets holdScrolling=true while scrolling so BTN_LONG is suppressed on release.
bool handleHoldScroll(bool btnDown, int maxVal = 9) {
  if (btnDown) {
    if (holdStartMs == 0) { holdStartMs = millis(); holdScrolling = false; }
    unsigned long held = millis() - holdStartMs;
    if (held >= HOLD_START_MS) {
      unsigned long now = millis();
      if (now - lastScrollMs >= SCROLL_RATE_MS) {
        lastScrollMs  = now;
        holdScrolling = true;
        digitIncrement(maxVal);
        return true;
      }
    }
  } else {
    // Button released — reset tracking but keep holdScrolling flag
    // so the caller can suppress the BTN_LONG event that fires on release.
    // Clear it only after one full loop with button up.
    holdStartMs = 0;
    if (holdScrolling) {
      holdScrolling = false;   // clear after release so next long press works
    }
  }
  return false;
}
// ================================================================
const char* classifyGlucose(float g) {
  if (g <  70) return "LOW";
  if (g < 100) return "NORMAL";
  if (g < 126) return "ELEVATED";
  return "HIGH";
}

// ================================================================
//  GLUCOSE TREND
//  5-reading buffer, median-smoothed, linear regression slope.
//  Requires >= 3 readings. Threshold ±2.0 mg/dL/reading matches
//  real scan variance of ~2 mg/dL, preventing random flipping.
// ================================================================
#define TREND_BUF 5
static float trendBuf[TREND_BUF] = {0, 0, 0, 0, 0};
static int   trendCount = 0;

void pushTrend(float g) {
  for (int i = 0; i < TREND_BUF - 1; i++) trendBuf[i] = trendBuf[i+1];
  trendBuf[TREND_BUF-1] = g;
  if (trendCount < TREND_BUF) trendCount++;
}

static float median3(float a, float b, float c) {
  if (a > b) { float t = a; a = b; b = t; }
  if (b > c) { float t = b; b = c; c = t; }
  if (a > b) { float t = a; a = b; b = t; }
  return b;
}

char getTrend() {
  if (trendCount < 3) return ' ';

  int n     = min(trendCount, TREND_BUF);
  int start = TREND_BUF - n;

  // Median-smooth: each point replaced by median of itself + neighbours
  float smoothed[TREND_BUF];
  for (int i = start; i < TREND_BUF; i++) {
    int lo = (i > start)        ? i - 1 : i;
    int hi = (i < TREND_BUF-1) ? i + 1 : i;
    smoothed[i] = median3(trendBuf[lo], trendBuf[i], trendBuf[hi]);
  }

  // Linear regression slope over smoothed readings
  float sumX=0, sumY=0, sumXY=0, sumX2=0;
  for (int i = 0; i < n; i++) {
    float x = (float)i;
    float y = smoothed[start + i];
    sumX  += x;   sumY  += y;
    sumXY += x*y; sumX2 += x*x;
  }
  float denom = (float)n * sumX2 - sumX * sumX;
  if (fabsf(denom) < 0.001f) return '-';
  float slope = ((float)n * sumXY - sumX * sumY) / denom;

  const float THRESH = 2.0f;
  return (slope >  THRESH) ? '^'
       : (slope < -THRESH) ? 'v'
       : '-';
}

// ================================================================
//  DISPLAY HELPERS
// ================================================================
void dispClear() { display.clearDisplay(); }

void dispTitle(const char* t, int y = 0, int sz = 1) {
  display.setTextSize(sz);
  display.setCursor(0, y);
  display.println(t);
}

void dispShow() { display.display(); }

// ── Splash screen ──────────────────────────────────────────────
void drawSplash(unsigned long age) {
  dispClear();
  display.setTextSize(2);
  display.setCursor(4, 8);
  display.println("PPG");
  display.setCursor(4, 28);
  display.println("Glucometer");

  // Progress bar — fills over 2500ms
  int barW = (int)((float)age / 2500.0f * 110.0f);
  barW = min(barW, 110);
  display.drawRect(9, 52, 110, 8, SSD1306_WHITE);
  display.fillRect(9, 52, barW, 8, SSD1306_WHITE);
  dispShow();
}

// ── Idle screen ────────────────────────────────────────────────
void drawIdle() {
  dispClear();
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("PPG Glucometer");
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);

  if (lastGlucose > 0) {
    display.setTextSize(2);
    display.setCursor(0, 16);
    display.print((int)lastGlucose);
    display.setTextSize(1);
    display.setCursor(50, 22);
    display.println("mg/dL");
    display.setCursor(0, 38);
    display.print(classifyGlucose(lastGlucose));
    if (calState == 0) { display.setCursor(80, 38); display.print("UNCAL"); }
  } else {
    display.setTextSize(1);
    display.setCursor(0, 18);
    display.println("No reading yet.");
    if (calState == 0) { display.setCursor(0, 30); display.println("-UNCALIBRATED-"); }
  }

  display.setCursor(0, 54);
  display.print("[S] scan     [L] menu");
  dispShow();
}

// ── Finger check screen ────────────────────────────────────────
void drawFingerCheck(unsigned long age) {
  dispClear();
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("FINGER CHECK");
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);
  display.setCursor(0, 18);
  display.println("Place finger on");
  display.println("sensor firmly.");

  // Animated dots
  int dots = (age / 500) % 4;
  display.setCursor(0, 42);
  display.print("Waiting");
  for (int i = 0; i < dots; i++) display.print(".");

  // Timeout countdown
  int remaining = (int)((FINGER_TIMEOUT_MS - age) / 1000) + 1;
  display.setCursor(96, 54);
  display.print(remaining); display.print("s");
  dispShow();
}

// ── Scanning status bar (called from processScan)  ─────────────
void updateOLEDStatus(unsigned long elapsed) {
  display.fillRect(0, 45, 128, 19, SSD1306_BLACK);
  display.setCursor(0, 52);
  display.setTextSize(1);
  if (elapsed < STABILIZE_MS) {
    display.print("Stablizing...");
  } else {
    display.print("LIVE:");
    display.print((COLLECTION_MS - elapsed) / 1000);
    display.print("s  B:");
    display.print(beatCount);
    if (calState == 0) { display.print(" !UC"); }
  }
  dispShow();
}

// ── Result screen ──────────────────────────────────────────────
void drawResult(float glucose, float bpm) {
  dispClear();
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("-- RESULT --");

  display.setTextSize(2);
  display.setCursor(0, 12);
  display.print((int)glucose);

  display.setTextSize(1);
  display.setCursor(52, 14);
  display.println("mg/dL");
  if (calState == 0) { display.setCursor(52, 24); display.println("UNCAL"); }

  display.setCursor(0, 34);
  display.print(classifyGlucose(glucose));
  char tr = getTrend();
  if (tr != ' ') { display.print("  "); display.print(tr); }

  display.setCursor(0, 48);
  display.print("HR:"); display.print((int)bpm);
  display.print("bpm ");
  if (lastSpO2 > 0) {
    display.print("O2:"); display.print((int)lastSpO2); display.print("%");
  }


  dispShow();
}

// ── Cal prompt ─────────────────────────────────────────────────
void drawCalPrompt() {
  dispClear();
  dispTitle("CALIBRATE?", 0);
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);
  display.setCursor(0, 16);
  display.println("Have a fingerstick");
  display.println("reading handy?");
  display.setCursor(0, 42);
  display.println("[Short] YES");
  display.setCursor(0, 54);
  display.println("[Long]  NO / Skip");
  dispShow();
}

// ── Cal confirm ────────────────────────────────────────────────
void drawCalConfirm() {
  int glucose = logDigits[0]*100 + logDigits[1]*10 + logDigits[2];
  glucose = constrain(glucose, 40, 400);
  dispClear();
  dispTitle("SAVE CAL?", 0);
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);
  display.setTextSize(2);
  display.setCursor(20, 18);
  display.print(glucose);
  display.setTextSize(1);
  display.setCursor(68, 24);
  display.println("mg/dL");
  display.setCursor(0, 44);
  display.println("[S] Save");
  display.setCursor(0, 54);
  display.println("[D] Re-enter");
  dispShow();
}

// ── Cal saved ──────────────────────────────────────────────────
void drawCalSaved() {
  dispClear();
  dispTitle("SAVED!", 8, 2);
  display.setTextSize(1);
  display.setCursor(0, 36);
  display.print("Offset: "); display.println(calOffset, 1);
  display.print("Readings: "); display.println(calN);
  dispShow();
}

// ── Main menu ──────────────────────────────────────────────────
const char* MENU_ITEMS[] = {
  "CALIBRATE",
  "VIEW CAL",
  "RESET CAL",
  "DATA-LOG",
  "SET SUBJECT",
  "EXIT"
};
const int N_MENU_ITEMS = 6;
int       menuIdx      = 0;

void drawMenu() {
  dispClear();
  // Title + hint on same line
  display.setTextSize(1);
  display.setCursor(0, 0); display.print("MENU");
  display.setCursor(50, 0); display.print("[S]+ [L]ok");
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);

  // Show 4 items, scroll window follows cursor
  const int VISIBLE = 4;
  int first = 0;
  if (menuIdx >= VISIBLE) first = menuIdx - VISIBLE + 1;

  for (int i = 0; i < VISIBLE; i++) {
    int item = first + i;
    if (item >= N_MENU_ITEMS) break;
    int y = 13 + i * 12;
    if (item == menuIdx) {
      display.fillRect(0, y-1, 120, 11, SSD1306_WHITE);
      display.setTextColor(SSD1306_BLACK);
    } else {
      display.setTextColor(SSD1306_WHITE);
    }
    display.setCursor(4, y);
    display.print(MENU_ITEMS[item]);
  }
  display.setTextColor(SSD1306_WHITE);

  // Scroll indicator bar on right edge
  int barH   = (int)(50.0f * VISIBLE / N_MENU_ITEMS);
  int barY   = 11 + (int)(50.0f * first / N_MENU_ITEMS);
  display.drawRect(123, 11, 4, 50, SSD1306_WHITE);
  display.fillRect(123, barY, 4, barH, SSD1306_WHITE);

  dispShow();
}

// ── View cal status ────────────────────────────────────────────
void drawViewCal() {
  dispClear();
  dispTitle("CAL STATUS", 0);
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);
  display.setCursor(0, 14);
  if (calState == 0) {
    display.println("UNCALIBRATED");
    display.println("No data saved.");
    display.println("");
    display.println("Scan then calibrate");
    display.println("from this menu.");
  } else {
    display.println("CALIBRATED");
    display.print("Offset: ");
    display.println(calOffset, 1);
    display.print("Readings: ");
    display.println(calN);
    display.println("");
    if (calN < 3) display.println("More readings = better");
    else          display.println("Calibration solid.");
  }
  dispShow();
}

// ── Data log submenu ───────────────────────────────────────────
void drawDataLogMenu(int sel) {
  dispClear();
  display.setTextSize(1);
  display.setCursor(0, 0); display.print("DATA-LOG");
  display.setCursor(60, 0); display.print("[S]+ [L]ok");
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);

  const char* items[] = { "LOG READING", "EXPORT DATA", "VIEW COUNT", "CLEAR DATA", "BACK" };
  const int   N_ITEMS = 5;
  const int   VISIBLE = 4;
  int first = 0;
  if (sel >= VISIBLE) first = sel - VISIBLE + 1;

  for (int i = 0; i < VISIBLE; i++) {
    int item = first + i;
    if (item >= N_ITEMS) break;
    int y = 13 + i * 12;
    if (item == sel) {
      display.fillRect(0, y-1, 120, 11, SSD1306_WHITE);
      display.setTextColor(SSD1306_BLACK);
    } else {
      display.setTextColor(SSD1306_WHITE);
    }
    display.setCursor(4, y); display.print(items[item]);
  }
  display.setTextColor(SSD1306_WHITE);

  // Scroll indicator
  int barH = (int)(50.0f * VISIBLE / N_ITEMS);
  int barY = 11 + (int)(50.0f * first / N_ITEMS);
  display.drawRect(123, 11, 4, 50, SSD1306_WHITE);
  display.fillRect(123, barY, 4, barH, SSD1306_WHITE);

  dispShow();
}

// ── Digit entry screen ─────────────────────────────────────────
// mode 0 = glucose (3 digits, label "GLUCOSE mg/dL")
// mode 1 = subject ID (2 digits, label "SUBJECT ID")
void drawDigitEntry(int mode) {
  dispClear();
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println(mode == 0 ? "ENTER GLUCOSE:" : "ENTER SUBJECT ID:");
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);

  // Build display number
  int startDigit = (mode == 1) ? 1 : 0;   // subject uses digits[1] and [2] only
  int nDigits    = (mode == 1) ? 2 : 3;

  display.setTextSize(3);
  int totalW = nDigits * 18 + (nDigits-1) * 4;
  int startX = (128 - totalW) / 2;

  for (int i = 0; i < nDigits; i++) {
    int d   = logDigits[startDigit + i];
    int x   = startX + i * 22;
    int pos = startDigit + i;
    if (pos == logDigitPos) {
      // Active digit — highlight
      display.fillRect(x-2, 14, 20, 26, SSD1306_WHITE);
      display.setTextColor(SSD1306_BLACK);
    } else {
      display.setTextColor(SSD1306_WHITE);
    }
    display.setCursor(x, 16);
    display.print(d);
  }
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(1);

  if (mode == 0) {
    display.setCursor(42, 44);
    display.print("mg/dL");
  } else {
    display.setCursor(48, 44);
    display.print("ID");
  }

  display.setCursor(0, 54);
  display.print("[S]+1 [H]fast [D]next");
  dispShow();
}

// ── Log confirm ────────────────────────────────────────────────
void drawLogConfirm(int glucose) {
  dispClear();
  dispTitle("LOG THIS?", 0);
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);
  display.setTextSize(2);
  display.setCursor(20, 18);
  display.print(glucose);
  display.setTextSize(1);
  display.setCursor(68, 24); display.println("mg/dL");
  display.setCursor(0, 42);
  display.print("Subj: ");
  display.print(subjId < 10 ? "0" : ""); display.println(subjId);
  display.setCursor(0, 52); display.println("[S]Save [D]Redo");
  dispShow();
}

// ── Log saved ──────────────────────────────────────────────────
void drawLogSaved() {
  dispClear();
  dispTitle("LOGGED!", 8, 2);
  display.setTextSize(1);
  display.setCursor(0, 36);
  display.print("Record "); display.print(logCount);
  display.print(" / "); display.println(LOG_MAX_RECORDS);
  display.setCursor(0, 48);
  display.print("Subj: ");
  display.print(subjId < 10 ? "0" : ""); display.print(subjId);
  dispShow();
}

// ── Subject confirm ────────────────────────────────────────────
void drawSubjConfirm() {
  int id = logDigits[1] * 10 + logDigits[2];
  dispClear();
  dispTitle("SET SUBJECT?", 0);
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);
  display.setTextSize(3);
  display.setCursor(40, 18);
  if (id < 10) display.print("0");
  display.print(id);
  display.setTextSize(1);
  display.setCursor(0, 48); display.println("[S]Save [D]Redo");
  dispShow();
}

// ── Subject saved ──────────────────────────────────────────────
void drawSubjSaved() {
  dispClear();
  dispTitle("SUBJECT SET!", 8, 2);
  display.setTextSize(1);
  display.setCursor(0, 40);
  display.print("Now logging as: ");
  display.print(subjId < 10 ? "0" : ""); display.println(subjId);
  dispShow();
}
void drawAborted() {
  dispClear();
  display.setTextSize(2);
  display.setCursor(0, 10);
  display.println("ABORTED");
  display.setTextSize(1);
  display.setCursor(0, 40);
  display.println("Scan cancelled.");
  dispShow();
}

// ── Rejected screen ────────────────────────────────────────────
void drawRejected() {
  dispClear();
  dispTitle("REJECTED", 0);
  display.drawLine(0, 10, 127, 10, SSD1306_WHITE);
  display.setCursor(0, 16);
  display.println("Signal too weak.");
  display.println("");
  display.println("Tips:");
  display.println("- Press firmly");
  display.println("- Stay still");
  dispShow();
}

// ================================================================
//  SCAN HELPERS  (verbatim from v5)
// ================================================================
void updateScaling(long irValue) {
  if (irValue < minIR) minIR = irValue;
  if (irValue > maxIR) maxIR = irValue;
  if (maxIR - minIR < 500) maxIR = minIR + 500;
}

void drawWave(long irValue) {
  int yPos = map(irValue, minIR, maxIR, 40, 5);
  yPos = constrain(yPos, 5, 40);
  display.drawLine(xPos - 1, lastY, xPos, yPos, SSD1306_WHITE);
  lastY = yPos;
  xPos++;
  if (xPos >= SCREEN_WIDTH) {
    xPos = 0;
    display.fillRect(0, 0, 128, 42, SSD1306_BLACK);
    minIR = irValue + 200; maxIR = irValue - 200;
  }
}

// ================================================================
//  SCAN LOGIC  (processScan unchanged from v5)
// ================================================================
void startNewScan() {
  bpmSum = 0; beatCount = 0; lastBpm = 0; errorCounter = 0;
  xPos = 0; lastY = 30; minIR = 200000; maxIR = 0;
  currentPeakIR = 0; currentValleyIR = 1000000L;
  peakSampleIdx = 0; valleySampleIdx = 0;
  beatSampleCount = 0; beatStartMs = millis();
  beatBufLen = 0;
  sum_ir_peak = sum_ba_ratio = sum_ac_dc = 0;
  currentPeakRed = 0; currentValleyRed = 1000000L; sum_red_ratio = 0;
  sd_reset();
  scanStartMs = millis();
  dispClear();
}

void processScan(long irValue) {
  unsigned long elapsed = millis() - scanStartMs;

  if (irValue > currentPeakIR)        { currentPeakIR = irValue; peakSampleIdx = beatSampleCount; }
  if (irValue < currentValleyIR)      { currentValleyIR = irValue; valleySampleIdx = beatSampleCount; }
  if (currentRedValue > currentPeakRed)   currentPeakRed   = currentRedValue;
  if (currentRedValue < currentValleyRed) currentValleyRed = currentRedValue;

  beatSampleCount++;
  if (beatBufLen < BEAT_BUF_LEN) beatBuf[beatBufLen++] = irValue;

  updateScaling(irValue);

  static int drawSkip = 0;
  if (++drawSkip >= 4) { drawSkip = 0; drawWave(irValue); }

  static unsigned long lastOledMs = 0;
  if (millis() - lastOledMs > 500) { lastOledMs = millis(); updateOLEDStatus(elapsed); }

  if (sd_update(irValue)) {
    unsigned long now  = millis();
    long  delta        = now - lastBeatMs;
    lastBeatMs         = now;
    float currentBpm   = 60000.0f / delta;

    if (elapsed >= STABILIZE_MS && currentBpm > 40 && currentBpm < 190) {
      if (lastBpm > 0 && fabsf(currentBpm - lastBpm) > MAX_BPM_DEV) {
        errorCounter++;
        lastBpm = currentBpm;
      } else {
        lastBpm = currentBpm;
        long  peak  = currentPeakIR;
        float ac    = (float)(currentPeakIR - currentValleyIR);
        float dc    = (float)(currentPeakIR + currentValleyIR) / 2.0f;
        float ac_dc = (dc > 0) ? constrain(ac / dc, 0.002f, 0.015f) : 0.005f;
        float ba    = computeBA(beatBuf, beatBufLen);

        if (peak >= 50000L) {
          beatCount++;
          bpmSum       += currentBpm;
          sum_ir_peak  += (float)peak;
          sum_ba_ratio += ba;
          sum_ac_dc    += ac_dc;
          // SpO2: accumulate Red AC/DC ratio per accepted beat
          float red_ac = (float)(currentPeakRed - currentValleyRed);
          float red_dc = (float)(currentPeakRed + currentValleyRed) / 2.0f;
          if (red_dc > 1000.0f) sum_red_ratio += red_ac / red_dc;
        } else {
          errorCounter++;
        }

        Serial.print("Beat "); Serial.print(beatCount);
        Serial.print("  BPM="); Serial.print(currentBpm, 1);
        Serial.print("  IR=");  Serial.print(peak);
        Serial.print("  BA=");  Serial.print(ba, 4);
        Serial.print("  AC/DC="); Serial.println(ac_dc, 5);
      }
    }

    // Reset per-beat accumulators — Red resets with IR
    currentPeakIR = 0; currentValleyIR = 1000000L;
    currentPeakRed = 0; currentValleyRed = 1000000L;
    peakSampleIdx = 0; valleySampleIdx = 0;
    beatSampleCount = 0; beatStartMs = now;
    beatBufLen = 0;
  }
}

void finalizeScan() {
  if (beatCount < MIN_BEATS) {
    goTo(ST_REJECTED);
    drawRejected();
    return;
  }

  float avg_ir  = sum_ir_peak  / beatCount;
  float avg_ba  = sum_ba_ratio / beatCount;
  float avg_ac  = sum_ac_dc    / beatCount;
  float bpm     = bpmSum       / beatCount;

  float rawGlucose = estimateGlucose(avg_ir, avg_ba, avg_ac);
  rawGlucose = constrain(rawGlucose, 55.0f, 300.0f);

  // SpO2 — R ratio method
  // R = (AC_red/DC_red) / (AC_ir/DC_ir)
  // AC/DC IR = avg_ac (already computed above)
  // SpO2 ≈ 110 - 25*R, clipped to physiological range 80-100%
  // Guard: require avg_ac > 0.002 (valid signal) and beatCount > 0
  float avg_red_ratio = (beatCount > 0) ? sum_red_ratio / beatCount : 0.0f;
  if (avg_ac > 0.002f && avg_red_ratio > 0.0f) {
    float R    = avg_red_ratio / avg_ac;
    lastSpO2   = constrain(110.0f - 25.0f * R, 80.0f, 100.0f);
  } else {
    lastSpO2 = -1.0f;   // not enough signal
  }

  lastRawGlucose = rawGlucose;
  logPendingIR   = avg_ir;
  logPendingBA   = avg_ba;
  logPendingAC   = avg_ac;
  logPendingBPM  = bpm;
  float glucose     = applyCalibration(rawGlucose);
  glucose           = constrain(glucose, 40.0f, 400.0f);

  Serial.println("===== FINAL =====");
  Serial.print("BPM:     "); Serial.println(bpm, 1);
  Serial.print("SpO2:    ");
  if (lastSpO2 > 0) { Serial.print(lastSpO2, 1); Serial.println(" %"); }
  else               { Serial.println("N/A"); }
  Serial.print("IR peak: "); Serial.println(avg_ir, 1);
  Serial.print("BA:      "); Serial.println(avg_ba, 4);
  Serial.print("AC/DC:   "); Serial.println(avg_ac, 5);
  Serial.print("RAW GLU: "); Serial.println(rawGlucose, 1);
  Serial.print("CAL GLU: "); Serial.print(glucose, 1); Serial.println(" mg/dL");
  Serial.println("=================");

  pushTrend(glucose);
  lastGlucose  = glucose;
  lastBpmFinal = bpm;

  drawResult(glucose, bpm);
  goTo(ST_RESULT);

  // Measurement is complete — this is the ONLY place a result is ever
  // sent over BLE, and it always reflects the value just computed above.
  bleSendResult(glucose, bpm, (lastSpO2 > 0) ? lastSpO2 : -1.0f, calState);
}

// ================================================================
//  SETUP
// ================================================================
void setup() {
  Serial.begin(115200);
  pinMode(BTN_PIN, INPUT_PULLUP);

  Wire.begin(8, 9);
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  EEPROM.begin(EEPROM_SIZE);
  calLoadEEPROM();
  logLoadHeader();

  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    display.setTextSize(1); display.setCursor(0, 0);
    display.println("SENSOR ERROR"); display.display();
    while (1);
  }
  particleSensor.setup(30, 1, 2, SAMPLE_RATE, 411, 4096);
  particleSensor.shutDown();   // sensor off at boot
  sensorRunning = false;
  lastActivityMs = millis();

  setupBLE();

  goTo(ST_SPLASH);
}

// ================================================================
//  MAIN LOOP — state machine
// ================================================================
void loop() {
  // ── Drain sensor FIFO (only when sensor is active) ───────────
  long irValue  = 0;
  bool newSample = false;
  if (sensorRunning) {
    particleSensor.check();
    if (particleSensor.available()) {
      irValue          = particleSensor.getFIFOIR();
      currentRedValue  = particleSensor.getFIFORed();  // before nextSample()
      particleSensor.nextSample();
      newSample = true;
    }
  }

  BtnEvent btn = readButton();

  // ── BLE-triggered measurement ────────────────────────────────
  // Mirrors the ST_IDLE / BTN_SHORT branch below exactly. Only ever
  // starts a scan — never fabricates or forwards a result on its own.
  if (bleStartRequested) {
    bleStartRequested = false;
    if (state == ST_IDLE) {
      fingerConfirmCount = 0;
      sensorWake();
      goTo(ST_FINGER_CHECK);
      drawFingerCheck(0);
      Serial.println("BLE: measurement started");
    } else {
      Serial.println("BLE: measurement command ignored - device not idle");
    }
  }

  // ── OLED auto-off ────────────────────────────────────────────
  // States where screen must stay on (active wait / scan in progress)
  bool activeState = (state == ST_SCANNING   ||
                      state == ST_LOG_SCAN    ||
                      state == ST_FINGER_CHECK||
                      state == ST_SPLASH);

  if (btn != BTN_NONE) {
    lastActivityMs = millis();
    if (!oledOn) {
      display.ssd1306_command(SSD1306_DISPLAYON);
      oledOn = true;
      // Redraw current screen so user sees context immediately
      switch (state) {
        case ST_IDLE:         drawIdle();                              break;
        case ST_RESULT:       drawResult(lastGlucose, lastBpmFinal);  break;
        case ST_MENU:         drawMenu();                              break;
        case ST_LOG_PROMPT:   drawDataLogMenu(dataLogMenuIdx);         break;
        case ST_CAL_PROMPT:   drawCalPrompt();                         break;
        case ST_CAL_RANGE:
        case ST_LOG_D1:
        case ST_LOG_D2:
        case ST_LOG_D3:
        case ST_SUBJ_D1:
        case ST_SUBJ_D2:      drawDigitEntry(
                                (state==ST_SUBJ_D1||state==ST_SUBJ_D2) ? 1 : 0
                              );                                       break;
        case ST_CAL_CONFIRM:  drawCalConfirm();                        break;
        case ST_LOG_CONFIRM:  drawLogConfirm(
                                logDigits[0]*100+logDigits[1]*10+logDigits[2]
                              );                                       break;
        case ST_SUBJ_CONFIRM: drawSubjConfirm();                       break;
        default:              display.clearDisplay(); display.display(); break;
      }
      btn = BTN_NONE;   // consume press — no action fires on wake
    }
  }

  if (!activeState && oledOn &&
      (millis() - lastActivityMs) >= OLED_TIMEOUT_MS) {
    display.ssd1306_command(SSD1306_DISPLAYOFF);
    oledOn = false;
  }

  switch (state) {

    // ── SPLASH ───────────────────────────────────────────────────
    case ST_SPLASH: {
      unsigned long age = stateAge();
      drawSplash(age);
      if (age >= 2500) goTo(ST_IDLE);
      break;
    }

    // ── IDLE ─────────────────────────────────────────────────────
    case ST_IDLE: {
      static unsigned long lastIdleDraw = 0;
      if (millis() - lastIdleDraw > 500) {
        lastIdleDraw = millis();
        drawIdle();
      }
      if (btn == BTN_SHORT) {
        fingerConfirmCount = 0;
        sensorWake();
        goTo(ST_FINGER_CHECK);
        drawFingerCheck(0);
      }
      if (btn == BTN_LONG) {
        menuIdx = 0;
        goTo(ST_MENU);
        drawMenu();
      }
      break;
    }

    // ── FINGER CHECK ─────────────────────────────────────────────
    case ST_FINGER_CHECK: {
      unsigned long age = stateAge();

      if (btn == BTN_SHORT) { goTo(ST_IDLE); break; }   // cancel

      if (age >= FINGER_TIMEOUT_MS) {
        dispClear();
        dispTitle("NO FINGER", 8, 2);
        display.setTextSize(1); display.setCursor(0, 36);
        display.println("Try again.");
        dispShow();
        delay(1500);
        goTo(ST_IDLE);
        break;
      }

      // Draw animated waiting screen every 300ms
      static unsigned long lastFingerDraw = 0;
      if (millis() - lastFingerDraw > 300) {
        lastFingerDraw = millis();
        drawFingerCheck(age);
      }

      // Require N consecutive above-threshold samples
      if (newSample) {
        if (irValue > FINGER_IR_THRESH) {
          fingerConfirmCount++;
          if (fingerConfirmCount >= FINGER_CONFIRM_N) {
            startNewScan();
            goTo(ST_SCANNING);
          }
        } else {
          fingerConfirmCount = 0;   // reset on any below-threshold sample
        }
      }
      break;
    }

    // ── SCANNING ─────────────────────────────────────────────────
    case ST_SCANNING: {
      // Abort on long press
      if (btn == BTN_LONG) {
        goTo(ST_ABORTED);
        drawAborted();
        break;
      }

      if (newSample) {
        unsigned long elapsed = millis() - scanStartMs;
        if (elapsed < COLLECTION_MS) {
          processScan(irValue);
        } else {
          finalizeScan();   // sets state to ST_RESULT or ST_REJECTED internally
        }
      }
      break;
    }

    // ── ABORTED ──────────────────────────────────────────────────
    case ST_ABORTED: {
      if (stateAge() >= 2000) goTo(ST_IDLE);
      break;
    }

    // ── REJECTED ─────────────────────────────────────────────────
    case ST_REJECTED: {
      if (stateAge() >= 4000 || btn == BTN_SHORT) goTo(ST_IDLE);
      break;
    }

    // ── RESULT ───────────────────────────────────────────────────
    case ST_RESULT: {
      if (stateAge() >= 8000 || btn == BTN_SHORT) {
        if (calState == 0) {
          goTo(ST_CAL_PROMPT);
          drawCalPrompt();
        } else {
          goTo(ST_IDLE);
        }
      }
      break;
    }

    // ── MENU ─────────────────────────────────────────────────────
    case ST_MENU: {
      if (btn == BTN_SHORT) {
        menuIdx = (menuIdx + 1) % N_MENU_ITEMS;
        drawMenu();
      }
      if (btn == BTN_DOUBLE) { goTo(ST_IDLE); }
      if (btn == BTN_LONG) {
        if (menuIdx == 0) {                    // CALIBRATE
          goTo(ST_CAL_PROMPT); drawCalPrompt();
        } else if (menuIdx == 1) {             // VIEW CAL
          drawViewCal(); delay(4000); drawMenu();
        } else if (menuIdx == 2) {             // RESET CAL
          // Double-confirm — same pattern as CLEAR DATA
          dispClear(); display.setTextSize(1); display.setCursor(0,0);
          display.println("RESET CALIBRATION?");
          display.drawLine(0,10,127,10,SSD1306_WHITE);
          display.setCursor(0,16);
          display.println("All cal readings");
          display.println("will be lost.");
          display.println("");
          display.println("[Long] CONFIRM RESET");
          display.println("[Any]  Cancel");
          dispShow();
          unsigned long t = millis();
          bool confirmed = false;
          while (millis() - t < 5000) {
            BtnEvent e = readButton();
            if (e == BTN_LONG) { confirmed = true; break; }
            if (e == BTN_SHORT || e == BTN_DOUBLE) break;
          }
          if (confirmed) {
            calState = 0; calOffset = 0.0f; calN = 0;
            calSaveEEPROM();
            dispClear(); display.setTextSize(2); display.setCursor(0,10);
            display.println("RESET"); display.setTextSize(1);
            display.setCursor(0,40); display.println("Calibration cleared.");
            dispShow(); delay(2000); goTo(ST_IDLE);
          } else {
            drawMenu();   // cancelled — back to menu
          }
        } else if (menuIdx == 3) {             // DATA LOG
          dataLogMenuIdx = 0;
          isCollecting   = false;
          goTo(ST_LOG_PROMPT); drawDataLogMenu(dataLogMenuIdx);
        } else if (menuIdx == 4) {             // SET SUBJECT
          logDigits[1] = subjId / 10;
          logDigits[2] = subjId % 10;
          logDigitPos  = 1;
          holdStartMs  = 0; holdScrolling = false;
          goTo(ST_SUBJ_D1); drawDigitEntry(1);
        } else {                               // EXIT
          goTo(ST_IDLE);
        }
      }
      break;
    }

    // ── LOG SUBMENU ──────────────────────────────────────────────
    case ST_LOG_PROMPT: {
      if (btn == BTN_SHORT) {
        dataLogMenuIdx = (dataLogMenuIdx + 1) % 5;
        drawDataLogMenu(dataLogMenuIdx);
      }
      if (btn == BTN_DOUBLE) { goTo(ST_MENU); drawMenu(); }
      if (btn == BTN_LONG) {
        if (dataLogMenuIdx == 0) {           // LOG READING → dedicated scan
          fingerConfirmCount = 0;
          sensorWake();
          goTo(ST_LOG_SCAN);
          // Show finger check screen reusing existing draw function
          drawFingerCheck(0);
        } else if (dataLogMenuIdx == 1) {    // EXPORT DATA
          dispClear(); dispTitle("EXPORTING...", 8, 2); dispShow();
          delay(500);
          logExportCSV();
          dispClear(); dispTitle("EXPORTED!", 8, 2);
          display.setTextSize(1); display.setCursor(0,36);
          display.print(logCount); display.println(" records sent.");
          display.println("Check Serial monitor.");
          dispShow(); delay(3000);
          goTo(ST_LOG_PROMPT); drawDataLogMenu(dataLogMenuIdx);
        } else if (dataLogMenuIdx == 2) {    // VIEW COUNT
          dispClear(); dispTitle("DATA-LOG", 0);
          display.drawLine(0,10,127,10,SSD1306_WHITE);
          display.setCursor(0,16);
          display.print("Records: "); display.println(logCount);
          display.print("Max:     "); display.println(LOG_MAX_RECORDS);
          display.print("Subject: ");
          display.print(subjId<10?"0":""); display.println(subjId);
          display.println("");
          display.print("Free: ");
          display.print(LOG_MAX_RECORDS - logCount);
          display.println(" slots");
          dispShow(); delay(4000);
          drawDataLogMenu(dataLogMenuIdx);
        } else if (dataLogMenuIdx == 3) {    // CLEAR DATA — requires second long press
          dispClear(); display.setTextSize(1); display.setCursor(0,0);
          display.println("CLEAR ALL DATA?");
          display.drawLine(0,10,127,10,SSD1306_WHITE);
          display.setCursor(0,16);
          display.println("This cannot be undone.");
          display.println("");
          display.println("[Long] CONFIRM DELETE");
          display.println("[Any]  Cancel");
          dispShow();
          unsigned long t = millis();
          bool confirmed = false;
          while (millis() - t < 5000) {
            BtnEvent e = readButton();
            if (e == BTN_LONG) { confirmed = true; break; }
            if (e == BTN_SHORT || e == BTN_DOUBLE) break;
          }
          if (confirmed) {
            logClearAll();
            dispClear(); display.setTextSize(2); display.setCursor(0,10);
            display.println("CLEARED"); dispShow(); delay(2000);
          }
          goTo(ST_LOG_PROMPT); drawDataLogMenu(dataLogMenuIdx);
        } else {                             // BACK
          goTo(ST_MENU); drawMenu();
        }
      }
      break;
    }

    // ── LOG SCAN — dedicated scan for data logging ────────────────
    // Same logic as normal scanning but:
    //   - Finger check with 10s timeout
    //   - On completion → goes to digit entry (not ST_RESULT)
    //   - Long press aborts back to log submenu
    case ST_LOG_SCAN: {
      unsigned long age = stateAge();

      // Abort → back to log submenu
      if (btn == BTN_LONG && !isCollecting) {
        goTo(ST_LOG_PROMPT); drawDataLogMenu(dataLogMenuIdx); break;
      }

      if (!isCollecting) {
        // Finger check phase
        if (age >= FINGER_TIMEOUT_MS) {
          dispClear(); dispTitle("NO FINGER", 8, 2);
          display.setTextSize(1); display.setCursor(0,36);
          display.println("Try again.");
          dispShow(); delay(1500);
          goTo(ST_LOG_PROMPT); drawDataLogMenu(dataLogMenuIdx);
          break;
        }
        static unsigned long lastLogFingerDraw = 0;
        if (millis() - lastLogFingerDraw > 300) {
          lastLogFingerDraw = millis();
          drawFingerCheck(age);
        }
        if (newSample) {
          if (irValue > FINGER_IR_THRESH) {
            fingerConfirmCount++;
            if (fingerConfirmCount >= FINGER_CONFIRM_N) {
              startNewScan();
              isCollecting = true;
            }
          } else {
            fingerConfirmCount = 0;
          }
        }
      } else {
        // Scanning phase — abort on long press
        if (btn == BTN_LONG) {
          isCollecting = false;
          goTo(ST_LOG_PROMPT); drawDataLogMenu(dataLogMenuIdx); break;
        }
        if (newSample) {
          unsigned long elapsed = millis() - scanStartMs;
          if (elapsed < COLLECTION_MS) {
            processScan(irValue);
          } else {
            // Scan complete — finalize features but don't show result screen
            isCollecting = false;
            if (beatCount < MIN_BEATS) {
              drawRejected(); delay(3000);
              goTo(ST_LOG_PROMPT); drawDataLogMenu(dataLogMenuIdx);
            } else {
              // Store features for logging
              logPendingIR  = sum_ir_peak  / beatCount;
              logPendingBA  = sum_ba_ratio / beatCount;
              logPendingAC  = sum_ac_dc    / beatCount;
              logPendingBPM = bpmSum       / beatCount;
              // Show quick summary
              dispClear();
              display.setTextSize(1); display.setCursor(0,0);
              display.println("SCAN DONE");
              display.drawLine(0,10,127,10,SSD1306_WHITE);
              display.setCursor(0,14);
              display.print("IR:  "); display.println((long)logPendingIR);
              display.print("BA:  "); display.println(logPendingBA, 3);
              display.print("AC:  "); display.println(logPendingAC, 4);
              display.print("BPM: "); display.println((int)logPendingBPM);
              display.setCursor(0,54);
              display.print("Enter glucose now...");
              dispShow(); delay(2000);
              // Go straight to digit entry
              logDigits[0] = 0; logDigits[1] = 8; logDigits[2] = 0;
              logDigitPos  = 0; holdStartMs = 0; holdScrolling = false;
              goTo(ST_LOG_D1); drawDigitEntry(0);
            }
          }
        }
      }
      break;
    }

    // ── LOG DIGIT ENTRY ──────────────────────────────────────────
    case ST_LOG_D1:
    case ST_LOG_D2:
    case ST_LOG_D3: {
      bool btnDown = (digitalRead(BTN_PIN) == LOW);
      int  maxV    = (logDigitPos == 0) ? 3 : 9;
      if (handleHoldScroll(btnDown, maxV)) {
        drawDigitEntry(0); break;
      }
      if (btn == BTN_SHORT) {
        digitIncrement(maxV); drawDigitEntry(0);
      }
      if (btn == BTN_DOUBLE && !holdScrolling) {
        logDigitPos++;
        if (logDigitPos > 2) {
          int glucose = logDigits[0]*100 + logDigits[1]*10 + logDigits[2];
          glucose = constrain(glucose, 40, 400);
          goTo(ST_LOG_CONFIRM); drawLogConfirm(glucose);
        } else {
          DeviceState ns = (logDigitPos == 1) ? ST_LOG_D2 : ST_LOG_D3;
          goTo(ns); drawDigitEntry(0);
        }
      }
      // Long press = abort → back to log submenu
      if (btn == BTN_LONG && !holdScrolling) {
        goTo(ST_LOG_PROMPT); drawDataLogMenu(dataLogMenuIdx);
      }
      break;
    }

    // ── LOG CONFIRM ──────────────────────────────────────────────
    case ST_LOG_CONFIRM: {
      int glucose = logDigits[0]*100 + logDigits[1]*10 + logDigits[2];
      glucose = constrain(glucose, 40, 400);
      if (btn == BTN_SHORT) {
        bool ok = logSaveRecord(logPendingIR, logPendingBA, logPendingAC,
                                logPendingBPM, (float)glucose);
        if (ok) {
          Serial.print("DATA,");
          Serial.print(subjId < 10 ? "0" : ""); Serial.print(subjId); Serial.print(",");
          Serial.print(logPendingIR,  1); Serial.print(",");
          Serial.print(logPendingBA,  4); Serial.print(",");
          Serial.print(logPendingAC,  5); Serial.print(",");
          Serial.print(logPendingBPM, 1); Serial.print(",");
          Serial.println((float)glucose, 1);
          goTo(ST_LOG_SAVED); drawLogSaved();
        } else {
          dispClear(); display.setTextSize(1); display.setCursor(0,0);
          display.println("STORAGE FULL!");
          display.setCursor(0,20); display.println("Export and clear");
          display.println("data first.");
          dispShow(); delay(3000);
          goTo(ST_LOG_PROMPT); drawDataLogMenu(dataLogMenuIdx);
        }
      }
      if (btn == BTN_DOUBLE) {
        // Re-enter value
        logDigitPos = 0; holdStartMs = 0; holdScrolling = false;
        goTo(ST_LOG_D1); drawDigitEntry(0);
      }
      // Long press = abort entirely → back to log submenu
      if (btn == BTN_LONG) {
        goTo(ST_LOG_PROMPT); drawDataLogMenu(dataLogMenuIdx);
      }
      break;
    }

    // ── LOG SAVED — loops back to submenu for another reading ─────
    case ST_LOG_SAVED: {
      if (stateAge() >= 2000) {
        goTo(ST_LOG_PROMPT); drawDataLogMenu(dataLogMenuIdx);
      }
      break;
    }

    // ── SUBJECT ID ENTRY ─────────────────────────────────────────
    case ST_SUBJ_D1:
    case ST_SUBJ_D2: {
      bool btnDown = (digitalRead(BTN_PIN) == LOW);
      if (handleHoldScroll(btnDown, 9)) {
        drawDigitEntry(1); break;
      }
      if (btn == BTN_SHORT) {
        digitIncrement(9); drawDigitEntry(1);
      }
      if (btn == BTN_DOUBLE && !holdScrolling) {
        logDigitPos++;
        if (logDigitPos > 2) {
          goTo(ST_SUBJ_CONFIRM); drawSubjConfirm();
        } else {
          goTo(ST_SUBJ_D2); drawDigitEntry(1);
        }
      }
      // Long press = abort → back to menu
      if (btn == BTN_LONG && !holdScrolling) {
        goTo(ST_MENU); drawMenu();
      }
      break;
    }

    // ── SUBJECT CONFIRM ──────────────────────────────────────────
    case ST_SUBJ_CONFIRM: {
      if (btn == BTN_SHORT) {
        int id = logDigits[1]*10 + logDigits[2];
        subjId = (uint8_t)constrain(id, 1, 99);
        logSaveHeader();
        goTo(ST_SUBJ_SAVED); drawSubjSaved();
      }
      if (btn == BTN_DOUBLE) {
        logDigitPos = 1; holdStartMs = 0; holdScrolling = false;
        goTo(ST_SUBJ_D1); drawDigitEntry(1);
      }
      break;
    }

    // ── SUBJECT SAVED ────────────────────────────────────────────
    case ST_SUBJ_SAVED: {
      if (stateAge() >= 2000) goTo(ST_IDLE);
      break;
    }

    // ── CAL PROMPT ───────────────────────────────────────────────
    case ST_CAL_PROMPT: {
      if (btn == BTN_SHORT) {
        // Go straight to digit entry — same as log entry
        logDigits[0] = 0; logDigits[1] = 8; logDigits[2] = 0;
        logDigitPos  = 0; holdStartMs = 0; holdScrolling = false;
        goTo(ST_CAL_RANGE);   // reuse ST_CAL_RANGE as digit entry for cal
        drawDigitEntry(0);
      }
      if (btn == BTN_LONG || stateAge() >= 5000) {
        goTo(ST_IDLE);
      }
      break;
    }

    // ── CAL DIGIT ENTRY (reuses ST_CAL_RANGE state slot) ─────────
    case ST_CAL_RANGE: {
      bool btnDown = (digitalRead(BTN_PIN) == LOW);
      int  maxV    = (logDigitPos == 0) ? 3 : 9;
      if (handleHoldScroll(btnDown, maxV)) {
        drawDigitEntry(0); break;
      }
      if (btn == BTN_SHORT) {
        digitIncrement(maxV); drawDigitEntry(0);
      }
      if (btn == BTN_DOUBLE && !holdScrolling) {
        logDigitPos++;
        if (logDigitPos > 2) {
          int glucose = logDigits[0]*100 + logDigits[1]*10 + logDigits[2];
          glucose = constrain(glucose, 40, 400);
          goTo(ST_CAL_CONFIRM); drawCalConfirm();
        } else {
          drawDigitEntry(0);
        }
      }
      // Long press = abort → back to idle
      if (btn == BTN_LONG && !holdScrolling) {
        goTo(ST_IDLE);
      }
      break;
    }

    // ── CAL CONFIRM ──────────────────────────────────────────────
    case ST_CAL_CONFIRM: {
      int glucose = logDigits[0]*100 + logDigits[1]*10 + logDigits[2];
      glucose = constrain(glucose, 40, 400);
      if (btn == BTN_SHORT) {
        calAddReading((float)glucose);
        goTo(ST_CAL_SAVED);
        drawCalSaved();
      }
      if (btn == BTN_DOUBLE) {
        logDigitPos = 0; holdStartMs = 0; holdScrolling = false;
        goTo(ST_CAL_RANGE); drawDigitEntry(0);
      }
      // Long press = abort → back to idle
      if (btn == BTN_LONG) {
        goTo(ST_IDLE);
      }
      break;
    }

    // ── CAL SAVED ────────────────────────────────────────────────
    case ST_CAL_SAVED: {
      if (stateAge() >= 3000) goTo(ST_IDLE);
      break;
    }
  }
}
