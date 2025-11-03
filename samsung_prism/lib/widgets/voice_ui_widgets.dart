import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';

class VoiceWaveWidget extends StatefulWidget {
  final bool isListening;
  final double soundLevel;
  final VoidCallback onTap;
  final Color primaryColor;
  final double size;

  const VoiceWaveWidget({
    Key? key,
    required this.isListening,
    required this.soundLevel,
    required this.onTap,
    this.primaryColor = const Color(0xFF1976D2),
    this.size = 60.0,
  }) : super(key: key);

  @override
  State<VoiceWaveWidget> createState() => _VoiceWaveWidgetState();
}

class _VoiceWaveWidgetState extends State<VoiceWaveWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));
  }

  @override
  void didUpdateWidget(VoiceWaveWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
      } else {
        _pulseController.stop();
        _waveController.stop();
        _pulseController.reset();
        _waveController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isListening ? _pulseAnimation.value : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.isListening
                      ? [widget.primaryColor, widget.primaryColor.withOpacity(0.7)]
                      : [Colors.grey[400]!, Colors.grey[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: widget.isListening
                    ? [
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated waves when listening
                  if (widget.isListening)
                    AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: VoiceWavePainter(
                            waveProgress: _waveAnimation.value,
                            soundLevel: widget.soundLevel,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  
                  // Microphone icon
                  Icon(
                    widget.isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: widget.size * 0.4,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class VoiceWavePainter extends CustomPainter {
  final double waveProgress;
  final double soundLevel;
  final Color color;

  VoiceWavePainter({
    required this.waveProgress,
    required this.soundLevel,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw animated waves based on sound level
    for (int i = 0; i < 3; i++) {
      final waveRadius = radius * (0.6 + (i * 0.15)) * (1 + soundLevel);
      final opacity = (1.0 - (waveProgress + i * 0.3) % 1.0) * 0.7;
      
      paint.color = color.withOpacity(opacity);
      
      canvas.drawCircle(center, waveRadius, paint);
    }
  }

  @override
  bool shouldRepaint(VoiceWavePainter oldDelegate) {
    return oldDelegate.waveProgress != waveProgress ||
           oldDelegate.soundLevel != soundLevel;
  }
}

class VoiceRecordingIndicator extends StatefulWidget {
  final bool isRecording;
  final String recognizedText;
  final VoidCallback? onCancel;

  const VoiceRecordingIndicator({
    Key? key,
    required this.isRecording,
    required this.recognizedText,
    this.onCancel,
  }) : super(key: key);

  @override
  State<VoiceRecordingIndicator> createState() => _VoiceRecordingIndicatorState();
}

class _VoiceRecordingIndicatorState extends State<VoiceRecordingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late Animation<double> _dotAnimation;

  @override
  void initState() {
    super.initState();
    
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _dotAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_dotController);

    if (widget.isRecording) {
      _dotController.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceRecordingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _dotController.repeat();
      } else {
        _dotController.stop();
        _dotController.reset();
      }
    }
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _dotAnimation,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(
                        0.5 + (_dotAnimation.value * 0.5),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Listening...',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (widget.onCancel != null)
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
            ],
          ),
          
          if (widget.recognizedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                widget.recognizedText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class VoiceSpeakingIndicator extends StatefulWidget {
  final bool isSpeaking;
  final String currentText;
  final VoidCallback? onStop;

  const VoiceSpeakingIndicator({
    Key? key,
    required this.isSpeaking,
    required this.currentText,
    this.onStop,
  }) : super(key: key);

  @override
  State<VoiceSpeakingIndicator> createState() => _VoiceSpeakingIndicatorState();
}

class _VoiceSpeakingIndicatorState extends State<VoiceSpeakingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create multiple bar animations for speaking effect
    _barControllers = List.generate(5, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      );
    });

    _barAnimations = _barControllers.map((controller) {
      return Tween<double>(
        begin: 0.2,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    if (widget.isSpeaking) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _waveController.repeat();
    for (var controller in _barControllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimations() {
    _waveController.stop();
    for (var controller in _barControllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void didUpdateWidget(VoiceSpeakingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      if (widget.isSpeaking) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    for (var controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpeaking) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Animated speaking bars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return AnimatedBuilder(
                    animation: _barAnimations[index],
                    builder: (context, child) {
                      return Container(
                        width: 3,
                        height: 16 * _barAnimations[index].value,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(width: 12),
              const Text(
                'Speaking...',
                style: TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (widget.onStop != null)
                IconButton(
                  onPressed: widget.onStop,
                  icon: const Icon(Icons.stop, color: Color(0xFF1976D2), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
            ],
          ),
          
          if (widget.currentText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                widget.currentText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class VoiceErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const VoiceErrorWidget({
    Key? key,
    required this.errorMessage,
    this.onRetry,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voice Error',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: const Text('Retry'),
            ),
          ],
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }
}