import 'package:intl/intl.dart';

class AppFormatters {
  static final _currency = NumberFormat('\$#,##0.00', 'fr_CA');
  static final _dateDisplay = DateFormat('dd/MM/yyyy');
  static final _dateStorage = DateFormat('yyyy-MM-dd');

  static String currency(double amount) => _currency.format(amount);

  static String dateToDisplay(String stored) {
    final dt = DateTime.parse(stored);
    return _dateDisplay.format(dt);
  }

  static String dateToStorage(DateTime dt) => _dateStorage.format(dt);

  static DateTime storageToDate(String stored) => DateTime.parse(stored);
}
