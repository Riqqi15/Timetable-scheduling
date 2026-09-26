import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable/core/theme/app_theme.dart';
import 'package:timetable/shared/widgets/app_notice.dart';

void main() {
  testWidgets('top notice floats without moving page content', (tester) async {
    await tester.pumpWidget(const _NoticeHarness());
    final body = find.byKey(const Key('notice-harness-body'));
    final bodyTop = tester.getTopLeft(body);

    await tester.tap(find.text('Show success'));
    await _pumpNotice(tester);

    expect(find.byType(MaterialBanner), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byKey(const Key('app_notice_success')), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(tester.getTopLeft(body), bodyTop);
  });

  testWidgets('bottom notice floats above mobile navigation space', (
    tester,
  ) async {
    await tester.pumpWidget(const _NoticeHarness());

    await tester.tap(find.text('Show error'));
    await _pumpNotice(tester);

    expect(find.byType(MaterialBanner), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    final notice = find.byKey(const Key('app_notice_error'));
    expect(notice, findsOneWidget);
    expect(tester.getBottomRight(notice).dy, lessThan(520));
  });

  testWidgets('new notice replaces the active notice', (tester) async {
    await tester.pumpWidget(const _NoticeHarness());

    await tester.tap(find.text('Show success'));
    await _pumpNotice(tester);
    await tester.tap(find.text('Show error'));
    await _pumpNotice(tester);

    expect(find.byKey(const Key('app_notice_success')), findsNothing);
    expect(find.byKey(const Key('app_notice_error')), findsOneWidget);
  });

  testWidgets('notice dismisses when tapped and when its duration expires', (
    tester,
  ) async {
    await tester.pumpWidget(const _NoticeHarness());

    await tester.tap(find.text('Show success'));
    await _pumpNotice(tester);
    await tester.tap(find.byKey(const Key('app_notice_success')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('app_notice_success')), findsNothing);

    await tester.tap(find.text('Show success'));
    await _pumpNotice(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('app_notice_success')), findsNothing);
  });

  testWidgets('notice is a live region for assistive technology', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const _NoticeHarness());

    await tester.tap(find.text('Show success'));
    await _pumpNotice(tester);

    final data = tester
        .getSemantics(find.bySemanticsLabel('Perubahan berhasil disimpan.'))
        .getSemanticsData();
    expect(data.flagsCollection.isLiveRegion, isTrue);
    semantics.dispose();
  });

  testWidgets('long multilingual notice survives large text and RTL', (
    tester,
  ) async {
    await tester.pumpWidget(const _NoticeHarness(textScale: 2));

    await tester.tap(find.text('Show multilingual'));
    await _pumpNotice(tester);

    expect(find.byKey(const Key('app_notice_info')), findsOneWidget);
    expect(find.textContaining('请注意'), findsOneWidget);
    expect(find.textContaining('يرجى'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpNotice(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

class _NoticeHarness extends StatelessWidget {
  const _NoticeHarness({this.textScale = 1});

  final double textScale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => ColoredBox(
            key: const Key('notice-harness-body'),
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: () => AppNotice.show(
                      context,
                      message: 'Perubahan berhasil disimpan.',
                      type: AppNoticeType.success,
                      placement: AppNoticePlacement.top,
                    ),
                    child: const Text('Show success'),
                  ),
                  FilledButton(
                    onPressed: () => AppNotice.show(
                      context,
                      message: 'Koneksi gagal. Coba lagi.',
                      type: AppNoticeType.error,
                    ),
                    child: const Text('Show error'),
                  ),
                  FilledButton(
                    onPressed: () => AppNotice.show(
                      context,
                      message:
                          '请注意，这是一条很长的通知。 يرجى المحاولة مرة أخرى. Informasi ini tetap harus terbaca tanpa terpotong.',
                      type: AppNoticeType.info,
                    ),
                    child: const Text('Show multilingual'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
