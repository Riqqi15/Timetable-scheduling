import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable/core/theme/app_theme.dart';
import 'package:timetable/shared/widgets/app_notice.dart';

void main() {
  testWidgets('success notice uses a light top banner', (tester) async {
    await tester.pumpWidget(const _NoticeHarness());

    await tester.tap(find.text('Show success'));
    await tester.pump();

    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.byKey(const Key('app_notice_success')), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app_notice_success')), findsNothing);
  });

  testWidgets('error notice uses a floating bottom snackbar', (tester) async {
    await tester.pumpWidget(const _NoticeHarness());

    await tester.tap(find.text('Show error'));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(find.byKey(const Key('app_notice_error')), findsOneWidget);
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
  });

  testWidgets('long multilingual notice survives large text and RTL', (
    tester,
  ) async {
    await tester.pumpWidget(const _NoticeHarness(textScale: 2));

    await tester.tap(find.text('Show multilingual'));
    await tester.pump();

    expect(find.byKey(const Key('app_notice_info')), findsOneWidget);
    expect(find.textContaining('请注意'), findsOneWidget);
    expect(find.textContaining('يرجى'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
          builder: (context) => Column(
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
                ),
                child: const Text('Show multilingual'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
