import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'main_shell_page.dart';
import '../../core/localization/locale_service.dart';
import '../../core/services/base_currency_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_flag_helper.dart';
import '../../core/widgets/app_skeleton_block.dart';
import '../../data/models/market_models.dart';
import '../../data/services/market_service.dart';

class ExchangeCalculatorPage extends StatefulWidget {
  const ExchangeCalculatorPage({super.key});

  @override
  State<ExchangeCalculatorPage> createState() => _ExchangeCalculatorPageState();
}

class _ExchangeCalculatorPageState extends State<ExchangeCalculatorPage> {
  final TextEditingController _amountController =
      TextEditingController(text: '100');
  final FocusNode _amountFocusNode = FocusNode();

  bool _loading = true;
  bool _isAmountHovered = false;
  List<CurrencyItem> _currencies = [];
  List<RateItem> _rates = [];

  String _base = 'SDG';
  String _selectedCurrency = 'USD';
  bool _isBaseToTarget = true;
  double? _result;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculate);
    _amountFocusNode.addListener(_handleAmountFocusChange);
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode
      ..removeListener(_handleAmountFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleAmountFocusChange() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleLanguage() async {
    await LocaleService.toggle();
    if (!mounted) return;
    await context.setLocale(LocaleService.locale);
    MainShellPage.of(context)?.refreshForLocaleChange();
    if (!mounted) return;
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final savedBase = await BaseCurrencyService.getBaseCurrency();
    final currencies = await MarketService.getCurrencies();
    final targets = currencies
        .map((item) => item.code)
        .where((code) => code.isNotEmpty && code != savedBase)
        .toList();
    final rates =
        await MarketService.getRatesForAll(base: savedBase, targets: targets);

    if (!mounted) return;

    setState(() {
      _base = savedBase;
      _currencies = currencies;
      _rates = rates;
      _selectedCurrency = _pickNextSelectedCurrency();
      _loading = false;
    });

    _calculate();
  }

  Future<void> _changeBase(String newBase) async {
    await BaseCurrencyService.saveBaseCurrency(newBase);
    setState(() {
      _base = newBase;
      _loading = true;
    });

    final targets = _currencies
        .map((item) => item.code)
        .where((code) => code.isNotEmpty && code != newBase)
        .toList();
    final rates =
        await MarketService.getRatesForAll(base: newBase, targets: targets);

    if (!mounted) return;

    setState(() {
      _rates = rates;
      _selectedCurrency = _pickNextSelectedCurrency();
      _loading = false;
    });

    _calculate();
  }

  String _pickNextSelectedCurrency() {
    if (_rates.any((rate) => rate.target == _selectedCurrency)) {
      return _selectedCurrency;
    }
    return _rates.isNotEmpty ? _rates.first.target : _base;
  }

  void _toggleDirection() {
    HapticFeedback.selectionClick();
    setState(() => _isBaseToTarget = !_isBaseToTarget);
    _calculate();
  }

  RateItem? _lookupRate(String code) {
    try {
      return _rates.firstWhere((e) => e.target == code);
    } catch (_) {
      return null;
    }
  }

  double? _findRate(String from, String to) {
    if (from == to) return 1.0;

    if (from == _base) {
      return _lookupRate(to)?.price;
    }

    if (to == _base) {
      final row = _lookupRate(from);
      if (row == null || row.price == 0) return null;
      return 1 / row.price;
    }

    final fromRow = _lookupRate(from);
    final toRow = _lookupRate(to);
    if (fromRow == null || toRow == null || fromRow.price == 0) return null;
    return toRow.price / fromRow.price;
  }

  void _calculate() {
    if (_loading || _rates.isEmpty || _currencies.isEmpty) {
      if (mounted) setState(() => _result = null);
      return;
    }

    final amount = double.tryParse(_normalizeNumber(_amountController.text));
    if (amount == null || amount <= 0) {
      if (mounted) setState(() => _result = null);
      return;
    }

    final rate = _findRate(_fromCurrency, _toCurrency);
    if (mounted) {
      setState(() => _result = rate == null ? null : amount * rate);
    }
  }

  List<String> get _availableCodes {
    final set = <String>{_base, ..._rates.map((e) => e.target)};
    return _currencies
        .where((e) => set.contains(e.code))
        .map((e) => e.code)
        .toList();
  }

  List<String> get _targetCodes =>
      _availableCodes.where((code) => code != _base).toList();

  String get _fromCurrency => _isBaseToTarget ? _base : _selectedCurrency;

  String get _toCurrency => _isBaseToTarget ? _selectedCurrency : _base;

  String _currencyName(String code) {
    try {
      return _currencies.firstWhere((e) => e.code == code).name;
    } catch (_) {
      return code;
    }
  }

  String _flag(String code) => CurrencyFlagHelper.fromCurrencyCode(code);

  String _formatNumber(double value, {int decimals = 2}) {
    final fixed = value.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final whole = parts.first.replaceAllMapped(reg, (_) => ',');
    return decimals == 0 ? whole : '$whole.${parts.last}';
  }

  String _normalizeNumber(String value) => value.replaceAll(',', '').trim();

  String get _rateLine {
    final rate = _findRate(_fromCurrency, _toCurrency);
    if (rate == null) return 'Rate unavailable';
    return '1 ${_currencyShortLabel(_fromCurrency)} = ${_formatNumber(rate, decimals: rate >= 1 ? 3 : 4)} ${_currencyShortLabel(_toCurrency)}';
  }

  String _currencyShortLabel(String code) {
    if (code == _base) return 'SDG';
    return _currencyName(code);
  }

  double _adaptiveFontSize(String value, {double large = 38, double min = 22}) {
    final length = value.length;
    if (length <= 8) return large;
    if (length <= 11) return 32;
    if (length <= 14) return 28;
    if (length <= 17) return 24;
    return min;
  }

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final codes = _availableCodes;
    final targetCodes = _targetCodes;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      body: SafeArea(
        child: _loading
            ? Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
                child: Column(
                  children: const [
                    AppSkeletonBlock(height: 72, rows: 1),
                    SizedBox(height: 14),
                    AppSkeletonBlock(height: 360, rows: 4),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
                  children: [
                    _buildTopBar(codes),
                    const SizedBox(height: 14),
                    _buildMainCard(targetCodes),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar(List<String> codes) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3EBEF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _buildBaseButton(codes),
            ),
          ),
          const SizedBox(width: 10),
          _buildLanguageButton(),
          const SizedBox(width: 10),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildMainCard(List<String> targetCodes) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE3EBEF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E2B37).withOpacity(0.06),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildConversionHeader(targetCodes),
          const SizedBox(height: 18),
          _buildAmountSection(),
          const SizedBox(height: 18),
          _buildResultSection(),
        ],
      ),
    );
  }

  Widget _buildConversionHeader(List<String> targetCodes) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173541), Color(0xFF245363)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Material(
              color: Colors.white.withOpacity(0.12),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _toggleDirection,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildCompactCurrencyChip(
              _toCurrency,
              editable: true,
              onTap: () => _openCurrencySheet(
                title: _t('Currency', 'العملة'),
                selectedCode: _selectedCurrency,
                codes: targetCodes,
                onSelect: (value) {
                  if (value == _selectedCurrency) return;
                  setState(() => _selectedCurrency = value);
                  _calculate();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorCard(List<String> targetCodes) {
    return _buildSideCard(
      title: _t('Currency', 'العملة'),
      code: _selectedCurrency,
      editable: true,
      items: targetCodes,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedCurrency = value);
        _calculate();
      },
    );
  }

  Widget _buildAmountSection() {
    final amountText = _amountController.text.isEmpty ? '0' : _amountController.text;
    final isFocused = _amountFocusNode.hasFocus;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _flag(_toCurrency),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_t('You send', 'أنت ترسل')} ${_currencyName(_toCurrency)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          MouseRegion(
            cursor: SystemMouseCursors.text,
            onEnter: (_) => setState(() => _isAmountHovered = true),
            onExit: (_) => setState(() => _isAmountHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isFocused
                    ? Colors.white.withOpacity(0.42)
                    : _isAmountHovered
                        ? Colors.white.withOpacity(0.32)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    inputFormatters: [_ThousandsSeparatorFormatter()],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    cursorColor: const Color(0xFF245363),
                    cursorWidth: 2.4,
                    cursorRadius: const Radius.circular(4),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: _adaptiveFontSize(amountText, large: 38, min: 20),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: '0',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: isFocused ? 3 : 2,
                    width: isFocused
                        ? 120
                        : _isAmountHovered
                            ? 72
                            : 36,
                    decoration: BoxDecoration(
                      color: isFocused
                          ? const Color(0xFF245363)
                          : _isAmountHovered
                              ? const Color(0xFF8FB1BC)
                              : const Color(0xFFD6E2E7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    final resultText =
        _result == null ? '--' : _formatNumber(_result!, decimals: 2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF163541),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _flag(_fromCurrency),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_t('You get', 'أنت تستلم')} ${_currencyName(_fromCurrency)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              resultText,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: _adaptiveFontSize(resultText, large: 38, min: 20),
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.show_chart_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _rateLine,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: const Color(0xFFF4F8FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _load,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2EAEE)),
          ),
          child: const Icon(
            Icons.sync_rounded,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton() {
    final languageCode = LocaleService.isArabic ? 'AR' : 'EN';

    return Material(
      color: const Color(0xFFF4F8FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _toggleLanguage,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2EAEE)),
          ),
          alignment: Alignment.center,
          child: Text(
            languageCode,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBaseButton(List<String> codes) {
    return Material(
      color: const Color(0xFFF4F8FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openCurrencySheet(
          title: 'Base currency',
          selectedCode: _base,
          codes: codes,
          onSelect: (value) {
            if (value != _base) {
              _changeBase(value);
            }
          },
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2EAEE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_flag(_base)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _currencyName(_base),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCurrencyChip(
    String code, {
    bool editable = false,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(_flag(code), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _currencyName(code),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (editable) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Colors.white.withOpacity(0.86),
            ),
          ],
        ],
      ),
    );

    if (!editable || onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: content,
      ),
    );
  }

  Widget _buildTopMeta({
    required String label,
    required String value,
    required String flag,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(flag, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 2),
      ],
    );
  }

  Widget _buildSideCard({
    required String title,
    required String code,
    required bool editable,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2EAEE)),
                ),
                child: Center(
                  child: Text(_flag(code), style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: editable
                    ? _buildLightDropdown(
                        code: code,
                        onTap: () => _openCurrencySheet(
                          title: title,
                          selectedCode: code,
                          codes: items,
                          onSelect: (value) => onChanged(value),
                        ),
                      )
                    : Text(
                        _currencyName(code),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLightDropdown({
    required String code,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF7FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(_flag(code)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currencyName(code),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCurrencySheet({
    required String title,
    required String selectedCode,
    required List<String> codes,
    required ValueChanged<String> onSelect,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CurrencySheet(
          title: title,
          selectedCode: selectedCode,
          codes: codes,
          flagFor: _flag,
          nameFor: _currencyName,
        );
      },
    );

    if (picked != null && mounted) {
      onSelect(picked);
    }
  }
}

class _CurrencySheet extends StatelessWidget {
  final String title;
  final String selectedCode;
  final List<String> codes;
  final String Function(String) flagFor;
  final String Function(String) nameFor;

  const _CurrencySheet({
    required this.title,
    required this.selectedCode,
    required this.codes,
    required this.flagFor,
    required this.nameFor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD9E2E7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              itemBuilder: (context, index) {
                final code = codes[index];
                final selected = code == selectedCode;
                return Material(
                  color: selected
                      ? const Color(0xFFEEF4F7)
                      : const Color(0xFFF9FBFC),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(code),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(flagFor(code), style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              nameFor(code),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF245363),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: codes.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) {
      return const TextEditingValue(text: '');
    }

    if (!RegExp(r'^\d*\.?\d*$').hasMatch(raw)) {
      return oldValue;
    }

    final parts = raw.split('.');
    final grouped = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final decimal = parts.length > 1 ? parts.sublist(1).join() : '';
    final formatted = decimal.isEmpty ? grouped : '$grouped.$decimal';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
