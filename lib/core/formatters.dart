import 'package:intl/intl.dart';
import 'services/preferences_service.dart';

class AppFormatters {
  static final _numberFmt = NumberFormat('#,##0.00', 'en_US');
  static final _dateDisplay = DateFormat('dd/MM/yyyy');
  static final _dateStorage = DateFormat('yyyy-MM-dd');

  static String currency(double amount) {
    final sym = PreferencesService().currency.symbol;
    return '$sym ${_numberFmt.format(amount)}';
  }

  static String dateToDisplay(String stored) {
    final dt = DateTime.parse(stored);
    return _dateDisplay.format(dt);
  }

  static String dateToStorage(DateTime dt) => _dateStorage.format(dt);

  static DateTime storageToDate(String stored) => DateTime.parse(stored);
}
