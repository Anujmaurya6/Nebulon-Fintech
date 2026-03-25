# 🚀 Smart Vault – AI Powered Fintech App

Smart Vault is a modern fintech application designed to track income, expenses, and provide intelligent financial insights using AI.

---

## 🌟 Features

### 💰 Expense & Income Tracking
- Add income and expenses easily
- Category-based tracking (Food, Transport, Shopping, etc.)
- Real-time balance calculation

### 📊 Analytics Dashboard
- Monthly income vs expense
- Category-wise spending (Pie Chart)
- Profitability & savings rate
- Dynamic charts (no static UI)

### 🤖 AI Financial Assistant
- Analyzes your spending habits
- Gives insights like:
  - “Your expenses increased this month”
  - “Food category spending is high”
- Supports Hindi & English + Voice output

### 🌐 Offline Mode + Auto Sync
- Works even without internet
- Saves data locally
- Auto syncs when online
- Shows message: "🔄 Syncing your data..."

### 🔐 Secure Authentication
- Email/Password login
- Google & GitHub OAuth
- Secured by Insforge

---

## 🛠️ Tech Stack

### Frontend
- Flutter
- fl_chart (for analytics)
- Provider / State Management

### Backend
- REST API (Insforge / Custom backend)
- JSON-based data handling

### Database
- Local: Hive / Sqflite (Offline support)
- Remote: Insforge Database

---

## 📱 Screens

- Login / Signup (OAuth enabled)
- Dashboard (Real-time data)
- Analytics (Charts & insights)
- Add Income / Expense
- AI Assistant

---

## ⚙️ Installation

```bash
git clone https://github.com/Anujmaurya6/Nebulon-Fintech.git
cd Nebulon-Fintech
flutter pub get
flutter run
