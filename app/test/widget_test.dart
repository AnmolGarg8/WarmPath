import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warmpath_app/main.dart';

void main() {
  testWidgets('WarmPathApp renders Discover recommendations view initially', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WarmPathApp()));
    await tester.pumpAndSettle();

    expect(find.text('WarmPath Recommendations'), findsOneWidget);
  });
}
