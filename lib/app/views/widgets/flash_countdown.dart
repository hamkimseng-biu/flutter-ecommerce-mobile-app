import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/time_service.dart';

class FlashCountdown extends StatefulWidget {
  final DateTime endTime;
  final Color? textColor;
  final Color? boxColor;

  const FlashCountdown({
    super.key,
    required this.endTime,
    this.textColor,
    this.boxColor,
  });

  @override
  State<FlashCountdown> createState() => _FlashCountdownState();
}

class _FlashCountdownState extends State<FlashCountdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.endTime.difference(TimeService().serverNow());
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final diff = widget.endTime.difference(TimeService().serverNow());
    if (diff.isNegative) {
      _timer?.cancel();
      if (mounted) setState(() => _remaining = Duration.zero);
      return;
    }
    if (mounted) setState(() => _remaining = diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxColor =
        widget.boxColor ?? (isDark ? Colors.white24 : Colors.black87);
    final textColor =
        widget.textColor ?? (isDark ? Colors.white : Colors.white);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _box('${_pad(h)}', boxColor, textColor),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            ':',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        _box('${_pad(m)}', boxColor, textColor),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            ':',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        _box('${_pad(s)}', boxColor, textColor),
      ],
    );
  }

  Widget _box(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );
}
