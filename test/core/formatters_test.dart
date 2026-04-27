import 'package:flutter_test/flutter_test.dart';
import 'package:mon_app_gestion/core/formatters.dart';

void main() {
  group('AppFormatters.currency', () {
    test('formate avec le symbole \$ et 2 décimales', () {
      expect(AppFormatters.currency(12.5), '\$12.50');
      expect(AppFormatters.currency(0), '\$0.00');
      expect(AppFormatters.currency(99.99), '\$99.99');
    });

    test('formate les grands montants avec séparateur de milliers', () {
      expect(AppFormatters.currency(1234.56), '\$1,234.56');
      expect(AppFormatters.currency(10000), '\$10,000.00');
    });

    test('arrondit correctement à 2 décimales', () {
      expect(AppFormatters.currency(1.006), '\$1.01');
      expect(AppFormatters.currency(1.004), '\$1.00');
    });
  });

  group('AppFormatters.dateToStorage', () {
    test('formate en YYYY-MM-DD', () {
      expect(
          AppFormatters.dateToStorage(DateTime(2024, 3, 5)), '2024-03-05');
      expect(
          AppFormatters.dateToStorage(DateTime(2024, 12, 31)), '2024-12-31');
    });
  });

  group('AppFormatters.dateToDisplay', () {
    test('formate en DD/MM/YYYY', () {
      expect(AppFormatters.dateToDisplay('2024-03-05'), '05/03/2024');
      expect(AppFormatters.dateToDisplay('2024-12-31'), '31/12/2024');
    });
  });

  group('AppFormatters.storageToDate', () {
    test('parse correctement YYYY-MM-DD', () {
      final dt = AppFormatters.storageToDate('2024-03-15');
      expect(dt.year, 2024);
      expect(dt.month, 3);
      expect(dt.day, 15);
    });
  });

  group('Aller-retour date', () {
    test('storage → display → parse reste cohérent', () {
      final original = DateTime(2024, 7, 4);
      final stored = AppFormatters.dateToStorage(original);
      final parsed = AppFormatters.storageToDate(stored);
      expect(parsed.year, original.year);
      expect(parsed.month, original.month);
      expect(parsed.day, original.day);
    });
  });
}
