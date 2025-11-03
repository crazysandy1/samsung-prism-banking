import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/agent_api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/voice_assistant_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/voice_ui_widgets.dart';
import '../widgets/voice_settings_widgets.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? agentName;
  final double? confidence;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.agentName,
    this.confidence,
  });
}

class AgentChatScreen extends StatefulWidget {
  const AgentChatScreen({Key? key}) : super(key: key);

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }



  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "Hello! I'm your Samsung Prism AI Banking Assistant. I can help you with:\n\n"
            "💰 Account Balance & Transactions\n"
            "🏦 Loan Eligibility & EMI Queries\n"
            "💳 Credit Card Limits & Status\n"
            "🆘 General Banking Support\n\n"
            "How can I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
        agentName: "System",
        confidence: 1.0,
      ));
    });
  }



  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceAssistantProvider>(
      builder: (context, voiceProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'AI Banking Assistant',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  ],
                ),
              ],
            ),
            actions: [
              // Voice Language Selector
              const VoiceLanguageSelector(),
              
              // Voice Settings
              IconButton(
                icon: const Icon(Icons.settings_voice, color: Colors.black54),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const VoiceSettingsDialog(),
                  );
                },
                tooltip: 'Voice Settings',
              ),
            ],
          ),
      body: Column(
        children: [
          // Voice Status Indicators
          Column(
            children: [
              // Voice Error Display
              if (voiceProvider.voiceState == VoiceState.error && voiceProvider.lastError != null)
                VoiceErrorWidget(
                  errorMessage: voiceProvider.lastError!,
                  onRetry: () async {
                    voiceProvider.clearError();
                    await voiceProvider.initialize();
                  },
                  onDismiss: voiceProvider.clearError,
                ),
              
              // Voice Recording Indicator
              VoiceRecordingIndicator(
                isRecording: voiceProvider.isListening,
                recognizedText: voiceProvider.recognizedText,
                onCancel: () {
                  voiceProvider.stopListening();
                  voiceProvider.clearRecognizedText();
                },
              ),
              
              // Voice Speaking Indicator
              VoiceSpeakingIndicator(
                isSpeaking: voiceProvider.isSpeaking,
                currentText: voiceProvider.currentSpeakingText,
                onStop: voiceProvider.stopSpeaking,
              ),
            ],
          ),
          
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, voiceProvider);
              },
            ),
          ),
          
          // Typing Indicator
          if (_isLoading) _buildTypingIndicator(),
          
          // Input Area with Voice
          _buildVoiceInputArea(voiceProvider),
        ],
      ),
      );
    });
  }

  // Voice-enabled input area
  Widget _buildVoiceInputArea(VoiceAssistantProvider voiceProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text Input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: voiceProvider.isListening 
                        ? 'Listening...' 
                        : 'Ask about your banking needs...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  // Auto-populate with recognized speech
                  onChanged: (text) {
                    if (text != voiceProvider.recognizedText && 
                        voiceProvider.recognizedText.isNotEmpty && 
                        !voiceProvider.isListening) {
                      // Clear recognized text after user starts typing
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        voiceProvider.clearRecognizedText();
                      });
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Voice Button
            VoiceWaveWidget(
              isListening: voiceProvider.isListening,
              soundLevel: voiceProvider.speechLevel,
              onTap: () => _handleVoiceInput(voiceProvider),
              size: 50,
            ),
            
            const SizedBox(width: 8),
            
            // Send Button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _sendMessage,
                icon: Icon(
                  _isLoading ? Icons.hourglass_empty : Icons.send,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle voice input
  Future<void> _handleVoiceInput(VoiceAssistantProvider voiceProvider) async {
    if (voiceProvider.isListening) {
      // Stop listening
      await voiceProvider.stopListening();
      
      // If we have recognized text, populate the input field
      if (voiceProvider.recognizedText.isNotEmpty) {
        _messageController.text = voiceProvider.recognizedText;
        voiceProvider.clearRecognizedText();
      }
    } else if (voiceProvider.isSpeaking) {
      // Stop speaking
      await voiceProvider.stopSpeaking();
    } else {
      // Start listening
      await _startVoiceListening(voiceProvider);
    }
  }

  // Start voice listening with proper initialization
  Future<void> _startVoiceListening(VoiceAssistantProvider voiceProvider) async {
    try {
      // Initialize if needed
      if (!voiceProvider.isInitialized) {
        final initialized = await voiceProvider.initialize();
        if (!initialized) {
          _showVoicePermissionDialog();
          return;
        }
      }

      // Get current language from locale provider
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      final currentLanguage = localeProvider.locale?.languageCode ?? 'en';
      
      // Set voice language to match app language
      await voiceProvider.setLanguage(currentLanguage);
      
      // Start listening
      await voiceProvider.startListening();
      
      // Auto-send after speech recognition completes
      _listenForSpeechComplete(voiceProvider);
      
    } catch (e) {
      _showSnackBar('Failed to start voice input: $e', isError: true);
    }
  }

  // Listen for speech recognition completion
  void _listenForSpeechComplete(VoiceAssistantProvider voiceProvider) {
    // Listen for state changes
    void listener() {
      if (voiceProvider.voiceState == VoiceState.processing && 
          voiceProvider.recognizedText.isNotEmpty) {
        
        // Remove listener to avoid multiple calls
        voiceProvider.removeListener(listener);
        
        // Auto-populate and send message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (voiceProvider.recognizedText.isNotEmpty) {
            _messageController.text = voiceProvider.recognizedText;
            voiceProvider.clearRecognizedText();
            _sendMessage(); // Auto-send voice message
          }
        });
      }
    }
    
    voiceProvider.addListener(listener);
  }

  // Show permission dialog for voice features
  void _showVoicePermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => VoicePermissionDialog(
        title: 'Microphone Permission Required',
        message: 'To use voice features, please grant microphone access.',
        onOpenSettings: () async {
          Navigator.of(context).pop();
          await openAppSettings();
        },
        onRetry: () async {
          Navigator.of(context).pop();
          final voiceProvider = Provider.of<VoiceAssistantProvider>(context, listen: false);
          await voiceProvider.initialize();
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, VoiceAssistantProvider voiceProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Message bubble
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: message.isUser
                              ? const Color(0xFF1976D2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomLeft: message.isUser
                                ? const Radius.circular(20)
                                : const Radius.circular(4),
                            bottomRight: message.isUser
                                ? const Radius.circular(4)
                                : const Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    
                    // TTS Button for agent messages
                    if (!message.isUser && voiceProvider.isInitialized) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _speakMessage(message.text, voiceProvider),
                        icon: Icon(
                          voiceProvider.isSpeaking && 
                          voiceProvider.currentSpeakingText == message.text
                              ? Icons.volume_up
                              : Icons.volume_up_outlined,
                          color: const Color(0xFF1976D2),
                          size: 20,
                        ),
                        tooltip: 'Listen to message',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!message.isUser && message.agentName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message.agentName!,
                          style: const TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 18, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  // Speak agent message using TTS
  Future<void> _speakMessage(String text, VoiceAssistantProvider voiceProvider) async {
    try {
      if (voiceProvider.isSpeaking && voiceProvider.currentSpeakingText == text) {
        // Stop current speech
        await voiceProvider.stopSpeaking();
      } else {
        // Get current language
        final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
        final currentLanguage = localeProvider.locale?.languageCode ?? 'en';
        
        // Set language and speak
        await voiceProvider.setLanguage(currentLanguage);
        await voiceProvider.speak(text);
      }
    } catch (e) {
      _showSnackBar('Failed to speak message: $e', isError: true);
    }
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.2;
        final animationValue = Curves.easeInOut.transform(
          ((_animationController.value - delay) % 1.0).clamp(0.0, 1.0),
        );
        
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.4 + (animationValue * 0.6)),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Enhanced send message with voice response
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      _showSnackBar('Please login to use the AI assistant', isError: true);
      return;
    }

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Query the agent
      final response = await AgentApiService.queryAgent(
        userId: authProvider.currentUser!.uid,
        queryText: message,
      );

      // Add agent response
      setState(() {
        _messages.add(ChatMessage(
          text: response.responseText,
          isUser: false,
          timestamp: DateTime.now(),
          agentName: response.agentName,
          confidence: response.confidence,
        ));
        _isLoading = false;
      });

      // Auto-speak response if enabled
      final voiceProvider = Provider.of<VoiceAssistantProvider>(context, listen: false);
      if (voiceProvider.autoSpeak && voiceProvider.isInitialized) {
        await _speakMessage(response.responseText, voiceProvider);
      }

      // Provide haptic feedback for successful response
      HapticFeedback.lightImpact();
    } catch (e) {
      // Add error message
      setState(() {
        _messages.add(ChatMessage(
          text: "I apologize, but I'm having trouble processing your request.\n\nError: ${e.toString()}\n\nPlease check if the agent system is running and try again.",
          isUser: false,
          timestamp: DateTime.now(),
          agentName: "System",
          confidence: 0.0,
        ));
        _isLoading = false;
      });

      _showSnackBar('Failed to get response: ${e.toString()}', isError: true);
    }

    _scrollToBottom();
  }
}
