import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class BaseCurrencyService {
  static Future<void> saveBaseCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.selectedBaseKey, code);
  }

  static Future<String> getBaseCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.selectedBaseKey) ?? 'SDG';
  }
}