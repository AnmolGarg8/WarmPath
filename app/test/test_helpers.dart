import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared test helper that traverses all rendered Text and RichText widgets in the tree
/// and fails if any widget contains the literal unescaped template string pattern "${".
void expectNoUnescapedTemplates(WidgetTester tester) {
  // Check regular Text widgets
  final textWidgets = tester.widgetList<Text>(find.byType(Text));
  for (final text in textWidgets) {
    final textData = text.data ?? text.textSpan?.toPlainText() ?? '';
    expect(
      textData.contains(r'${'),
      isFalse,
      reason: 'Found unescaped template string in Text widget: "$textData"',
    );
  }

  // Check RichText widgets
  final richTextWidgets = tester.widgetList<RichText>(find.byType(RichText));
  for (final richText in richTextWidgets) {
    final plainText = richText.text.toPlainText();
    expect(
      plainText.contains(r'${'),
      isFalse,
      reason: 'Found unescaped template string in RichText widget: "$plainText"',
    );
  }
}
