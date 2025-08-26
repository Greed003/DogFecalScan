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
- ⚡ **Offline Support** (with TensorFlow Lite model, if added).

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

### 1. Clone the Repository
```bash
git clone https://github.com/Greed003/DogFecalScan.git
cd DogFecalScan
