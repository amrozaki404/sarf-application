import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/main_shell_page.dart';
import '../../core/localization/locale_service.dart';
import '../../core/services/base_currency_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_flag_helper.dart';
import '../../core/widgets/app_action_button.dart';
import '../../core/widgets/app_skeleton_block.dart';
import '../../data/models/market_models.dart' hide RateItem;
import '../../data/models/price_models.dart';
import '../../data/services/market_service.dart';
import '../../data/services/price_service.dart';

class RatesPage extends StatefulWidget {
  final dynamic user;
  const RatesPage({super.key, this.user});

  @override
  State<RatesPage> createState() => _RatesPageState();
}

String getCurrencyFlag(String code) => CurrencyFlagHelper.fromCurrencyCode(code);

class _RatesPageState extends State<RatesPage> {
  bool _isLoading = true;
  String _base = 'SDG';
  List<CurrencyItem> _currencies = [];
  List<RateItem> _rates = [];
  MetalPrices? _metals;
  DateTime? _lastUpdated;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _refreshData(isInitial: true);
  }

  Future<void> _refreshData({bool isInitial = false, String? newBase}) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    if (newBase != null) HapticFeedback.mediumImpact();

    try {
      final targetBase = newBase ?? await BaseCurrencyService.getBaseCurrency();
      final currencies = isInitial || _currencies.isEmpty
          ? await MarketService.getCurrencies()
          : _currencies;
      final targets = currencies
          .map((item) => item.code)
          .where((code) => code.isNotEmpty && code != targetBase)
          .toList();
      final pricesData = await PriceService.getRates(
        base: targetBase,
        targets: targets,
      );

      if (newBase != null) {
        await BaseCurrencyService.saveBaseCurrency(newBase);
      }

      if (!mounted) return;

      setState(() {
        _base = targetBase;
        _currencies = currencies;

        if (pricesData != null && pricesData is PricesResponse) {
          _rates = pricesData.rates;
          _metals = pricesData.metals;
        } else if (pricesData != null) {
          try {
            _rates = (pricesData as dynamic).rates;
            _metals = (pricesData as dynamic).metals;
          } catch (_) {
            _rates = [];
            _metals = null;
          }
        } else {
          _rates = [];
          _metals = null;
        }

        _lastUpdated = DateTime.now();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Sorry, data could not be refreshed right now',
              'عذراً، تعذر تحديث البيانات حالياً',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCurrencyBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CurrencyPickerSheet(
        currencies: _currencies,
        selectedBase: _base,
        onSelect: (code) {
          Navigator.pop(context);
          _refreshData(newBase: code);
        },
      ),
    );
  }

  Future<void> _onLanguagePressed() async {
    await LocaleService.toggle();
    if (!mounted) return;
    await context.setLocale(LocaleService.locale);
    MainShellPage.of(context)?.refreshForLocaleChange();
    if (!mounted) return;
    await _refreshData();
  }

  RateItem? _findRate(String code) {
    try {
      return _rates.firstWhere((e) => e.target == code);
    } catch (_) {
      return null;
    }
  }

  String _currencyName(String code) {
    try {
      return _currencies.firstWhere((e) => e.code == code).name;
    } catch (_) {
      return code;
    }
  }

  String _formatNumber(double value, {int decimals = 2}) {
    final fixed = value.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final integer = parts[0];
    final decimal = parts.length > 1 ? parts[1] : '';

    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final withComma = integer.replaceAllMapped(reg, (match) => ',');

    if (decimals == 0) return withComma;
    return '$withComma.$decimal';
  }

  String _formatRate(double value) {
    if (value >= 1000) return _formatNumber(value, decimals: 2);
    if (value >= 100) return _formatNumber(value, decimals: 2);
    if (value >= 1) return _formatNumber(value, decimals: 3);
    return _formatNumber(value, decimals: 4);
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _metalUnitLabel() {
    return _isArabic ? '$_base / جرام' : '$_base / gram';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 156,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF163541), Color(0xFF245363)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(36),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 20),
                  _buildRatesHeader(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _isLoading
                        ? const _LoadingBlock()
                        : _buildRatesGrid(_rates),
                  ),
                  const SizedBox(height: 18),
                  _buildMetalsHeader(),
                  const SizedBox(height: 10),
                  Expanded(
                    child:
                        _isLoading ? const _LoadingBlock() : _buildMetalsCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163541), Color(0xFF245363)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163541).withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _t('Market overview', 'نظرة على السوق'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              AppActionButton(
                icon: Icons.sync_rounded,
                onTap: () => _refreshData(),
                dark: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TopSelectorButton(
            flag: getCurrencyFlag(_base),
            title: _currencyName(_base),
            onTap: _showCurrencyBottomSheet,
            dark: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRatesHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _t('Exchange rates', 'أسعار العملات'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetalsHeader() {
    return Text(
      _t('Gold and silver', 'الذهب والفضة'),
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildRatesGrid(List<RateItem> rates) {
    if (rates.isEmpty) {
      return _EmptyBlock(
        message: _t(
          'No exchange rate data is available right now',
          'لا توجد بيانات أسعار متاحة حالياً',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: rates.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 10, color: Color(0xFFF0F3F7)),
        itemBuilder: (context, index) => _buildRateCard(rates[index]),
      ),
    );
  }

  Widget _buildRateCard(RateItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          _FlagBubble(
            flag: getCurrencyFlag(item.target),
            size: 46,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.targetName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.target,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatRate(item.price),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_base / 1 ${item.target}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetalsCard() {
    if (_metals == null) {
      return _EmptyBlock(
        message: _t('Metal data is unavailable', 'بيانات المعادن غير متوفرة'),
      );
    }

    final items = [
      _MetalItem(
        title: _t('24K gold', 'ذهب عيار 24'),
        value: _metals!.gold24kPerGramSDG,
        icon: Icons.workspace_premium_rounded,
      ),
      _MetalItem(
        title: _t('21K gold', 'ذهب عيار 21'),
        value: _metals!.gold21kPerGramSDG,
        icon: Icons.diamond_outlined,
      ),
      _MetalItem(
        title: _t('Pure silver', 'فضة نقية'),
        value: _metals!.silverPerGramSDG,
        icon: Icons.circle_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 8, color: Color(0xFFF0F3F7)),
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6E5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    item.icon,
                    color: const Color(0xFFC9991A),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.value == null ? '--' : _formatRate(item.value!),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _metalUnitLabel(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopSelectorButton extends StatelessWidget {
  final String flag;
  final String title;
  final VoidCallback onTap;
  final bool dark;

  const _TopSelectorButton({
    required this.flag,
    required this.title,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final secondary = dark ? Colors.white70 : AppColors.textSecondary;
    final borderColor =
        dark ? Colors.white.withOpacity(0.14) : const Color(0xFFE7ECF3);

    return Material(
      color: dark ? Colors.white.withOpacity(0.08) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withOpacity(0.06) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              _FlagBubble(flag: flag, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagBubble extends StatelessWidget {
  final String flag;
  final double size;

  const _FlagBubble({
    required this.flag,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Center(
        child: Text(
          flag,
          style: TextStyle(fontSize: size * 0.52),
        ),
      ),
    );
  }
}

class _CurrencyPickerSheet extends StatefulWidget {
  final List<CurrencyItem> currencies;
  final String selectedBase;
  final Function(String) onSelect;

  const _CurrencyPickerSheet({
    required this.currencies,
    required this.selectedBase,
    required this.onSelect,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final filtered = widget.currencies.where((item) {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return item.code.toLowerCase().contains(q) ||
          item.name.toLowerCase().contains(q);
    }).toList();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Color(0xFFFDFEFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: isArabic
                      ? 'ابحث بالاسم أو الرمز'
                      : 'Search by name or code',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF4F6FA),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isSelected = item.code == widget.selectedBase;

                  return Material(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => widget.onSelect(item.code),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            _FlagBubble(
                              flag: getCurrencyFlag(item.code),
                              size: 48,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.code,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  final double height;

  const _LoadingBlock({this.height = 180});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonBlock(height: height);
  }
}

class _EmptyBlock extends StatelessWidget {
  final String message;

  const _EmptyBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MetalItem {
  final String title;
  final double? value;
  final IconData icon;

  _MetalItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}
