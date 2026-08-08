import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_investment_control/core/app_widget.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our financial app and advance past splash screen timer
    await tester.pumpWidget(const AppWidget());
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AppWidget), findsOneWidget);
  });
}
