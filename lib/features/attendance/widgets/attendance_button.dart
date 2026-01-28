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
  late AnimationController _cancelPulseController;

  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _cancelPulseAnimation;

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

    // Cancel pulse animation (scale down then up)
    _cancelPulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cancelPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.05), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _cancelPulseController,
      curve: Curves.easeOut,
    ));

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
    _cancelPulseController.dispose();
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
      _triggerCancelPulse();
      _hapticFail();
      return;
    }

    _lastHapticProgress = 0;
    _hapticStart();
    _scaleController.forward();
    _progressController.forward(from: 0);
  }

  void _onPressEnd() {
    if (!widget.isEnabled) return;

    _scaleController.reverse();

    if (_progressController.isAnimating) {
      // Released too early - pulse and fail haptic
      _progressController.stop();
      _progressController.reset();
      _triggerCancelPulse();
      _hapticFail();
    }
  }

  void _onComplete() {
    _hapticSuccess();
    _scaleController.reverse();
    _progressController.reset();
    widget.onComplete?.call();
  }

  // ============ HAPTIC PATTERNS ============

  /// Start haptic: Medium tap to indicate hold started
  void _hapticStart() {
    HapticFeedback.mediumImpact();
  }

  /// Fail haptic: Double quick vibration (longer delay)
  void _hapticFail() {
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.vibrate();
    });
  }

  /// Success haptic: Triple vibration celebration
  void _hapticSuccess() {
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 150), () {
        HapticFeedback.vibrate();
      });
    });
  }

  void _triggerCancelPulse() {
    _cancelPulseController.forward(from: 0);
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
    const double size = 160; // Scaled down from 200

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _cancelPulseAnimation]),
      builder: (context, child) {
        // Apply both scale animations
        final combinedScale =
            _scaleAnimation.value * _cancelPulseAnimation.value;

        return Transform.scale(
          scale: combinedScale,
          child: child,
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
                  size: 44,
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
