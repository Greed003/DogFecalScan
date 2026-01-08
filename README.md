# 🐶 Dog Fecal Scan App

A **Flutter mobile app** that helps pet owners monitor their dogs’ digestive health.  
The app classifies dog feces into four categories using AI:

- ✅ **Normal**
- 🟠 **Dry**
- 🟡 **Soft**
- 🔴 **Watery**

It also provides health insights and recommendations based on the classification.  

---

## 📱 Features
- 📷 **Image Capture & Upload** – Take or select a stool image.
- 🤖 **AI Classification** – Classifies stool into 4 categories.
- 📊 **History Tracking** – View past classifications with dates, results, and icons.
- 🎨 **Dark Brown & Gold Theme** – Clean and pet-friendly UI design.
- ⚡ **Offline Support** (with TensorFlow Lite model).

---

## 📸 Screenshots
(Add screenshots here once available)

---

## 🛠️ Tech Stack
- **Frontend:** Flutter (Dart)
- **ML Model:** TensorFlow Lite / MobileNetV3 (planned integration)
- **State Management:** setState (can upgrade to Provider/Bloc)
- **Storage:** Local storage (SQLite / SharedPreferences for history)

---

## 🚀 Getting Started

---

### 1. Clone the Repository
```bash
git clone https://github.com/Greed003/DogFecalScan.git
cd DogFecalScan

---

### 2. Install Flutter Dependencies
```bash
flutter pub get

---

### 3. Check Flutter Environment (Recommended)
```bash
flutter doctor

Resolve any reported issues before continuing.

---

### 4. Connect a Device or Start an Emulator
- **Android Emulator**
```bash
flutter emulators
flutter emulators --launch <emulator_id>
- **Physical Device**
Enable **USB debugging** on your Android phone and connect it via USB.

---

### 5. Run the App
```bash
flutter run

---

### 6. (Optional) Clean & Rebuild
```bash
flutter clean
flutter pub get
flutter run

---

## 🧪 Useful Flutter Commands
```bash
flutter devices        # List connected devices
flutter run -d chrome  # Run on Chrome (web)
flutter build apk      # Build APK for Android
flutter build appbundle # Build AAB for Play Store

---