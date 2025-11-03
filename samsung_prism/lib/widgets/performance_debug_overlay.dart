import 'package:flutter/material.dart';

/// Performance monitoring overlay for debugging (UI removed)
class PerformanceDebugOverlay extends StatefulWidget {
  final Widget child;
  
  const PerformanceDebugOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<PerformanceDebugOverlay> createState() => _PerformanceDebugOverlayState();
}

class _PerformanceDebugOverlayState extends State<PerformanceDebugOverlay> {

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: widget.child,
    );
  }
}
