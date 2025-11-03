# Samsung Prism Multi-Agent System Setup Guide

## 🔧 Configuration Requirements

### 1. Firebase Configuration

You have **TWO OPTIONS** to configure Firebase:

#### Option A: Using Firebase Service Account (Recommended)

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `samsung-prism-default` (or your project name)
3. **Navigate to**: Project Settings → Service Accounts
4. **Generate new private key**:
   - Click "Generate new private key"
   - Download the JSON file
   - Rename it to `samsung-prism-firebase-adminsdk.json`
   - Place it in the `config/` folder

5. **Update .env file**:
   ```env
   FIREBASE_PROJECT_ID=samsung-prism-default
   GOOGLE_CLOUD_PROJECT=samsung-prism-default
   GOOGLE_APPLICATION_CREDENTIALS=config/samsung-prism-firebase-adminsdk.json
   ```

#### Option B: Using Project ID Only (Simple)

1. **Find your project ID** in Firebase Console
2. **Update .env file**:
   ```env
   FIREBASE_PROJECT_ID=your-actual-project-id
   GOOGLE_CLOUD_PROJECT=your-actual-project-id
   # Comment out or remove the GOOGLE_APPLICATION_CREDENTIALS line
   ```

### 2. Gemini API Configuration

1. **Go to Google AI Studio**: https://makersuite.google.com/app/apikey
2. **Create API Key**:
   - Click "Create API Key"
   - Copy the generated key

3. **Update .env file**:
   ```env
   GEMINI_API_KEY=your-actual-gemini-api-key
   ```

### 3. Complete .env Configuration

Your final `.env` file should look like this:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=samsung-prism-default
GOOGLE_CLOUD_PROJECT=samsung-prism-default
GOOGLE_APPLICATION_CREDENTIALS=config/samsung-prism-firebase-adminsdk.json

# AI Configuration
GEMINI_API_KEY=AIzaSyC-your-actual-gemini-api-key

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_ENV=development

# Agent Configuration
CONFIDENCE_THRESHOLD=0.6
LOG_LEVEL=INFO

# Security
SECRET_KEY=samsung-prism-multi-agent-secret-key
API_KEY=your-api-key-here
```

## 🚀 Quick Start

### Step 1: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 2: Configure Environment
1. Copy `.env.example` to `.env` (if it doesn't exist)
2. Fill in your Firebase project ID
3. Add your Gemini API key
4. Optionally add Firebase service account credentials

### Step 3: Test Firebase Connection
```bash
python -c "
from config.firebase_config import firebase_config
import asyncio
async def test():
    result = firebase_config.initialize_firebase()
    if result:
        print('✅ Firebase connection successful!')
        firebase_config.test_connection()
    else:
        print('❌ Firebase connection failed!')
asyncio.run(test())
"
```

### Step 4: Run the Server
```bash
python main.py
```

Or use the batch file:
```bash
run.bat
```

## 🔍 Troubleshooting

### Firebase Issues

**Error: "Project ID is required"**
- Ensure `FIREBASE_PROJECT_ID` is set in `.env`
- Check that your project ID is correct

**Error: "quota exceeded" or "API not enabled"**
- Enable Firestore API in Google Cloud Console
- Set up billing if required

**Error: "service account credentials"**
- Download service account JSON from Firebase Console
- Place it in the `config/` folder
- Update `GOOGLE_APPLICATION_CREDENTIALS` path

### Gemini API Issues

**Error: "API key not found"**
- Get API key from Google AI Studio
- Add it to `.env` as `GEMINI_API_KEY`

**Error: "API not enabled"**
- Enable Generative AI API in Google Cloud Console

### Connection Test

Run this test to verify your setup:

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "agents": ["AccountAgent", "LoanAgent", "CardAgent", "SupportAgent"],
  "firebase_connected": true,
  "timestamp": "2025-01-15T10:30:00"
}
```

## 📱 Flutter Integration

Once the server is running, test the agents:

```bash
# Test Account Agent
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "query_text": "What is my account balance?",
    "context": {}
  }'
```

## 🔐 Security Notes

- Keep your `.env` file secure and never commit it to version control
- Use strong API keys in production
- Set up proper Firebase security rules
- Enable authentication for production deployments

## 📊 Monitoring

Check agent performance:
- Health endpoint: `GET /health`
- Agent capabilities: `GET /agents/capabilities`
- Query endpoint: `POST /query`

For detailed logs, check the console output when running the server.
