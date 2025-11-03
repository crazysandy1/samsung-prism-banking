import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/keystroke_models.dart';

/// Widget that captures keystroke timing data from user input
/// 
/// This widget records the exact timing of key press and release events
/// to create a unique typing pattern for each user.
class KeystrokeRecorder extends StatefulWidget {
  final Function(KeystrokeSession) onSessionComplete;
  final Function(KeystrokeEvent)? onKeystrokeEvent;
  final String? hintText;
  final String? expectedText;
  final int? maxLength;
  final bool enabled;
  final bool obscureText;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;

  const KeystrokeRecorder({
    Key? key,
    required this.onSessionComplete,
    this.onKeystrokeEvent,
    this.hintText,
    this.expectedText,
    this.maxLength,
    this.enabled = true,
    this.obscureText = false,
    this.onStartRecording,
    this.onStopRecording,
  }) : super(key: key);

  @override
  State<KeystrokeRecorder> createState() => _KeystrokeRecorderState();
}

class _KeystrokeRecorderState extends State<KeystrokeRecorder> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<KeystrokeEvent> _events = [];
  final Map<String, int> _keyDownTimes = {};
  DateTime? _sessionStartTime;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(KeystrokeRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear the text field when the widget key changes (new recording session)
    if (widget.key != oldWidget.key) {
      _controller.clear();
      _clearSession();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSession() {
    setState(() {
      _isRecording = false;
      _sessionStartTime = null;
      _events.clear();
      _keyDownTimes.clear();
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isRecording) {
      _startRecording();
    } else if (!_focusNode.hasFocus && _isRecording) {
      _stopRecording();
    }
  }

  void _onTextChanged() {
    // This is called when text changes, but we rely on RawKeyboardListener
    // for actual keystroke timing
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _sessionStartTime = DateTime.now();
      _events.clear();
      _keyDownTimes.clear();
    });
    widget.onStartRecording?.call();
  }

  void _stopRecording() {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
    });

    widget.onStopRecording?.call();

    if (_events.isNotEmpty && _sessionStartTime != null) {
      // Capture the text before clearing
      final capturedText = _controller.text;
      
      final session = KeystrokeSession(
        userId: '', // Will be set by the caller
        events: List.from(_events),
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
        capturedText: capturedText, // Store the captured text
      );
      
      // Clear the text field after completing session
      _controller.clear();
      
      widget.onSessionComplete(session);
    }
  }

  void _recordKeystroke(String key, String eventType) {
    if (!_isRecording) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final event = KeystrokeEvent(
      key: key,
      event: eventType,
      timestamp: timestamp,
    );

    setState(() {
      _events.add(event);
    });

    widget.onKeystrokeEvent?.call(event);

    // Track key down times for calculating hold duration
    if (eventType == 'down') {
      _keyDownTimes[key] = timestamp;
    } else if (eventType == 'up') {
      _keyDownTimes.remove(key);
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_isRecording || !widget.enabled) return false;

    String? keyLabel = _getKeyLabel(event.logicalKey);
    if (keyLabel == null) return false;

    if (event is KeyDownEvent) {
      _recordKeystroke(keyLabel, 'down');
    } else if (event is KeyUpEvent) {
      _recordKeystroke(keyLabel, 'up');
    }

    return false; // Allow normal text input processing
  }

  String? _getKeyLabel(LogicalKeyboardKey key) {
    // Handle special keys
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.backspace) return 'Backspace';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.shiftLeft) return 'Shift_L';
    if (key == LogicalKeyboardKey.shiftRight) return 'Shift_R';
    if (key == LogicalKeyboardKey.controlLeft) return 'Ctrl_L';
    if (key == LogicalKeyboardKey.controlRight) return 'Ctrl_R';
    if (key == LogicalKeyboardKey.altLeft) return 'Alt_L';
    if (key == LogicalKeyboardKey.altRight) return 'Alt_R';
    if (key == LogicalKeyboardKey.delete) return 'Delete';
    if (key == LogicalKeyboardKey.escape) return 'Escape';

    // Handle number keys
    if (key == LogicalKeyboardKey.digit0) return '0';
    if (key == LogicalKeyboardKey.digit1) return '1';
    if (key == LogicalKeyboardKey.digit2) return '2';
    if (key == LogicalKeyboardKey.digit3) return '3';
    if (key == LogicalKeyboardKey.digit4) return '4';
    if (key == LogicalKeyboardKey.digit5) return '5';
    if (key == LogicalKeyboardKey.digit6) return '6';
    if (key == LogicalKeyboardKey.digit7) return '7';
    if (key == LogicalKeyboardKey.digit8) return '8';
    if (key == LogicalKeyboardKey.digit9) return '9';

    // Handle letter keys
    final keyLabel = key.keyLabel.toLowerCase();
    if (keyLabel.length == 1 && RegExp(r'[a-z]').hasMatch(keyLabel)) {
      return keyLabel;
    }

    // Handle punctuation and symbols
    final punctuation = {
      LogicalKeyboardKey.period: '.',
      LogicalKeyboardKey.comma: ',',
      LogicalKeyboardKey.semicolon: ';',
      LogicalKeyboardKey.quote: "'",
      LogicalKeyboardKey.bracketLeft: '[',
      LogicalKeyboardKey.bracketRight: ']',
      LogicalKeyboardKey.backslash: '\\',
      LogicalKeyboardKey.slash: '/',
      LogicalKeyboardKey.minus: '-',
      LogicalKeyboardKey.equal: '=',
      LogicalKeyboardKey.backquote: '`',
    };

    return punctuation[key];
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        return _handleKeyEvent(event) 
            ? KeyEventResult.handled 
            : KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            obscureText: widget.obscureText,
            maxLength: widget.maxLength,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              suffixIcon: _isRecording
                  ? const Icon(
                      Icons.fiber_manual_record,
                      color: Colors.red,
                      size: 16,
                    )
                  : null,
            ),
            onSubmitted: (_) => _stopRecording(),
          ),
          if (widget.expectedText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Type: "${widget.expectedText}"',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.circle,
                    color: Colors.red,
                    size: 8,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Recording keystrokes... (${_events.length} events)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Simplified keystroke recorder for password-like inputs
class PasswordKeystrokeRecorder extends StatelessWidget {
  final Function(KeystrokeSession) onSessionComplete;
  final String? hintText;
  final bool enabled;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;

  const PasswordKeystrokeRecorder({
    Key? key,
    required this.onSessionComplete,
    this.hintText = 'Enter your password',
    this.enabled = true,
    this.onStartRecording,
    this.onStopRecording,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeystrokeRecorder(
      onSessionComplete: onSessionComplete,
      hintText: hintText,
      enabled: enabled,
      obscureText: true,
      onStartRecording: onStartRecording,
      onStopRecording: onStopRecording,
    );
  }
}

/// Keystroke recorder with predefined text for training
class TrainingKeystrokeRecorder extends StatelessWidget {
  final Function(KeystrokeSession) onSessionComplete;
  final String trainingText;
  final bool enabled;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;

  const TrainingKeystrokeRecorder({
    Key? key,
    required this.onSessionComplete,
    required this.trainingText,
    this.enabled = true,
    this.onStartRecording,
    this.onStopRecording,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeystrokeRecorder(
      onSessionComplete: onSessionComplete,
      hintText: 'Type the text below exactly',
      expectedText: trainingText,
      enabled: enabled,
      onStartRecording: onStartRecording,
      onStopRecording: onStopRecording,
    );
  }
}
