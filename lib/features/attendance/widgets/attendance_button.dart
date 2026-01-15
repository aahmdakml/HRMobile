import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_state.dart';

/// A large circular button for attendance action with hold-to-confirm interaction
/// Features:
/// - Radial progress animation on long press
/// - Scale down effect during press
/// - Shake animation on early release
/// - Haptic feedback choreography
class AttendanceButton extends StatefulWidget {
  final AttendanceAction action;
  final bool isEnabled;
  final VoidCallback? onComplete;
  final Duration holdDuration;

  const AttendanceButton({
    super.key,
    required this.action,
    this.isEnabled = true,
    this.onComplete,
    this.holdDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<AttendanceButton> createState() => _AttendanceButtonState();
}

class _AttendanceButtonState extends State<AttendanceButton>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _scaleController;
  late AnimationController _shakeController;

  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

  Timer? _hapticTimer;
  double _lastHapticProgress = 0;

  @override
  void initState() {
    super.initState();

    // Progress animation (0 to 1)
    _progressController = AnimationController(
      duration: widget.holdDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    // Scale animation (1 to 0.95)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    // Shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    // Listen for completion
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onComplete();
      }
    });

    // Listen for progress to trigger haptic feedback
    _progressAnimation.addListener(_onProgressUpdate);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _scaleController.dispose();
    _shakeController.dispose();
    _hapticTimer?.cancel();
    super.dispose();
  }

  void _onProgressUpdate() {
    // Trigger haptic every 20% progress
    final progress = _progressAnimation.value;
    final milestone = (progress * 5).floor() / 5; // 0, 0.2, 0.4, 0.6, 0.8

    if (milestone > _lastHapticProgress) {
      _lastHapticProgress = milestone;
      HapticFeedback.selectionClick();
    }
  }

  void _onPressStart() {
    if (!widget.isEnabled) {
      _triggerShake();
      HapticFeedback.vibrate();
      return;
    }

    _lastHapticProgress = 0;
    HapticFeedback.lightImpact();
    _scaleController.forward();
    _progressController.forward(from: 0);
  }

  void _onPressEnd() {
    if (!widget.isEnabled) return;

    _scaleController.reverse();

    if (_progressController.isAnimating) {
      // Released too early - shake and vibrate
      _progressController.stop();
      _progressController.reset();
      _triggerShake();
      HapticFeedback.vibrate();
    }
  }

  void _onComplete() {
    HapticFeedback.heavyImpact();
    _scaleController.reverse();
    _progressController.reset();
    widget.onComplete?.call();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  Color get _buttonColor {
    if (!widget.isEnabled) return AppColors.disabled;

    switch (widget.action) {
      case AttendanceAction.checkIn:
        return AppColors.checkIn;
      case AttendanceAction.breakOut:
        return AppColors.breakOut;
      case AttendanceAction.resume:
        return AppColors.resume;
      case AttendanceAction.checkOut:
        return AppColors.checkOut;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double size = 150;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _shakeAnimation]),
      builder: (context, child) {
        // Calculate shake offset
        final shakeOffset = _shakeAnimation.value *
            10 *
            ((_shakeController.value * 10).floor() % 2 == 0 ? 1 : -1);

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _onPressStart(),
        onTapUp: (_) => _onPressEnd(),
        onTapCancel: _onPressEnd,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _buttonColor.withOpacity(0.15),
                ),
              ),

              // Progress arc
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _ProgressArcPainter(
                      progress: _progressAnimation.value,
                      color: _buttonColor,
                      strokeWidth: 4,
                    ),
                  );
                },
              ),

              // Inner circle with icon
              Container(
                width: size - 20,
                height: size - 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _buttonColor,
                  boxShadow: [
                    BoxShadow(
                      color: _buttonColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the progress arc
class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw progress arc starting from top (-90 degrees)
    const startAngle = -3.14159 / 2; // -90 degrees in radians
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
