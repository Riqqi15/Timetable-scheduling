import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppNoticeType { success, info, warning, error }

enum AppNoticePlacement { top, bottom }

abstract final class AppNotice {
  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    required String message,
    AppNoticeType type = AppNoticeType.info,
    AppNoticePlacement placement = AppNoticePlacement.bottom,
    Duration? duration,
  }) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final resolvedDuration = duration ?? _durationFor(type);
    _removeActiveEntry();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _AppNoticeOverlay(
        message: trimmedMessage,
        type: type,
        placement: placement,
        duration: resolvedDuration,
        onDismiss: () => _removeEntry(entry),
        onDisposed: () => _forgetEntry(entry),
      ),
    );
    _activeEntry = entry;
    overlay.insert(entry);
  }

  static void _removeActiveEntry() {
    final entry = _activeEntry;
    if (entry == null) return;
    _activeEntry = null;
    if (entry.mounted) entry.remove();
    entry.dispose();
  }

  static void _removeEntry(OverlayEntry entry) {
    if (!identical(_activeEntry, entry)) return;
    _activeEntry = null;
    if (entry.mounted) entry.remove();
    entry.dispose();
  }

  static void _forgetEntry(OverlayEntry entry) {
    if (identical(_activeEntry, entry)) _activeEntry = null;
  }

  static Duration _durationFor(AppNoticeType type) => switch (type) {
    AppNoticeType.success => const Duration(seconds: 3),
    AppNoticeType.info => const Duration(seconds: 4),
    AppNoticeType.warning => const Duration(seconds: 5),
    AppNoticeType.error => const Duration(seconds: 6),
  };
}

class _AppNoticeOverlay extends StatefulWidget {
  const _AppNoticeOverlay({
    required this.message,
    required this.type,
    required this.placement,
    required this.duration,
    required this.onDismiss,
    required this.onDisposed,
  });

  final String message;
  final AppNoticeType type;
  final AppNoticePlacement placement;
  final Duration duration;
  final VoidCallback onDismiss;
  final VoidCallback onDisposed;

  @override
  State<_AppNoticeOverlay> createState() => _AppNoticeOverlayState();
}

class _AppNoticeOverlayState extends State<_AppNoticeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 160),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _opacity = animation;
    _offset = Tween<Offset>(
      begin: widget.placement == AppNoticePlacement.top
          ? const Offset(0, -0.25)
          : const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(animation);
    _controller.forward();
    _timer = Timer(widget.duration, () => unawaited(_dismiss()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    widget.onDisposed();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _timer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final towardEdge = widget.placement == AppNoticePlacement.top
        ? velocity < -250
        : velocity > 250;
    if (towardEdge) unawaited(_dismiss());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final scaleProgress = (textScale - 1).clamp(0.0, 1.0).toDouble();
    final navHeight = 72.0 + (28.0 * scaleProgress);

    return Positioned(
      left: 16,
      right: 16,
      top: widget.placement == AppNoticePlacement.top
          ? MediaQuery.paddingOf(context).top + 12
          : null,
      bottom: widget.placement == AppNoticePlacement.bottom
          ? bottomInset + navHeight + 12
          : null,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(_dismiss()),
            onVerticalDragEnd: _handleVerticalDragEnd,
            child: _AppNoticeCard(message: widget.message, type: widget.type),
          ),
        ),
      ),
    );
  }
}

class _AppNoticeCard extends StatelessWidget {
  const _AppNoticeCard({required this.message, required this.type});

  final String message;
  final AppNoticeType type;

  @override
  Widget build(BuildContext context) {
    final palette = _NoticePalette.forType(type);
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        key: Key('app_notice_${type.name}'),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A202030),
              offset: Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(palette.icon, color: palette.foreground, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.foreground,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticePalette {
  const _NoticePalette({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;

  static _NoticePalette forType(AppNoticeType type) => switch (type) {
    AppNoticeType.success => const _NoticePalette(
      background: Color(0xFFEAF7EF),
      foreground: Color(0xFF126B35),
      icon: Icons.check_circle_rounded,
    ),
    AppNoticeType.info => const _NoticePalette(
      background: AppColors.primaryBlueLight,
      foreground: AppColors.deepPurple,
      icon: Icons.info_rounded,
    ),
    AppNoticeType.warning => const _NoticePalette(
      background: Color(0xFFFFF5DD),
      foreground: Color(0xFF7A4A00),
      icon: Icons.warning_amber_rounded,
    ),
    AppNoticeType.error => const _NoticePalette(
      background: Color(0xFFFFECEC),
      foreground: Color(0xFFA52222),
      icon: Icons.error_rounded,
    ),
  };
}
