import 'package:flutter_test/flutter_test.dart';

import 'package:event_pairs/main.dart';

void main() {
  testWidgets('moves from login to tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('登録する'), findsOneWidget);
    expect(find.text('Event Pairs'), findsNothing);

    await tester.tap(find.text('登録する'));
    await tester.pumpAndSettle();

    expect(find.text('Event Pairs'), findsOneWidget);
    expect(find.text('見つける'), findsOneWidget);
    expect(find.text('募集する'), findsOneWidget);
    expect(find.text('イベント検索'), findsOneWidget);

    await tester.tap(find.text('募集する'));
    await tester.pumpAndSettle();

    expect(find.text('どんな人と行きたい？'), findsOneWidget);
  });
}
