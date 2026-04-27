import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_currency.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._();
  factory PreferencesService() => _instance;
  PreferencesService._();

  static const _currencyKey = 'pref_currency_code';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  AppCurrency get currency {
    final code = _prefs.getString(_currencyKey) ?? 'USD';
    return AppCurrency.fromCode(code);
  }

  Future<void> setCurrency(AppCurrency c) async {
    await _prefs.setString(_currencyKey, c.code);
  }
}
