# Keystroke Dynamics Authentication Integration

This document describes how the keystroke dynamics authentication system has been integrated into the Samsung Prism Flutter application.

## Overview

The integration provides a dual-layer authentication system that combines traditional email/password authentication with keystroke dynamics pattern recognition for enhanced security.

## Architecture

### Backend Components
- **Flask API Server** (`app.py`): Main server handling ML operations
- **Machine Learning Model**: IsolationForest for anomaly detection
- **Feature Extraction**: Analyzes hold time, keydown-keydown time, and keyup-keydown time

### Frontend Components
- **Models** (`keystroke_models.dart`): Data structures for keystroke events and API responses
- **Service** (`keystroke_auth_service.dart`): HTTP client for API communication
- **Provider** (`keystroke_auth_provider.dart`): State management using Provider pattern
- **Widget** (`keystroke_recorder.dart`): Records keystroke timing patterns
- **Screens**: Enhanced login and setup screens

## Usage Flow

### 1. Initial Setup
1. User opens the enhanced login screen
2. Toggles keystroke authentication ON
3. If first time, redirected to keystroke setup screen
4. Server configuration and connection testing
5. Training data collection (5 samples)
6. Model training and persistence

### 2. Authentication Flow
1. User enters email and password
2. Traditional authentication validates credentials
3. If keystroke authentication is enabled:
   - Keystroke patterns are recorded during password entry
   - Patterns sent to ML model for verification
   - Both authentications must pass for login success

### 3. Routes and Navigation

The following routes have been added to support keystroke authentication:

```dart
'/enhanced-login': (context) => const EnhancedLoginScreen(),
'/keystroke-setup': (context) => const KeystrokeSetupScreen(),
```

## Key Features

### Enhanced Security
- Dual-layer authentication (something you know + how you type)
- Machine learning-based pattern recognition
- Real-time keystroke timing capture

### User Experience
- Optional keystroke authentication (can be toggled)
- Progressive setup with step-by-step guidance
- Graceful fallback to traditional authentication if keystroke fails

### Technical Features
- Provider pattern for state management
- HTTP service abstraction for API calls
- Comprehensive error handling
- Model persistence and caching

## Configuration

### Backend Server Setup
1. Start the Flask backend server:
   ```bash
   cd keystroke_auth_backend
   python app.py
   ```

2. The server runs on `http://localhost:5000` by default

### Flutter App Configuration
1. The app automatically detects and configures the keystroke service
2. Server URL can be configured in the setup screen
3. Configuration is persisted using SharedPreferences

## API Endpoints

### Training
- **POST** `/train` - Train user model with keystroke samples
- **GET** `/user/<user_id>/info` - Get user training status

### Authentication
- **POST** `/predict` - Authenticate user keystroke pattern
- **GET** `/health` - Server health check

## State Management

The `KeystrokeAuthProvider` manages the following states:
- `idle`: Ready for operations
- `recording`: Capturing keystroke patterns
- `training`: Training the ML model
- `authenticating`: Verifying keystroke patterns
- `success`: Operation completed successfully
- `failure`: Authentication failed
- `error`: System error occurred

## Error Handling

The system includes comprehensive error handling for:
- Network connectivity issues
- Server communication failures
- ML model training errors
- Authentication timeouts
- Invalid keystroke patterns

## Testing

Integration tests have been created to verify:
- Screen loading and UI components
- Provider state management
- Authentication flow
- Error scenarios

Run tests with:
```bash
flutter test test/keystroke_integration_test.dart
```

## Security Considerations

1. **Data Privacy**: Keystroke timing data is processed locally and securely transmitted
2. **Fallback Security**: Traditional authentication remains active as backup
3. **Model Security**: User models are isolated and stored securely
4. **Network Security**: HTTPS support for production deployments

## Future Enhancements

Potential improvements include:
- Adaptive learning to improve model accuracy over time
- Multi-device keystroke profile synchronization
- Advanced analytics and user behavior insights
- Integration with biometric authentication systems

## Troubleshooting

### Common Issues

1. **Server Connection Failed**
   - Verify Flask server is running
   - Check network connectivity
   - Ensure correct server URL configuration

2. **Training Failed**
   - Ensure sufficient training samples (minimum 5)
   - Check for consistent typing patterns
   - Verify server has sufficient resources

3. **Authentication Failed**
   - Try typing more naturally
   - Re-train if typing patterns have changed significantly
   - Check server logs for detailed error information

### Debug Mode

Enable debug logging by setting the debug flag in the provider:
```dart
final provider = KeystrokeAuthProvider();
provider.setDebugMode(true);
```

This provides detailed logs of the authentication process and can help identify issues.
