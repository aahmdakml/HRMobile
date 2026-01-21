import 'dart:async';
import 'package:flutter/material.dart';

/// A live clock widget with blinking colon animation
class LiveClock extends StatefulWidget {
  final DateTime? serverTime;

  const LiveClock({super.key, this.serverTime});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  Duration _timeOffset = Duration.zero;
  bool _colonVisible = true;

  @override
  void initState() {
    super.initState();
    _updateOffset();

    // Update every 500ms to handle colon blinking
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _now = DateTime.now().add(_timeOffset);
        _colonVisible = !_colonVisible;
      });
    });
  }

  @override
  void didUpdateWidget(LiveClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.serverTime != oldWidget.serverTime) {
      _updateOffset();
    }
  }

  void _updateOffset() {
    if (widget.serverTime != null) {
      // Calculate difference between server time and current local time
      _timeOffset = widget.serverTime!.difference(DateTime.now());
      // Immediately update _now
      _now = DateTime.now().add(_timeOffset);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatHour(int hour) {
    return hour.toString().padLeft(2, '0');
  }

  String _formatMinute(int minute) {
    return minute.toString().padLeft(2, '0');
  }

  String _formatSecond(int second) {
    return second.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live Clock - Large font with blinking colon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Hours
            Text(
              _formatHour(_now.hour),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 80,
                fontWeight: FontWeight.w300,
                letterSpacing: -2,
                color: theme.textTheme.headlineLarge?.color?.withOpacity(0.8),
              ),
            ),
            // Blinking colon
            AnimatedOpacity(
              opacity: _colonVisible ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 200),
              child: Text(
                ':',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 80,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            // Minutes
            Text(
              _formatMinute(_now.minute),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 80,
                fontWeight: FontWeight.w300,
                letterSpacing: -2,
                color: theme.textTheme.headlineLarge?.color?.withOpacity(0.8),
              ),
            ),
            // Seconds (smaller)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _formatSecond(_now.second),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Date subtitle
        Text(
          _formatDate(_now),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final dayName = days[date.weekday % 7];
    final monthName = months[date.month - 1];

    return '$dayName, $monthName ${date.day}, ${date.year}';
  }
}
