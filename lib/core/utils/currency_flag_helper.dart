class CurrencyFlagHelper {
  static const Map<String, String> _regionOverrides = {
    'EUR': 'EU',
    'GBP': 'GB',
  };

  static String fromCurrencyCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.length < 3) return '🏳️';

    final region = _regionOverrides[normalized] ?? normalized.substring(0, 2);
    if (!_isAlpha2(region)) return '🏳️';

    return _regionToFlag(region);
  }

  static bool _isAlpha2(String value) {
    return RegExp(r'^[A-Z]{2}$').hasMatch(value);
  }

  static String _regionToFlag(String regionCode) {
    const base = 0x1F1E6;
    const asciiA = 0x41;

    final chars = regionCode.codeUnits
        .map((unit) => String.fromCharCode(base + unit - asciiA))
        .join();

    return chars.isEmpty ? '🏳️' : chars;
  }
}
