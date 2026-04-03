import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/market_models.dart' show CurrencyItem;
import '../../data/models/price_models.dart';
import '../../data/services/market_service.dart';
import '../../data/services/price_service.dart';
import '../../core/services/base_currency_service.dart';

class MarketRatesPage extends StatefulWidget {
  const MarketRatesPage({super.key});

  @override
  State<MarketRatesPage> createState() => _MarketRatesPageState();
}

class _MarketRatesPageState extends State<MarketRatesPage> {
  bool _isLoading = true;
  List<RateItem> _allRates = [];
  String _baseCurrency = 'SDG';
  List<CurrencyItem> _currencies = [];

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    setState(() => _isLoading = true);
    try {
      final base = await BaseCurrencyService.getBaseCurrency();
      final currencies = _currencies.isEmpty
          ? await MarketService.getCurrencies()
          : _currencies;
      final targets = currencies
          .map((item) => item.code)
          .where((code) => code.isNotEmpty && code != base)
          .toList();
      final response = await PriceService.getRates(
        base: base,
        targets: targets,
      );

      if (mounted) {
        setState(() {
          _baseCurrency = base;
          _currencies = currencies;
          _allRates = response?.rates ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'أسعار السوق',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchRates,
            icon: const Icon(Icons.sync_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRates,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: _allRates.length,
                itemBuilder: (context, index) {
                  final rate = _allRates[index];
                  return _buildRateCard(rate);
                },
              ),
            ),
    );
  }

  Widget _buildRateCard(RateItem rate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildLeadingIcon(rate.target),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rate.targetName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1 ${rate.target} = ${rate.price.toStringAsFixed(2)} $_baseCurrency',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(height: 4),
              Text(
                rate.tranTime ?? '',
                style: const TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(String code) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          code,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
