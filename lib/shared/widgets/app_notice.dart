import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppNoticeType { success, info, warning, error }

enum AppNoticePlacement { top, bottom }

abstract final class AppNotice {
  static void show(
    BuildContext context, {
    required String message,
    AppNoticeType type = AppNoticeType.info,
    AppNoticePlacement placement = AppNoticePlacement.bottom,
    Duration? duration,
  }) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..removeCurrentMaterialBanner()
      ..removeCurrentSnackBar();

    final resolvedDuration = duration ?? _durationFor(type);
    if (placement == AppNoticePlacement.top) {
      messenger.showMaterialBanner(
        MaterialBanner(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          content: _AutoDismissNoticeCard(
            message: trimmedMessage,
            type: type,
            duration: resolvedDuration,
            onDismiss: messenger.hideCurrentMaterialBanner,
          ),
          actions: const [SizedBox.shrink()],
        ),
      );
      return;
    }

    final bottomInset = MediaQuery.maybeViewPaddingOf(context)?.bottom ?? 0;
    messenger.showSnackBar(
      SnackBar(
        content: _AppNoticeCard(message: trimmedMessage, type: type),
        duration: resolvedDuration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 12),
      ),
    );
  }

  static Duration _durationFor(AppNoticeType type) => switch (type) {
    AppNoticeType.success => const Duration(seconds: 3),
    AppNoticeType.info => const Duration(seconds: 4),
    AppNoticeType.warning => const Duration(seconds: 5),
    AppNoticeType.error => const Duration(seconds: 6),
  };
}

class _AutoDismissNoticeCard extends StatefulWidget {
  const _AutoDismissNoticeCard({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final AppNoticeType type;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_AutoDismissNoticeCard> createState() =>
      _AutoDismissNoticeCardState();
}

class _AutoDismissNoticeCardState extends State<_AutoDismissNoticeCard> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onDismiss);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AppNoticeCard(message: widget.message, type: widget.type);
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
