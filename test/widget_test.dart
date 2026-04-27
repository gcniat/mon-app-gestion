import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mon_app_gestion/main.dart';

void main() {
  testWidgets("L'application se lance et affiche une MaterialApp",
      (WidgetTester tester) async {
    await tester.pumpWidget(const FuelTrackerApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
