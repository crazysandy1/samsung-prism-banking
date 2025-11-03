# Samsung Prism Multi-Agent Banking System

A sophisticated AI-powered banking assistance system built with Google's Agent Development Kit principles, featuring specialized agents for different banking functions.

## 🎯 Overview

The Samsung Prism Multi-Agent System provides intelligent banking assistance through specialized agents:

- **AccountAgent** - Handles balance inquiries and transactions
- **LoanAgent** - Deals with loan eligibility and EMI queries  
- **CardAgent** - Manages card limits, status, and activation
- **SupportAgent** - General FAQs and non-financial help

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Web Service                      │
├─────────────────────────────────────────────────────────────┤
│                  Multi-Agent System                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Account   │ │    Loan     │ │    Card     │ │   Support   │ │
│  │    Agent    │ │   Agent     │ │   Agent     │ │    Agent    │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                   Firebase Firestore                       │
│         (Connected to Flutter App Database)                │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Features

### Core Capabilities
- **Intelligent Query Routing** - Automatically routes queries to the most appropriate agent
- **Confidence-Based Selection** - Uses confidence scores to select the best agent for each query
- **Firebase Integration** - Direct connection to your Flutter app's Firebase database
- **RESTful API** - Easy integration with any frontend application
- **Comprehensive Logging** - Full interaction logging for analytics and debugging

### Agent Specializations

#### AccountAgent
- Check account balances
- View transaction history
- Get recent transactions
- Money transfer guidance
- Account statement information

#### LoanAgent  
- Check loan eligibility
- Calculate EMI
- Provide interest rates
- Loan application status
- Personal/Home/Car/Education loan information

#### CardAgent
- Check card limits (credit/debit)
- Card activation guidance
- Block/unblock cards
- Check card status
- PIN change/reset services
- Card replacement process

#### SupportAgent
- Contact information and customer care
- Branch and ATM locations
- Mobile app and internet banking help
- Security guidelines
- Complaint registration
- General banking FAQs

## 📋 Prerequisites

- Python 3.8 or higher
- Firebase project with Firestore database
- Google Cloud service account (for Firebase access)

## ⚡ Quick Start

### 1. Clone and Setup
```bash
# Navigate to the agent development kit folder
cd agent_development_kit

# Run setup script
python setup.py
```

### 2. Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
# Add your Firebase service account key path
# Configure other settings as needed
```

### 3. Firebase Setup
Ensure your Firebase Firestore has these collections:
- `users` - User profile data
- `user_balances` - Account balances
- `transactions` - Transaction history
- `user_cards` - Card information
- `loan_applications` - Loan records
- `agent_interactions` - Interaction logs

### 4. Run the System
```bash
# Windows
run.bat

# Or manually
python main.py
```

### 5. Test the API
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **System Status**: http://localhost:8000/status

## 📡 API Usage

### Process a Query
```bash
POST /query
Content-Type: application/json

{
  "user_id": "user123",
  "query_text": "What is my account balance?",
  "context": {
    "session_id": "session123"
  }
}
```

### Response
```json
{
  "agent_name": "AccountAgent",
  "response_text": "Your current account balance is ₹25,450.00. Last updated: 2025-01-01",
  "confidence": 0.95,
  "action_taken": "balance_inquiry",
  "data": {
    "balance": 25450.00,
    "last_updated": "2025-01-01"
  },
  "timestamp": "2025-01-01T12:00:00"
}
```

## 🔗 Flutter Integration

### Add HTTP Client to Flutter
```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
```

### Flutter Service Class
```dart
// lib/services/agent_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AgentService {
  static const String baseUrl = 'http://localhost:8000';
  
  static Future<Map<String, dynamic>> queryAgent({
    required String userId,
    required String queryText,
    Map<String, dynamic>? context,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/query'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'query_text': queryText,
        'context': context,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to query agent');
    }
  }
}
```

### Usage in Flutter Widget
```dart
// Example usage in a Flutter widget
class ChatWidget extends StatefulWidget {
  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];

  Future<void> _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add({'type': 'user', 'text': query});
    });

    try {
      final response = await AgentService.queryAgent(
        userId: 'current_user_id', // Get from your auth system
        queryText: query,
        context: {'session_id': 'flutter_session'},
      );

      setState(() {
        _messages.add({
          'type': 'agent',
          'text': response['response_text'],
          'agent': response['agent_name'],
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'type': 'error',
          'text': 'Sorry, I encountered an error. Please try again.',
        });
      });
    }

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return ListTile(
                title: Text(message['text']),
                subtitle: message['type'] == 'agent' 
                  ? Text('Agent: ${message['agent']}')
                  : null,
                leading: Icon(
                  message['type'] == 'user' 
                    ? Icons.person 
                    : Icons.smart_toy,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask me anything about banking...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                onPressed: _sendMessage,
                icon: Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

## 🔧 Configuration

### Environment Variables (.env)
```env
# Firebase Configuration
GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account-key.json
FIREBASE_PROJECT_ID=your-project-id

# API Configuration  
API_HOST=0.0.0.0
API_PORT=8000
CONFIDENCE_THRESHOLD=0.6
```

### Agent Configuration
Modify confidence thresholds and capabilities in individual agent files:
- `agents/account_agent.py`
- `agents/loan_agent.py`
- `agents/card_agent.py`
- `agents/support_agent.py`

## 📊 Monitoring and Analytics

### Health Check Endpoint
```bash
GET /health
```

### System Status
```bash
GET /status
```

### Agent Capabilities
```bash
GET /capabilities
GET /agents/{agent_name}/capabilities
```

## 🔍 Example Queries

### Account Queries
- "What is my account balance?"
- "Show me my recent transactions"
- "I want to transfer money"

### Loan Queries  
- "Am I eligible for a personal loan?"
- "Calculate EMI for 5 lakh home loan"
- "What are current interest rates?"

### Card Queries
- "What is my credit card limit?"
- "How do I activate my new card?"
- "Block my card immediately"

### Support Queries
- "Where is the nearest branch?"
- "How do I download the mobile app?"
- "Customer care contact number"

## 🛠️ Development

### Project Structure
```
agent_development_kit/
├── agents/                 # Agent implementations
│   ├── base_agent.py      # Base agent class
│   ├── account_agent.py   # Account operations
│   ├── loan_agent.py      # Loan services
│   ├── card_agent.py      # Card management
│   ├── support_agent.py   # General support
│   └── multi_agent_system.py # System coordinator
├── config/                # Configuration
│   └── firebase_config.py # Firebase setup
├── main.py               # FastAPI application
├── requirements.txt      # Python dependencies
├── setup.py             # Setup script
├── run.bat              # Windows runner
└── README.md            # This file
```

### Adding New Agents
1. Create new agent class inheriting from `BaseAgent`
2. Implement required methods: `can_handle()`, `process_query()`, `get_capabilities()`
3. Register agent in `MultiAgentSystem`
4. Update API documentation

### Testing
```bash
# Test specific query
POST /test/query?query_text=What%20is%20my%20balance&user_id=test123

# Run health check
GET /health

# Check system status
GET /status
```

## 🔒 Security Considerations

### Production Deployment
- Use proper Firebase security rules
- Implement API authentication and rate limiting
- Use HTTPS in production
- Validate and sanitize all inputs
- Monitor for abuse and anomalies

### Data Privacy
- Implement proper data retention policies
- Ensure compliance with banking regulations
- Log interactions securely
- Use encryption for sensitive data

## 🚀 Deployment

### Docker Deployment
```dockerfile
FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "main.py"]
```

### Cloud Deployment
- Deploy to Google Cloud Run, AWS Lambda, or Azure Functions
- Configure environment variables
- Set up proper monitoring and logging
- Implement auto-scaling based on load

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is part of the Samsung Prism banking application. All rights reserved.

## 📞 Support

For technical support or questions:
- Create an issue in the repository
- Contact the development team
- Check the API documentation at `/docs`

---

**Samsung Prism Multi-Agent Banking System** - Intelligent banking assistance powered by AI 🚀
