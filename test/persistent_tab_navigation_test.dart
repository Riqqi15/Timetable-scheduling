import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timetable/core/routing/router.dart';
import 'package:timetable/features/profile/presentation/pages/profile_page.dart';
import 'package:timetable/features/timetable/presentation/pages/timetable_page.dart';
import 'package:timetable/main.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('main tabs preserve the timetable page state', (tester) async {
    appRouter.go('/timetable');
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final timetableState = tester.state(find.byType(TimetablePage));

    appRouter.go('/akun');
    await tester.pump();
    await tester.pump();
    expect(find.byType(ProfilePage), findsOneWidget);

    appRouter.go('/timetable');
    await tester.pump();
    await tester.pump();

    expect(tester.state(find.byType(TimetablePage)), same(timetableState));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
