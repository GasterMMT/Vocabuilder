import 'package:flutter_test/flutter_test.dart';
import 'package:vocabuilder/app.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const VocabuilderApp());
    expect(find.text('Vocabuilder'), findsOneWidget);
  });
}
