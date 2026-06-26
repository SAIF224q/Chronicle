import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronicle_app/src/ui/widgets/dashed_border_painter.dart';
import 'package:chronicle_app/src/ui/widgets/confetti_wrapper.dart';

void main() {
  testWidgets('DashedBorderPainter renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            painter: DashedBorderPainter(
              color: Colors.purple,
              strokeWidth: 2.0,
              dashPattern: const [4, 4],
              radius: 12.0,
            ),
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is DashedBorderPainter,
      ),
      findsOneWidget,
    );
  });

  testWidgets('ConfettiWrapper renders child and plays animation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConfettiWrapper(
            child: Text('Unlocked Card'),
          ),
        ),
      ),
    );

    expect(find.text('Unlocked Card'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter.runtimeType.toString() == '_ConfettiPainter',
      ),
      findsOneWidget,
    );

    // Pump to verify it doesn't crash on tick
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 2000));
  });
}
