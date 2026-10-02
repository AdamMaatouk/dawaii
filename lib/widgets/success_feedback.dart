import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A short vibration plus a big check mark that pops up and fades, so the
/// user knows the dose was saved.
Future<void> showSuccessFeedback(BuildContext context) async {
  HapticFeedback.mediumImpact();
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  final entry = OverlayEntry(builder: (_) => const _SuccessCheck());
  overlay.insert(entry);
  await Future<void>.delayed(_SuccessCheck.duration);
  entry.remove();
}

class _SuccessCheck extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 900);

  const _SuccessCheck();

  @override
  State<_SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<_SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _SuccessCheck.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: Curves.elasticOut),
    );
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1, curve: Curves.easeOut),
    );

    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: 1 - fade.value,
            child: Transform.scale(
              scale: 0.4 + 0.6 * scale.value,
              child: child,
            ),
          ),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: palette.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: palette.success.withValues(alpha: 0.4),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 96,
            ),
          ),
        ),
      ),
    );
  }
}
