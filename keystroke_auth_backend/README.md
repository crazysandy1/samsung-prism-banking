# Keystroke Dynamics Authentication Backend

A Flask-based REST API backend for user authentication using keystroke dynamics and machine learning. This application analyzes typing patterns to distinguish between genuine users and imposters.

## Features

- **User Training**: Collect and store keystroke timing data for each user
- **Anomaly Detection**: Use IsolationForest algorithm to detect typing pattern anomalies
- **Model Persistence**: Save trained models for each user using joblib
- **Feature Extraction**: Extract hold time, keydown-keydown, and keyup-keydown timings
- **REST API**: Simple JSON-based API for mobile app integration
- **Health Monitoring**: Built-in health check and user info endpoints

## Technical Architecture

### Machine Learning Approach
- **Algorithm**: IsolationForest (Anomaly Detection)
- **Features**: Three types of keystroke timings:
  - Hold Time: Time between key press and release
  - Keydown-Keydown Time: Time between consecutive key presses
  - Keyup-Keydown Time: Time between key release and next key press
- **Training**: Requires minimum 5 samples per user before model training
- **Prediction**: Returns genuine user (authenticated) or imposter (anomaly detected)

### Data Storage
- **User Features**: Stored as `.npy` files in `user_models/` directory
- **Trained Models**: Saved as `.joblib` files with metadata
- **Feature Padding**: Handles variable-length feature vectors automatically

## Installation

### Prerequisites
- Python 3.7 or higher
- pip package manager

### Setup Steps

1. **Clone or Download the Project**
   ```bash
   cd keystroke_auth_backend
   ```

2. **Create Virtual Environment (Recommended)**
   ```bash
   python -m venv venv
   
   # On Windows
   venv\Scripts\activate
   
   # On macOS/Linux
   source venv/bin/activate
   ```

3. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the Application**
   ```bash
   python app.py
   ```

The server will start on `http://0.0.0.0:5000` and be accessible from any device on your network.

## API Documentation

### Base URL
```
http://localhost:5000
```

### Endpoints

#### 1. Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "Keystroke Dynamics Authentication API",
  "timestamp": "2025-08-27T10:30:00.000000"
}
```

#### 2. Train User Model
```http
POST /train
```

**Request Body:**
```json
{
  "user_id": "unique_user_identifier",
  "keystroke_data": [
    {"key": "p", "event": "down", "timestamp": 100},
    {"key": "p", "event": "up", "timestamp": 250},
    {"key": "a", "event": "down", "timestamp": 350},
    {"key": "a", "event": "up", "timestamp": 510},
    {"key": "s", "event": "down", "timestamp": 600},
    {"key": "s", "event": "up", "timestamp": 750}
  ]
}
```

**Response (Before Model Training):**
```json
{
  "status": "Training data received",
  "samples_count": 3,
  "model_trained": false,
  "message": "Need 5 samples to train model"
}
```

**Response (After Model Training):**
```json
{
  "status": "Training data received",
  "samples_count": 5,
  "model_trained": true
}
```

#### 3. Authenticate User
```http
POST /predict
```

**Request Body:** Same format as `/train`

**Response (Genuine User):**
```json
{
  "authenticated": true,
  "confidence_score": 0.15,
  "user_id": "unique_user_identifier"
}
```

**Response (Imposter Detected):**
```json
{
  "authenticated": false,
  "reason": "Typing pattern anomaly detected",
  "confidence_score": -0.25,
  "user_id": "unique_user_identifier"
}
```

**Error Response:**
```json
{
  "error": "User model not found. Please train the model first."
}
```

#### 4. Get User Information
```http
GET /user/{user_id}/info
```

**Response:**
```json
{
  "user_id": "unique_user_identifier",
  "training_samples": 5,
  "has_trained_model": true,
  "min_samples_required": 5,
  "max_feature_length": 12
}
```

## Integration with Flutter App

### Sample Flutter HTTP Client Code

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class KeystrokeAuthService {
  final String baseUrl = 'http://YOUR_SERVER_IP:5000';
  
  Future<Map<String, dynamic>> trainUser(String userId, List<Map<String, dynamic>> keystrokeData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/train'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'keystroke_data': keystrokeData,
      }),
    );
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>> authenticateUser(String userId, List<Map<String, dynamic>> keystrokeData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'keystroke_data': keystrokeData,
      }),
    );
    return jsonDecode(response.body);
  }
}
```

### Keystroke Data Format

Each keystroke event should include:
- `key`: The character or key pressed (e.g., "a", "Enter", "Shift")
- `event`: Either "down" (key press) or "up" (key release)
- `timestamp`: Time in milliseconds when the event occurred

## File Structure

```
keystroke_auth_backend/
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── README.md             # This file
└── user_models/          # Created automatically
    ├── user1_features.npy     # User's training features
    ├── user1.joblib          # User's trained model
    └── user1_metadata.json   # Model metadata
```

## Error Handling

The API includes comprehensive error handling for:
- Invalid JSON requests
- Missing required fields
- Insufficient training data
- Model loading/saving errors
- Feature extraction failures

All errors return appropriate HTTP status codes and descriptive error messages.

## Security Considerations

1. **Network Security**: Use HTTPS in production
2. **Input Validation**: All inputs are validated before processing
3. **Rate Limiting**: Consider implementing rate limiting for production use
4. **User ID Security**: Use secure, non-guessable user identifiers
5. **Model Protection**: Trained models are stored locally and not exposed via API

## Performance Optimization

- **Feature Caching**: Features are cached to disk for quick model training
- **Model Persistence**: Trained models persist between server restarts
- **Memory Efficient**: Uses numpy arrays for efficient data handling
- **Batch Processing**: Can handle multiple training samples efficiently

## Troubleshooting

### Common Issues

1. **Module Import Errors**
   ```bash
   pip install --upgrade -r requirements.txt
   ```

2. **Permission Errors on Model Directory**
   ```bash
   mkdir user_models
   chmod 755 user_models
   ```

3. **Network Access Issues**
   - Ensure firewall allows port 5000
   - Check that `0.0.0.0` binding is working
   - Verify mobile device is on same network

4. **Model Training Not Working**
   - Ensure minimum 5 training samples
   - Check that keystroke data has both 'down' and 'up' events
   - Verify timestamp format is consistent

### Debug Mode

The application runs in debug mode by default. For production:

```python
app.run(host='0.0.0.0', port=5000, debug=False)
```

## Research Background

This implementation is based on the research and methodology from:
- **Reference Repository**: https://github.com/nikhilagr/User-Authentication-using-keystroke-dynamics
- **Machine Learning Approach**: Anomaly detection using IsolationForest
- **Feature Engineering**: Time-based keystroke dynamics analysis

## Future Enhancements

- Database integration for user management
- Real-time model retraining
- Multiple authentication algorithms
- Web-based admin dashboard
- Advanced anomaly scoring methods
- Support for different input devices

## License

This project is created for educational and research purposes as part of the Samsung Prism project.

## Support

For technical support or questions about the implementation, please refer to the source code comments and this documentation.
