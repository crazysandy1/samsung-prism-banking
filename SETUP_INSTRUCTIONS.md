# Samsung Prism Banking App - Setup Instructions

This guide will help you clone the project and set up your own Firebase credentials to run the Samsung Prism Banking App.

## 📋 Prerequisites

Before starting, make sure you have:
- Flutter SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extension
- Git installed on your machine
- Google account for Firebase
- Python 3.8+ (for Agent Development Kit)
- Node.js (for any web components)

## 🚀 Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/DarshanCHMSR/Samsung_prism.git

# Navigate to the project directory
cd Samsung_prism
```

## 🔥 Step 2: Create New Firebase Project

### 2.1 Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `samsung-prism-banking-[your-name]`
4. Enable Google Analytics (recommended)
5. Choose or create Analytics account
6. Click "Create project"

### 2.2 Enable Required Services
In your Firebase project, enable these services:

1. **Authentication**
   - Go to Authentication → Sign-in method
   - Enable Email/Password
   - Enable Google Sign-in (optional)

2. **Firestore Database**
   - Go to Firestore Database → Create database
   - Start in test mode (for now)
   - Choose your preferred location

3. **Storage**
   - Go to Storage → Get started
   - Start in test mode
   - Choose same location as Firestore

## 📱 Step 3: Configure Flutter App

### 3.1 Android Configuration
1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.samsung.prism.banking_app`
3. Download `google-services.json`
4. Place it in: `samsung_prism/android/app/google-services.json`

### 3.2 iOS Configuration (if needed)
1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID: `com.samsung.prism.bankingApp`
3. Download `GoogleService-Info.plist`
4. Place it in: `samsung_prism/ios/Runner/GoogleService-Info.plist`

### 3.3 Web Configuration (if needed)
1. In Firebase Console, click "Add app" → Web
2. Enter app nickname: `Samsung Prism Banking Web`
3. Copy the Firebase configuration object

### 3.4 Update Firebase Options
1. Open `samsung_prism/lib/firebase_options.dart`
2. Replace the existing configuration with your new Firebase project details:

```dart
// Replace these values with your Firebase project configuration
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',
  appId: 'YOUR_IOS_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  iosBundleId: 'com.samsung.prism.bankingApp',
);

static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',
  appId: 'YOUR_WEB_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

## 🤖 Step 4: Configure Agent Development Kit

### 4.1 Create Service Account
1. In Firebase Console, go to Project Settings → Service accounts
2. Click "Generate new private key"
3. Save the JSON file as: `agent_development_kit/config/firebase-adminsdk.json`

### 4.2 Update Agent Configuration
1. Open `agent_development_kit/config/firebase_config.py`
2. Update the configuration:

```python
import firebase_admin
from firebase_admin import credentials, firestore
import os

# Path to your service account key file
SERVICE_ACCOUNT_PATH = os.path.join(os.path.dirname(__file__), 'firebase-adminsdk.json')

# Initialize Firebase Admin SDK
cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
firebase_admin.initialize_app(cred)

# Initialize Firestore client
db = firestore.client()

# Your project configuration
PROJECT_ID = 'YOUR_PROJECT_ID'
```

### 4.3 Install Agent Dependencies
```bash
cd agent_development_kit
pip install -r requirements.txt
```

## 🔐 Step 5: Configure Keystroke Authentication Backend

### 5.1 Update Backend Configuration
1. Open `keystroke_auth_backend/config.py`
2. Update Firebase configuration:

```python
import firebase_admin
from firebase_admin import credentials, firestore
import os

# Firebase configuration
FIREBASE_CONFIG = {
    'service_account_path': 'path/to/your/firebase-adminsdk.json',
    'project_id': 'YOUR_PROJECT_ID'
}

# Initialize Firebase Admin SDK
cred = credentials.Certificate(FIREBASE_CONFIG['service_account_path'])
firebase_admin.initialize_app(cred)
db = firestore.client()
```

### 5.2 Install Backend Dependencies
```bash
cd keystroke_auth_backend
pip install -r requirements.txt
```

## 🔒 Step 6: Update Security Rules

### 6.1 Firestore Security Rules
In Firebase Console, go to Firestore Database → Rules and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Transactions are user-specific
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Bank accounts are user-specific
    match /bank_accounts/{accountId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Agent conversations are user-specific
    match /agent_conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Voice sessions are user-specific
    match /voice_sessions/{sessionId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Notifications are user-specific
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

### 6.2 Storage Security Rules
In Firebase Console, go to Storage → Rules and replace with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 📦 Step 7: Install Dependencies

### 7.1 Flutter Dependencies
```bash
cd samsung_prism
flutter pub get
```

### 7.2 Generate Required Files
```bash
flutter packages pub run build_runner build
```

## 🧪 Step 8: Test the Setup

### 8.1 Test Flutter App
```bash
cd samsung_prism
flutter run
```

### 8.2 Test Agent Development Kit
```bash
cd agent_development_kit
python test_config.py
```

### 8.3 Test Keystroke Backend
```bash
cd keystroke_auth_backend
python test_api.py
```

## 🔄 Step 9: Environment Variables (Optional but Recommended)

Create a `.env` file in the root directory:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com

# Gemini API (for AI features)
GEMINI_API_KEY=your_gemini_api_key

# Other configurations
DEBUG_MODE=false
LOG_LEVEL=info
```

## 📝 Step 10: Initialize Database with Sample Data (Optional)

Run the initialization script to create sample data:

```bash
cd agent_development_kit
python -c "
from config.firebase_config import db
from datetime import datetime

# Create sample user data structure
sample_data = {
    'users': {
        'sample_user_id': {
            'email': 'demo@example.com',
            'displayName': 'Demo User',
            'createdAt': datetime.now(),
            'isActive': True
        }
    }
}

print('Database initialized with sample structure')
"
```

## 🚨 Important Security Notes

1. **Never commit sensitive files to Git:**
   - `google-services.json`
   - `GoogleService-Info.plist`
   - `firebase-adminsdk.json`
   - `.env` files

2. **Add to .gitignore:**
```gitignore
# Firebase
**/google-services.json
**/GoogleService-Info.plist
**/firebase-adminsdk.json
**/.env

# User models (contains sensitive data)
keystroke_auth_backend/user_models/
```

3. **Update security rules** before going to production
4. **Use environment variables** for sensitive configuration

## 🐛 Troubleshooting

### Common Issues:

1. **"Firebase project not found"**
   - Verify project ID in firebase_options.dart
   - Check if all services are enabled

2. **"Permission denied" in Firestore**
   - Verify security rules are updated
   - Check user authentication status

3. **"Service account key not found"**
   - Verify file path in configuration
   - Ensure JSON file is properly downloaded

4. **Flutter build issues**
   - Run `flutter clean && flutter pub get`
   - Check Flutter and Dart SDK versions

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Verify all configuration files are updated
3. Check Firebase Console for any error logs
4. Create an issue in the GitHub repository

## 🎉 You're All Set!

Once you've completed all steps, you should have a fully functional Samsung Prism Banking App with your own Firebase backend. The app includes:

- 🔐 Secure authentication
- 💰 Banking transactions
- 🤖 AI-powered chat agents
- 🗣️ Voice assistant
- 🔒 Keystroke authentication
- 🌍 Multilingual support (13 languages)
- 📱 Cross-platform compatibility

Happy coding! 🚀