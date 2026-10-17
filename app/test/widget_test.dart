import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warmpath_app/main.dart';

void main() {
  testWidgets('WarmPathApp renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WarmPathApp()));
    expect(find.byType(WarmPathApp), findsOneWidget);
  });
}
