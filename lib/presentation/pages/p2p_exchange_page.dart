import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_flag_helper.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/p2p_models.dart';
import '../../data/services/p2p_service.dart';
import 'p2p_history_page.dart';

String _tr(bool isArabic, String en, String ar) => isArabic ? ar : en;

class P2PExchangePage extends StatefulWidget {
  final String? initialServiceCode;

  const P2PExchangePage({
    super.key,
    this.initialServiceCode,
  });

  @override
  State<P2PExchangePage> createState() => _P2PExchangePageState();
}


class _P2PExchangePageState extends State<P2PExchangePage> {
  bool _loading = false;
  String? _loadError;
  bool _initialServiceOpened = false;
  List<P2PServiceOption> _services = List<P2PServiceOption>.from(
    P2PService.services,
  );
  List<P2POrder> _orders = [];
  P2POrder? _lastOrder;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final services = await P2PService.getServiceOptions();
      final orders = await P2PService.getOrders();
      final lastOrder = await P2PService.getLastOrder();
      if (!mounted) return;
      setState(() {
        _services = services;
        _orders = orders;
        _lastOrder = lastOrder;
        _loading = false;
      });
      _openInitialServiceIfNeeded();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = _tr(
          _isArabic,
          'Transfer mock data could not be loaded.',
          'تعذر تحميل بيانات التحويل التجريبية.',
        );
      });
    }
  }

  void _openInitialServiceIfNeeded() {
    if (_initialServiceOpened || widget.initialServiceCode == null || !mounted) {
      return;
    }

    final requestedService = _services.where(
      (service) => service.code == widget.initialServiceCode,
    );
    if (requestedService.isEmpty) return;

    _initialServiceOpened = true;
    final service = requestedService.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openDetails(service, replaceCurrentPage: true);
    });
  }

  Future<T?> _openRoute<T>(
    Route<T> route, {
    bool replaceCurrentPage = false,
  }) {
    final navigator = Navigator.of(context);
    if (replaceCurrentPage) {
      return navigator.pushReplacement<T, void>(route);
    }
    return navigator.push<T>(route);
  }

  Future<void> _openDetails(
    P2PServiceOption service, {
    bool replaceCurrentPage = false,
  }) async {
    if (!service.isAvailable) {
      _show(
        _tr(
          _isArabic,
          'Use the calculator for conversion.',
          'استخدم الحاسبة لتحويل العملات.',
        ),
      );
      return;
    }

    if (service.code == P2PService.serviceInternationalTransfer) {
      final submitted = await _openRoute<bool>(
        MaterialPageRoute(
          builder: (_) => _InternationalTransferFlowPage(
            service: service,
            isArabic: _isArabic,
          ),
        ),
        replaceCurrentPage: replaceCurrentPage,
      );

      if (submitted == true && mounted) {
        await _load();
        if (!mounted) return;
        _show(
          P2PService.submissionMessage(
            service.code,
            isArabic: _isArabic,
          ),
        );
      }
      return;
    }

    final fromMethods = await P2PService.getFromMethods(service.code);
    final fromId = fromMethods.isEmpty ? null : fromMethods.first.id;
    final toMethods = fromId == null
        ? <P2PMethodOption>[]
        : await P2PService.getToMethods(
            serviceCode: service.code,
            fromMethodId: fromId,
          );
    final merchants = fromId == null
        ? <P2PMerchantOption>[]
        : await P2PService.getMerchants(
            serviceCode: service.code,
            fromMethodId: fromId,
          );

    if (!mounted) return;

    final submitted = await _openRoute<bool>(
      MaterialPageRoute(
        builder: (_) => _TransferDetailsPage(
          service: service,
          fromMethods: fromMethods,
          initialFromMethodId: fromId,
          initialToMethods: toMethods,
          initialMerchants: merchants,
          isArabic: _isArabic,
        ),
      ),
      replaceCurrentPage: replaceCurrentPage,
    );

    if (submitted == true && mounted) {
      await _load();
      if (!mounted) return;
      _show(
        P2PService.submissionMessage(
          service.code,
          isArabic: _isArabic,
        ),
      );
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        title: Text(_tr(_isArabic, 'Services', 'الخدمات')),
        actions: [
          if (_orders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.receipt_long_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => P2PHistoryPage(orders: _orders),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadError != null) ...[
              _Card(
                child: Text(
                  _loadError!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_services.isEmpty)
              _Card(
                child: Text(
                  _tr(
                    _isArabic,
                    'No mock transfer services were found.',
                    'لا توجد خدمات تحويل تجريبية حالياً.',
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              _TransferSelectorCard(
                services: _services,
                onSelected: _openDetails,
                isArabic: _isArabic,
              ),
          ],
        ),
      ),
    );
  }
}

class _IntlTransferProvider {
  final String id;
  final String name;
  final String? logoUrl;

  const _IntlTransferProvider({
    required this.id,
    required this.name,
    this.logoUrl,
  });
}

class _IntlExchangeRate {
  final String providerId;
  final String sendCurrency;
  final String receiveCurrency;
  final double rate;

  const _IntlExchangeRate({
    required this.providerId,
    required this.sendCurrency,
    required this.receiveCurrency,
    required this.rate,
  });
}

class _IntlExchangeHouse {
  final String id;
  final String name;
  final String logoText;
  final String? logoUrl;
  final Color logoColor;
  final Color logoBackground;
  final String note;
  final List<_IntlExchangeRate> rates;

  const _IntlExchangeHouse({
    required this.id,
    required this.name,
    required this.logoText,
    this.logoUrl,
    required this.logoColor,
    required this.logoBackground,
    required this.note,
    required this.rates,
  });

  bool supportsProvider(String providerId) {
    return rates.any((rate) => rate.providerId == providerId);
  }

  List<String> currenciesFor(String providerId) {
    final values = rates
        .where((rate) => rate.providerId == providerId)
        .map((rate) => rate.sendCurrency)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  _IntlExchangeRate? rateFor({
    required String providerId,
    required String sendCurrency,
  }) {
    for (final rate in rates) {
      if (rate.providerId == providerId && rate.sendCurrency == sendCurrency) {
        return rate;
      }
    }
    return null;
  }
}

const List<_IntlTransferProvider> _intlProviders = [
  _IntlTransferProvider(
    id: 'wistron_transfer',
    name: 'Wistron Transfer',
    logoUrl:
        'https://play-lh.googleusercontent.com/WEI7eaROMpsxYSAWCLGhmJdlTiw94MiS57vpHHOQmBShd25mOi22x6ImBkb3bNiFL7Y=w240-h480-rw',
  ),
  _IntlTransferProvider(
    id: 'moneygram',
    name: 'MoneyGram',
    logoUrl:
        'https://play-lh.googleusercontent.com/uoo6Vd556jKBapSQyJUcZHxlDANJkH9ddMleB-7cKBUMmAA5iZ5FB6-V7st0putVXHReopMAxtzg8rw-8266CXo=w240-h480-rw',
  ),
];

const List<_IntlExchangeHouse> _intlExchangeHouses = [
  _IntlExchangeHouse(
    id: 'mig',
    name: 'MIG Exchange',
    logoText: 'MIG',
    logoUrl:
        'https://scontent.fcai20-6.fna.fbcdn.net/v/t39.30808-6/462913065_554762910465058_8315845462438786345_n.jpg?_nc_cat=103&ccb=1-7&_nc_sid=1d70fc&_nc_ohc=31Kr6xSkK6AQ7kNvwGYe_HW&_nc_oc=AdoShJJBa6wwVZsVc893ch2DijgSDipFcDijqZzp3GD5hf4kOtcfmrpXwlnc7q4u8iE&_nc_zt=23&_nc_ht=scontent.fcai20-6.fna&_nc_gid=TSLErbY3GBROMjsGwMvJSg&_nc_ss=7a389&oh=00_Af27bwlSubKLdHpa5ojH4PXczqKhCqDIk30EdV24SprbSg&oe=69D4A9E1',
    logoColor: Color(0xFF0E3E52),
    logoBackground: Color(0xFFE7F4FA),
    note: '',
    rates: [
      _IntlExchangeRate(
        providerId: 'wistron_transfer',
        sendCurrency: 'USD',
        receiveCurrency: 'SDG',
        rate: 2488,
      ),
      _IntlExchangeRate(
        providerId: 'wistron_transfer',
        sendCurrency: 'SAR',
        receiveCurrency: 'SDG',
        rate: 663.5,
      ),
      _IntlExchangeRate(
        providerId: 'moneygram',
        sendCurrency: 'USD',
        receiveCurrency: 'SDG',
        rate: 2480,
      ),
    ],
  )
];

class _InternationalTransferFlowPage extends StatefulWidget {
  final P2PServiceOption service;
  final bool isArabic;

  const _InternationalTransferFlowPage({
    required this.service,
    required this.isArabic,
  });

  @override
  State<_InternationalTransferFlowPage> createState() =>
      _InternationalTransferFlowPageState();
}

class _InternationalTransferFlowPageState
    extends State<_InternationalTransferFlowPage> {
  final _referenceController = TextEditingController();
  final _amountController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _picker = ImagePicker();

  int _currentStep = 0;
  bool _submitting = false;
  bool _isFormattingAmount = false;
  String _selectedProviderId = _intlProviders.first.id;
  String? _selectedExchangeId;
  String? _selectedCurrency;
  String? _selectedReceiveMethodId;
  File? _idDocumentFile;

  String _t(String en, String ar) => _tr(widget.isArabic, en, ar);

  List<P2PMethodOption> get _receiveMethods {
    final items = P2PService.methods
        .where((item) => item.serviceCode == P2PService.serviceLocalTransfer)
        .toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  P2PMethodOption? get _selectedReceiveMethod {
    if (_selectedReceiveMethodId == null) return null;
    try {
      return _receiveMethods.firstWhere(
        (item) => item.id == _selectedReceiveMethodId,
      );
    } catch (_) {
      return null;
    }
  }

  List<_IntlExchangeHouse> get _availableExchanges {
    final items = List<_IntlExchangeHouse>.from(_intlExchangeHouses);
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  _IntlExchangeHouse? get _selectedExchange {
    if (_selectedExchangeId == null) return null;
    try {
      return _intlExchangeHouses.firstWhere(
        (exchange) => exchange.id == _selectedExchangeId,
      );
    } catch (_) {
      return null;
    }
  }

  List<_IntlTransferProvider> get _availableProviders {
    final exchange = _selectedExchange;
    if (exchange == null) {
      return List<_IntlTransferProvider>.from(_intlProviders);
    }

    final supportedProviderIds = exchange.rates
        .map((rate) => rate.providerId)
        .toSet();
    final items = _intlProviders
        .where((provider) => supportedProviderIds.contains(provider.id))
        .toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  List<String> get _availableCurrencies {
    final exchange = _selectedExchange;
    if (exchange == null) return const [];
    return exchange.currenciesFor(_selectedProviderId);
  }

  _IntlExchangeRate? get _selectedRate {
    final exchange = _selectedExchange;
    final currency = _selectedCurrency;
    if (exchange == null || currency == null) return null;
    return exchange.rateFor(
      providerId: _selectedProviderId,
      sendCurrency: currency,
    );
  }

  double? get _sendAmount {
    return double.tryParse(_amountController.text.replaceAll(',', ''));
  }

  double? get _receiveAmount {
    final amount = _sendAmount;
    final rate = _selectedRate;
    if (amount == null || rate == null) return null;
    return amount * rate.rate;
  }

  @override
  void initState() {
    super.initState();
    _syncSelections();
    final methods = _receiveMethods;
    _selectedReceiveMethodId = methods.isEmpty ? null : methods.first.id;
    _amountController.addListener(_formatAmountInput);
  }

  @override
  void dispose() {
    _amountController.removeListener(_formatAmountInput);
    _referenceController.dispose();
    _amountController.dispose();
    _customerNameController.dispose();
    _receiverNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  void _formatAmountInput() {
    if (_isFormattingAmount) return;

    final raw = _amountController.text.replaceAll(',', '');
    if (raw.isEmpty) return;

    final parts = raw.split('.');
    final wholeDigits = parts.first.replaceAll(RegExp(r'[^0-9]'), '');
    final fractionDigits = parts.length > 1
        ? parts.sublist(1).join().replaceAll(RegExp(r'[^0-9]'), '')
        : '';

    if (wholeDigits.isEmpty) return;

    final formattedWhole = wholeDigits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final formatted = fractionDigits.isEmpty
        ? formattedWhole
        : '$formattedWhole.$fractionDigits';

    if (formatted == _amountController.text) return;

    _isFormattingAmount = true;
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingAmount = false;
  }

  void _syncSelections() {
    final exchanges = _availableExchanges;
    if (exchanges.isEmpty) {
      _selectedExchangeId = null;
      _selectedCurrency = null;
      return;
    }

    final exchangeExists = exchanges.any(
      (exchange) => exchange.id == _selectedExchangeId,
    );
    final exchange = exchangeExists
        ? exchanges.firstWhere((item) => item.id == _selectedExchangeId)
        : exchanges.first;
    _selectedExchangeId = exchange.id;

    final providers = _availableProviders;
    if (providers.isEmpty) {
      _selectedCurrency = null;
      return;
    }

    if (!providers.any((provider) => provider.id == _selectedProviderId)) {
      _selectedProviderId = providers.first.id;
    }

    final currencies = exchange.currenciesFor(_selectedProviderId);
    if (currencies.isEmpty) {
      _selectedCurrency = null;
      return;
    }

    if (!currencies.contains(_selectedCurrency)) {
      _selectedCurrency = currencies.first;
    }
  }

  Future<void> _pickDocument() async {
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _idDocumentFile = File(file.path));
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_selectedExchange == null) {
        _show(_t('Choose an exchange first.', 'اختر دار صرافة أولاً.'));
        return false;
      }
      return true;
    }

    if (_currentStep == 1) {
      if (_referenceController.text.trim().isEmpty ||
          _selectedCurrency == null ||
          _sendAmount == null ||
          _sendAmount! <= 0 ||
          _selectedRate == null) {
        _show(
          _t(
            'Enter reference, amount, and currency.',
            'أدخل المرجع والمبلغ والعملة.',
          ),
        );
        return false;
      }
      return true;
    }

    if (_currentStep == 2) {
      if (_customerNameController.text.trim().isEmpty ||
          _receiverNameController.text.trim().isEmpty ||
          _idDocumentFile == null) {
        _show(
          _t(
            'Complete customer KYC and upload the ID document.',
            'أكمل بيانات العميل وارفع وثيقة الهوية.',
          ),
        );
        return false;
      }
      return true;
    }

    if (_currentStep == 3) {
      if (_selectedReceiveMethod == null ||
          _accountNumberController.text.trim().isEmpty ||
          _accountHolderController.text.trim().isEmpty) {
        _show(
          _t(
            'Complete payout bank details first.',
            'أكمل بيانات الاستلام البنكية أولاً.',
          ),
        );
        return false;
      }
      return true;
    }

    return true;
  }

  Future<void> _continue() async {
    if (!_validateCurrentStep()) return;
    if (!mounted) return;
    if (_currentStep == 2 && _accountHolderController.text.trim().isEmpty) {
      _accountHolderController.text = _receiverNameController.text.trim();
    }
    setState(() => _currentStep += 1);
  }

  Future<bool> _handleBackNavigation() async {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
      return false;
    }
    return true;
  }

  Future<void> _handleAppBarBack() async {
    final shouldPop = await _handleBackNavigation();
    if (shouldPop && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<_IntlTransferProvider?> _showProviderPicker() {
    return showModalBottomSheet<_IntlTransferProvider>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _IntlProviderPickerSheet(
          title: _t('Transfer provider', 'جهة الحوالة'),
          providers: _availableProviders,
          selectedId: _selectedProviderId,
          isArabic: widget.isArabic,
        );
      },
    );
  }

  Future<_IntlExchangeHouse?> _showExchangePicker() {
    return showModalBottomSheet<_IntlExchangeHouse>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _IntlExchangePickerSheet(
          title: _t('Choose exchange', 'إختر الصرافة'),
          exchanges: _availableExchanges,
          selectedId: _selectedExchangeId,
          isArabic: widget.isArabic,
        );
      },
    );
  }

  Future<String?> _showCurrencyPicker() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _IntlCurrencyPickerSheet(
          title: _t('Currency', 'العملة'),
          currencies: _availableCurrencies,
          selectedCurrency: _selectedCurrency,
          isArabic: widget.isArabic,
        );
      },
    );
  }

  Future<P2PMethodOption?> _showReceiveMethodPicker() {
    return showModalBottomSheet<P2PMethodOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _MethodPickerSheet(
          title: _t('Receive method', 'وسيلة الاستلام'),
          methods: _receiveMethods,
          isArabic: widget.isArabic,
        );
      },
    );
  }

  Future<void> _showDocumentPreview({
    required File file,
    required String title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _IntlDocumentPreviewSheet(
          title: title,
          file: file,
          isArabic: widget.isArabic,
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;

    final exchange = _selectedExchange;
    final rate = _selectedRate;
    final amount = _sendAmount;
    final receiveAmount = _receiveAmount;
    final receiveMethod = _selectedReceiveMethod;
    if (exchange == null ||
        rate == null ||
        amount == null ||
        receiveAmount == null ||
        receiveMethod == null ||
        _idDocumentFile == null) {
      _show(_t(
          'Review the form and try again.', 'راجع البيانات ثم حاول مرة أخرى.'));
      return;
    }

    setState(() => _submitting = true);
    await P2PService.uploadReceipt(_idDocumentFile!);
    final provider = _intlProviders.firstWhere(
      (item) => item.id == _selectedProviderId,
    );
    await P2PService.createManualOrder(
      serviceCode: widget.service.code,
      serviceTitle: widget.service.title,
      routeTitle: '${_providerName(_selectedProviderId)} to ${exchange.name}',
      status: 'UNDER_REVIEW',
      merchantName: exchange.name,
      sendAmount: amount,
      sendCurrency: rate.sendCurrency,
      receiveAmount: receiveAmount,
      receiveCurrency: rate.receiveCurrency,
      feeAmount: 0,
      feeCurrency: rate.receiveCurrency,
      rate: rate.rate,
      paymentSummary:
          'Ref ${_referenceController.text.trim()} / KYC ${_fileName(_idDocumentFile!)}',
      destinationSummary:
          '${receiveMethod.name} / ${_accountNumberController.text.trim()} / ${_accountHolderController.text.trim()}',
      receiptName: _fileName(_idDocumentFile!),
      sourceName: provider.name,
      sourceLogoUrl: provider.logoUrl,
      destinationName: receiveMethod.name,
      destinationLogoUrl: receiveMethod.logoUrl,
      attachments: [
        P2POrderAttachment(
          label: _t('ID document', 'وثيقة الهوية'),
          name: _fileName(_idDocumentFile!),
          previewSource: _idDocumentFile!.path,
        ),
      ],
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop(true);
  }

  String _providerName(String providerId) {
    return _intlProviders
        .firstWhere((provider) => provider.id == providerId)
        .name;
  }

  String _currencyDisplay(String? currency) {
    if (currency == null || currency.isEmpty) {
      return _t('Choose currency', 'اختر العملة');
    }
    return '$currency';
  }

  String _fileName(File file) => file.path.split(Platform.pathSeparator).last;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F6F8),
        appBar: AppBar(
          leading: BackButton(onPressed: _handleAppBarBack),
          title: Text(
            P2PService.titleFor(
              P2PService.serviceInternationalTransfer,
              isArabic: widget.isArabic,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            _IntlNumericStepper(
                currentStep: _currentStep, isArabic: widget.isArabic),
            const SizedBox(height: 14),
            if (_currentStep < 4)
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepBody(),
                  ],
                ),
              )
            else
              _buildStepBody(),
            const SizedBox(height: 18),
            if (_currentStep < 4)
              AppButton(
                label: _t('Continue', 'متابعة'),
                onPressed: _continue,
              )
            else
              AppButton(
                label: _t('Submit payout request', 'إرسال طلب الاستلام'),
                onPressed: _submit,
                isLoading: _submitting,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildExchangeStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildKycStep();
      case 3:
        return _buildReceiveStep();
      default:
        return _buildReviewStep();
    }
  }

  Widget _buildExchangeStep() {
    final selectedExchange = _selectedExchange;
    final selectedProvider = _intlProviders.firstWhere(
      (provider) => provider.id == _selectedProviderId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.call_made_rounded,
          label: _t('Choose exchange', 'إختر الصرافة'),
        ),
        const SizedBox(height: 8),
        _IntlSelectorField(
          title: selectedExchange == null
              ? _t('Choose exchange', 'إختر الصرافة')
              : selectedExchange.name,
          subtitle: selectedExchange?.note,
          isArabic: widget.isArabic,
          leading: _IntlExchangeBadge(exchange: selectedExchange),
          onTap: () async {
            final selected = await _showExchangePicker();
            if (selected == null) return;
            setState(() {
              _selectedExchangeId = selected.id;
              _syncSelections();
            });
          },
        ),
        const SizedBox(height: 16),
        _SectionLabel(
          icon: Icons.call_received_rounded,
          label: _t('Transfer provider', 'جهة الحوالة'),
        ),
        const SizedBox(height: 8),
        _IntlSelectorField(
          title: selectedProvider.name,
          subtitle: null,
          isArabic: widget.isArabic,
          leading: _IntlProviderBadge(provider: selectedProvider),
          onTap: () async {
            final selected = await _showProviderPicker();
            if (selected == null) return;
            setState(() {
              _selectedProviderId = selected.id;
              _syncSelections();
            });
          },
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    final rate = _selectedRate;
    final receiveAmount = _receiveAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.receipt_long_rounded,
          label: _t('Reference number', 'رقم المرجع'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _referenceController,
          decoration: InputDecoration(
            hintText: _t('Enter Wistron reference', 'أدخل مرجع Wistron'),
          ),
        ),
        const SizedBox(height: 14),
        _SectionLabel(
          icon: Icons.payments_outlined,
          label: _t('Amount', 'المبلغ'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: _t('Enter sent amount', 'أدخل مبلغ الإرسال'),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        _SectionLabel(
          icon: Icons.attach_money_rounded,
          label: _t('Currency', 'العملة'),
        ),
        const SizedBox(height: 8),
        _IntlSelectorField(
          title: _currencyDisplay(_selectedCurrency),
          subtitle: null,
          isArabic: widget.isArabic,
          leading: _IntlCurrencyBadge(currency: _selectedCurrency),
          onTap: () async {
            final selected = await _showCurrencyPicker();
            if (selected == null) return;
            setState(() => _selectedCurrency = selected);
          },
        ),
        const SizedBox(height: 16),
        if (rate != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Exchange calculation', 'حساب التحويل'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _KeyValueRow(
                  label: _t('Desk rate', 'سعر الصرافة'),
                  value:
                      '1 ${rate.sendCurrency} = ${P2PService.fmtAmount(rate.rate)} ${rate.receiveCurrency}',
                ),
                _KeyValueRow(
                  label: _t('Estimated payout', 'الصرف المتوقع'),
                  value: receiveAmount == null
                      ? '--'
                      : '${P2PService.fmtAmount(receiveAmount)} ${rate.receiveCurrency}',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildKycStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _customerNameController,
          decoration: InputDecoration(
            labelText: _t('Sender full name', 'الاسم الكامل للمرسل'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _receiverNameController,
          decoration: InputDecoration(
            labelText: _t('Receiver full name', 'اسم الكامل للمستلم'),
          ),
        ),
        const SizedBox(height: 16),
        _UploadDocumentCard(
          title: _t('ID document', 'وثيقة الهوية'),
          subtitle: _t(
            'Passport or national ID for customer verification.',
            'جواز السفر أو الهوية الوطنية للتحقق من العميل.',
          ),
          fileName:
              _idDocumentFile == null ? null : _fileName(_idDocumentFile!),
          previewFile: _idDocumentFile,
          onPreview: _idDocumentFile == null
              ? null
              : () => _showDocumentPreview(
                    file: _idDocumentFile!,
                    title: _t('ID document', 'وثيقة الهوية'),
                  ),
          onTap: _pickDocument,
        ),
      ],
    );
  }

  Widget _buildReceiveStep() {
    final receiveMethod = _selectedReceiveMethod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.account_balance_rounded,
          label: _t('Receive method', 'وسيلة الاستلام'),
        ),
        const SizedBox(height: 8),
        _IntlSelectorField(
          title: receiveMethod == null
              ? _t('Choose receive method', 'اختر وسيلة الاستلام')
              : receiveMethod.name,
          subtitle: null,
          isArabic: widget.isArabic,
          leading: _MethodBadge(method: receiveMethod),
          onTap: () async {
            final selected = await _showReceiveMethodPicker();
            if (selected == null) return;
            setState(() => _selectedReceiveMethodId = selected.id);
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _accountNumberController,
          decoration: InputDecoration(
            labelText: _t('Account number', 'رقم الحساب'),
            hintText: _t('Enter bank or wallet number', 'أدخل رقم الحساب أو المحفظة'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _accountHolderController,
          decoration: InputDecoration(
            labelText: _t('Account holder name', 'اسم صاحب الحساب'),
            hintText: _t(
              'Defaults to receiver name',
              'يتم تعبئته باسم المستلم افتراضياً',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final exchange = _selectedExchange;
    final rate = _selectedRate;
    final receiveAmount = _receiveAmount;
    final receiveMethod = _selectedReceiveMethod;
    if (exchange == null ||
        rate == null ||
        receiveAmount == null ||
        receiveMethod == null) {
      return Text(
        _t('Review data is incomplete.', 'بيانات المراجعة غير مكتملة.'),
        style: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IntlReviewSection(
          title: _t('Transfer summary', 'ملخص التحويل'),
          icon: Icons.receipt_long_rounded,
          child: Column(
            children: [
              _KeyValueRow(
                label: _t('Transfer provider', 'جهة الحوالة'),
                value: _providerName(_selectedProviderId),
              ),
              _KeyValueRow(
                label: _t('Exchange', 'دار الصرافة'),
                value: exchange.name,
              ),
              _KeyValueRow(
                label: _t('Send currency', 'عملة الإرسال'),
                value: _currencyDisplay(rate.sendCurrency),
              ),
              _KeyValueRow(
                label: _t('Transfer amount', 'مبلغ التحويل'),
                value:
                    '${P2PService.fmtAmount(_sendAmount ?? 0)} ${_currencyDisplay(rate.sendCurrency)}',
              ),
              _KeyValueRow(
                label: _t('Receive currency', 'عملة الاستلام'),
                value: _currencyDisplay(rate.receiveCurrency),
              ),
              _KeyValueRow(
                label: _t('Received amount', 'المبلغ المستلم'),
                value:
                    '${P2PService.fmtAmount(receiveAmount)} ${_currencyDisplay(rate.receiveCurrency)}',
              ),
              _KeyValueRow(
                label: _t('Desk rate', 'سعر الصرافة'),
                value:
                    '1 ${rate.sendCurrency} = ${P2PService.fmtAmount(rate.rate)} ${rate.receiveCurrency}',
              ),
              _KeyValueRow(
                label: _t('Reference', 'المرجع'),
                value: _referenceController.text.trim(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _IntlReviewSection(
          title: _t('Payout details', 'بيانات الاستلام'),
          icon: Icons.account_balance_wallet_outlined,
          child: Column(
            children: [
              _KeyValueRow(
                label: _t('Receive method', 'وسيلة الاستلام'),
                value: receiveMethod.name,
              ),
              _KeyValueRow(
                label: _t('Account number', 'رقم الحساب'),
                value: _accountNumberController.text.trim(),
              ),
              _KeyValueRow(
                label: _t('Account holder', 'صاحب الحساب'),
                value: _accountHolderController.text.trim(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _IntlReviewSection(
          title: _t('Customer & documents', 'العميل والمستندات'),
          icon: Icons.badge_outlined,
          child: Column(
            children: [
              _KeyValueRow(
                label: _t('Customer', 'العميل'),
                value: _customerNameController.text.trim(),
              ),
              _KeyValueRow(
                label: _t('Receiver', 'المستلم'),
                value: _receiverNameController.text.trim(),
              ),
              _IntlDocumentRow(
                label: _t('ID document', 'وثيقة الهوية'),
                value: _idDocumentFile == null
                    ? '--'
                    : _fileName(_idDocumentFile!),
                previewFile: _idDocumentFile,
                onTapPreview: _idDocumentFile == null
                    ? null
                    : () => _showDocumentPreview(
                          file: _idDocumentFile!,
                          title: _t('ID document', 'وثيقة الهوية'),
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IntlSelectorField extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget leading;
  final bool isArabic;
  final VoidCallback onTap;

  const _IntlSelectorField({
    required this.title,
    required this.leading,
    required this.isArabic,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: isArabic
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _IntlReviewSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _IntlReviewSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.exchangeDark),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _IntlDocumentRow extends StatelessWidget {
  final String label;
  final String value;
  final File? previewFile;
  final VoidCallback? onTapPreview;

  const _IntlDocumentRow({
    required this.label,
    required this.value,
    this.previewFile,
    this.onTapPreview,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          if (previewFile != null)
            _IntlDocumentThumbnail(
              file: previewFile!,
              onTap: onTapPreview,
              size: 42,
            )
          else
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.exchangeDark.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.description_outlined,
                size: 18,
                color: AppColors.exchangeDark,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (onTapPreview != null) ...[
            const SizedBox(width: 8),
            Text(
              'Preview',
              style: const TextStyle(
                color: AppColors.exchangeDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTapPreview == null) {
      return content;
    }

    return InkWell(
      onTap: onTapPreview,
      borderRadius: BorderRadius.circular(14),
      child: content,
    );
  }
}

class _IntlDocumentPreviewSheet extends StatelessWidget {
  final String title;
  final File file;
  final bool isArabic;

  const _IntlDocumentPreviewSheet({
    required this.title,
    required this.file,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.86,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FBFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4DEE2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Row(
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2EAEE)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Image.file(
                          file,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntlNumericStepper extends StatelessWidget {
  final int currentStep;
  final bool isArabic;

  const _IntlNumericStepper({
    required this.currentStep,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final labels = [
      _tr(isArabic, 'Exchange', 'الصرافة'),
      _tr(isArabic, 'Details', 'التفاصيل'),
      _tr(isArabic, 'KYC', 'الهوية'),
      _tr(isArabic, 'Receive', 'الاستلام'),
      _tr(isArabic, 'Review', 'المراجعة'),
    ];
    final children = <Widget>[];

    for (var index = 0; index < labels.length; index++) {
      final isDone = index < currentStep;
      final isActive = index == currentStep;

      children.add(
        Expanded(
          child: _IntlStepItem(
            number: index + 1,
            label: labels[index],
            active: isActive,
            done: isDone,
          ),
        ),
      );

      if (index != labels.length - 1) {
        children.add(
          Container(
            width: 18,
            height: 2,
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
              color: isDone ? AppColors.exchangeDark : const Color(0xFFDCE5E9),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Row(children: children),
    );
  }
}

class _IntlStepItem extends StatelessWidget {
  final int number;
  final String label;
  final bool active;
  final bool done;

  const _IntlStepItem({
    required this.number,
    required this.label,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final filled = active || done;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: filled ? AppColors.exchangeDark : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? AppColors.exchangeDark : const Color(0xFFDCE5E9),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              color: filled ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: filled ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _IntlProviderBadge extends StatelessWidget {
  final _IntlTransferProvider? provider;

  const _IntlProviderBadge({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _LogoBadge(
      logoUrl: provider?.logoUrl,
      size: 38,
      borderRadius: 12,
      borderColor: Color(0xFFD5E3FF),
      padding: 6,
    );
  }
}

class _IntlExchangeBadge extends StatelessWidget {
  final _IntlExchangeHouse? exchange;

  const _IntlExchangeBadge({required this.exchange});

  @override
  Widget build(BuildContext context) {
    if (exchange == null) {
      return const _LogoBadge(
        logoUrl: null,
        size: 38,
        borderRadius: 12,
        borderColor: Color(0xFFD7E2E6),
        padding: 6,
      );
    }
    return _ExchangeLogoBadge(exchange: exchange!);
  }
}

class _IntlCurrencyBadge extends StatelessWidget {
  final String? currency;

  const _IntlCurrencyBadge({required this.currency});

  @override
  Widget build(BuildContext context) {
    final flag = currency == null || currency!.isEmpty
        ? null
        : CurrencyFlagHelper.fromCurrencyCode(currency!);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0A3)),
      ),
      alignment: Alignment.center,
      child: flag == null
          ? const Icon(
              Icons.attach_money_rounded,
              color: Color(0xFFB16A00),
              size: 18,
            )
          : Text(
              flag,
              style: const TextStyle(fontSize: 18),
            ),
    );
  }
}

class _IntlProviderPickerSheet extends StatelessWidget {
  final String title;
  final List<_IntlTransferProvider> providers;
  final String selectedId;
  final bool isArabic;

  const _IntlProviderPickerSheet({
    required this.title,
    required this.providers,
    required this.selectedId,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FBFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD4DEE2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...providers.map(
              (provider) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _IntlSheetTile(
                  isArabic: isArabic,
                  selected: provider.id == selectedId,
                  leading: _IntlProviderBadge(provider: provider),
                  title: provider.name,
                  onTap: () => Navigator.of(context).pop(provider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntlExchangePickerSheet extends StatelessWidget {
  final String title;
  final List<_IntlExchangeHouse> exchanges;
  final String? selectedId;
  final bool isArabic;

  const _IntlExchangePickerSheet({
    required this.title,
    required this.exchanges,
    required this.selectedId,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FBFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD4DEE2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...exchanges.map(
              (exchange) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _IntlSheetTile(
                  isArabic: isArabic,
                  selected: exchange.id == selectedId,
                  leading: _ExchangeLogoBadge(exchange: exchange),
                  title: exchange.name,
                  onTap: () => Navigator.of(context).pop(exchange),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntlCurrencyPickerSheet extends StatelessWidget {
  final String title;
  final List<String> currencies;
  final String? selectedCurrency;
  final bool isArabic;

  const _IntlCurrencyPickerSheet({
    required this.title,
    required this.currencies,
    required this.selectedCurrency,
    required this.isArabic,
  });

  String _currencyDisplay(String currency) {
    return '${CurrencyFlagHelper.fromCurrencyCode(currency)} $currency';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FBFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD4DEE2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...currencies.map(
              (currency) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _IntlSheetTile(
                  isArabic: isArabic,
                  selected: currency == selectedCurrency,
                  leading: _IntlCurrencyBadge(currency: currency),
                  title: _currencyDisplay(currency),
                  subtitle: null,
                  onTap: () => Navigator.of(context).pop(currency),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntlSheetTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool isArabic;
  final VoidCallback onTap;

  const _IntlSheetTile({
    required this.leading,
    required this.title,
    required this.selected,
    required this.isArabic,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F7FA) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.exchangeDark.withOpacity(0.25)
                : const Color(0xFFE2EAEE),
          ),
        ),
        child: Row(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: isArabic
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.exchangeDark,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeLogoBadge extends StatelessWidget {
  final _IntlExchangeHouse exchange;

  const _ExchangeLogoBadge({required this.exchange});

  @override
  Widget build(BuildContext context) {
    return _LogoBadge(
      logoUrl: exchange.logoUrl,
      size: 40,
      borderRadius: 14,
      borderColor: Color(0xFFD7E2E6),
      padding: 6,
    );
  }
}

class _UploadDocumentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? fileName;
  final File? previewFile;
  final VoidCallback? onPreview;
  final VoidCallback onTap;

  const _UploadDocumentCard({
    required this.title,
    required this.subtitle,
    required this.fileName,
    this.previewFile,
    this.onPreview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            if (previewFile != null)
              _IntlDocumentThumbnail(
                file: previewFile!,
                onTap: onPreview,
                size: 52,
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.exchangeDark.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: AppColors.exchangeDark,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (previewFile != null && onPreview != null)
                  GestureDetector(
                    onTap: onPreview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.exchangeDark.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Preview',
                        style: TextStyle(
                          color: AppColors.exchangeDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (previewFile != null && onPreview != null)
                  const SizedBox(height: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IntlDocumentThumbnail extends StatelessWidget {
  final File file;
  final VoidCallback? onTap;
  final double size;

  const _IntlDocumentThumbnail({
    required this.file,
    this.onTap,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E2E6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          if (onTap != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.zoom_in_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RatePill extends StatelessWidget {
  final String label;
  final String value;

  const _RatePill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferDetailsPage extends StatefulWidget {
  final P2PServiceOption service;
  final List<P2PMethodOption> fromMethods;
  final String? initialFromMethodId;
  final List<P2PMethodOption> initialToMethods;
  final List<P2PMerchantOption> initialMerchants;
  final bool isArabic;

  const _TransferDetailsPage({
    required this.service,
    required this.fromMethods,
    required this.initialFromMethodId,
    required this.initialToMethods,
    required this.initialMerchants,
    required this.isArabic,
  });

  @override
  State<_TransferDetailsPage> createState() => _TransferDetailsPageState();
}

class _TransferDetailsPageState extends State<_TransferDetailsPage> {
  final _amountController = TextEditingController();

  late List<P2PMethodOption> _toMethods;
  late List<P2PMerchantOption> _merchants;
  String? _fromMethodId;
  String? _toMethodId;
  bool _continueLoading = false;
  bool _isFormattingAmount = false;

  String _t(String en, String ar) => _tr(widget.isArabic, en, ar);

  @override
  void initState() {
    super.initState();
    _fromMethodId = widget.initialFromMethodId;
    _toMethods = List<P2PMethodOption>.from(widget.initialToMethods);
    _merchants = List<P2PMerchantOption>.from(widget.initialMerchants);
    _toMethodId = _toMethods.isEmpty ? null : _toMethods.first.id;
    _amountController.text =
        widget.service.code == P2PService.serviceLocalTransfer
            ? '100,000'
            : '100';
    _amountController.addListener(_formatAmountInput);
  }

  @override
  void dispose() {
    _amountController.removeListener(_formatAmountInput);
    _amountController.dispose();
    super.dispose();
  }

  void _formatAmountInput() {
    if (_isFormattingAmount) return;

    final raw = _amountController.text.replaceAll(',', '');
    if (raw.isEmpty) return;

    final parts = raw.split('.');
    final wholeDigits = parts.first.replaceAll(RegExp(r'[^0-9]'), '');
    final fractionDigits = parts.length > 1
        ? parts.sublist(1).join().replaceAll(RegExp(r'[^0-9]'), '')
        : '';

    if (wholeDigits.isEmpty) return;

    final formattedWhole = wholeDigits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final formatted = fractionDigits.isEmpty
        ? formattedWhole
        : '$formattedWhole.$fractionDigits';

    if (formatted == _amountController.text) return;

    _isFormattingAmount = true;
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingAmount = false;
  }

  Future<void> _changeFrom(String value) async {
    final toMethods = await P2PService.getToMethods(
      serviceCode: widget.service.code,
      fromMethodId: value,
    );
    final merchants = await P2PService.getMerchants(
      serviceCode: widget.service.code,
      fromMethodId: value,
    );
    if (!mounted) return;
    setState(() {
      _fromMethodId = value;
      _toMethods = toMethods;
      _merchants = merchants;
      _toMethodId = toMethods.isEmpty ? null : toMethods.first.id;
    });
  }

  double? _parsedAmount() {
    return double.tryParse(_amountController.text.replaceAll(',', ''));
  }

  Future<void> _continue() async {
    final amount = _parsedAmount();
    if (_fromMethodId == null || _toMethodId == null) {
      _show(_t('Complete all fields first.', 'أكمل كل الحقول أولاً.'));
      return;
    }
    if (amount == null || amount <= 0) {
      _show(_t('Enter a valid amount.', 'أدخل مبلغاً صحيحاً.'));
      return;
    }

    setState(() => _continueLoading = true);
    final merchants = await P2PService.getMerchants(
      serviceCode: widget.service.code,
      fromMethodId: _fromMethodId!,
    );
    if (!mounted) return;
    setState(() {
      _merchants = merchants;
      _continueLoading = false;
    });

    if (merchants.isEmpty) {
      _show(
        _t(
          'No merchants are available for this route.',
          'لا يوجد تجار متاحون لهذا المسار.',
        ),
      );
      return;
    }

    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _MerchantSelectionPage(
          service: widget.service,
          fromMethod: P2PService.getMethodById(_fromMethodId!),
          toMethod: P2PService.getMethodById(_toMethodId!),
          sendAmount: amount,
          merchants: merchants,
          isArabic: widget.isArabic,
        ),
      ),
    );

    if (submitted == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<P2PMethodOption?> _showMethodPicker({
    required String title,
    required List<P2PMethodOption> methods,
  }) {
    return showModalBottomSheet<P2PMethodOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _MethodPickerSheet(
          title: title,
          methods: methods,
          isArabic: widget.isArabic,
        );
      },
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _feeText(P2PMerchantOption merchant) {
    return merchant.feeType == 'fixed'
        ? '${P2PService.fmtAmount(merchant.feeValue)} SDG'
        : '${merchant.feeValue.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        title: Text(
          _t('P2P details', 'تفاصيل طلب P2P'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    icon: Icons.call_received_rounded,
                    label: _t('Customer has', 'ما يملكه العميل'),
                  ),
                  const SizedBox(height: 8),
                  _MethodSelectorField(
                    title: _fromMethodId == null
                        ? _t('Choose source method', 'اختر وسيلة الإرسال')
                        : P2PService.getMethodById(_fromMethodId!).name,
                    method: _fromMethodId == null
                        ? null
                        : P2PService.getMethodById(_fromMethodId!),
                    isArabic: widget.isArabic,
                    onTap: () async {
                      final selected = await _showMethodPicker(
                        title: _t('Customer has', 'ما يملكه العميل'),
                        methods: widget.fromMethods,
                      );
                      if (selected == null) return;
                      _changeFrom(selected.id);
                    },
                  ),
                  const SizedBox(height: 14),
                  _SectionLabel(
                    icon: Icons.call_made_rounded,
                    label: _t('Customer wants', 'ما الذي يريده العميل'),
                  ),
                  const SizedBox(height: 8),
                  _MethodSelectorField(
                    title: _toMethodId == null
                        ? _t(
                            'Choose destination method',
                            'اختر وسيلة الاستلام',
                          )
                        : P2PService.getMethodById(_toMethodId!).name,
                    method: _toMethodId == null
                        ? null
                        : P2PService.getMethodById(_toMethodId!),
                    isArabic: widget.isArabic,
                    onTap: () async {
                      final selected = await _showMethodPicker(
                        title: _t('Customer wants', 'ما الذي يريده العميل'),
                        methods: _toMethods,
                      );
                      if (selected == null) return;
                      setState(() => _toMethodId = selected.id);
                    },
                  ),
                  const SizedBox(height: 14),
                  _SectionLabel(
                    icon: Icons.payments_outlined,
                    label: _t('Amount', 'المبلغ'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText:
                          _t('Enter transfer amount', 'أدخل مبلغ التحويل'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: _t('Continue to merchants', 'المتابعة إلى التجار'),
                    onPressed: _continue,
                    isLoading: _continueLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantSelectionPage extends StatefulWidget {
  final P2PServiceOption service;
  final P2PMethodOption fromMethod;
  final P2PMethodOption toMethod;
  final double sendAmount;
  final List<P2PMerchantOption> merchants;
  final bool isArabic;

  const _MerchantSelectionPage({
    required this.service,
    required this.fromMethod,
    required this.toMethod,
    required this.sendAmount,
    required this.merchants,
    required this.isArabic,
  });

  @override
  State<_MerchantSelectionPage> createState() => _MerchantSelectionPageState();
}

class _MerchantSelectionPageState extends State<_MerchantSelectionPage> {
  String? _loadingMerchantId;
  int _activeTab = 0;

  String _t(String en, String ar) => _tr(widget.isArabic, en, ar);

  String _feeText(P2PMerchantOption merchant) {
    return merchant.feeType == 'fixed'
        ? '${P2PService.fmtAmount(merchant.feeValue)} SDG'
        : '${merchant.feeValue.toStringAsFixed(1)}%';
  }

  double _rating(P2PMerchantOption merchant) {
    switch (merchant.id) {
      case 'merchant_sondos':
        return 4.9;
      case 'merchant_moez':
        return 4.7;
      default:
        return 4.8;
    }
  }

  String _completionTime(P2PMerchantOption merchant) {
    switch (merchant.id) {
      case 'merchant_sondos':
        return _t('5-10 min', '5-10 دقائق');
      case 'merchant_moez':
        return _t('10-20 min', '10-20 دقيقة');
      default:
        return _t('3-8 min', '3-8 دقائق');
    }
  }

  int _completionMinutes(P2PMerchantOption merchant) {
    switch (merchant.id) {
      case 'merchant_sondos':
        return 5;
      case 'merchant_moez':
        return 10;
      default:
        return 3;
    }
  }

  List<P2PMerchantOption> _visibleMerchants() {
    final items = [...widget.merchants];
    switch (_activeTab) {
      case 1:
        items.sort((a, b) => _rating(b).compareTo(_rating(a)));
        break;
      case 2:
        items.sort(
          (a, b) => _completionMinutes(a).compareTo(_completionMinutes(b)),
        );
        break;
      default:
        items.sort((a, b) => a.name.compareTo(b.name));
    }
    return items;
  }

  Future<void> _selectMerchant(P2PMerchantOption merchant) async {
    setState(() => _loadingMerchantId = merchant.id);
    final request = P2PQuoteRequest(
      serviceCode: widget.service.code,
      fromMethodId: widget.fromMethod.id,
      toMethodId: widget.toMethod.id,
      merchantId: merchant.id,
      sendAmount: widget.sendAmount,
    );
    final quote = await P2PService.getQuote(request);
    final account = P2PService.getMerchantAccount(
      merchantId: merchant.id,
      methodId: widget.fromMethod.id,
    );
    if (!mounted) return;
    setState(() => _loadingMerchantId = null);

    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _TransferReceiptPage(
          service: widget.service,
          request: request,
          quote: quote,
          fromMethod: widget.fromMethod,
          toMethod: widget.toMethod,
          account: account,
          isArabic: widget.isArabic,
        ),
      ),
    );

    if (submitted == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleMerchants = _visibleMerchants();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_t('Pay', 'دفع')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MerchantMarketTabs(
              isArabic: widget.isArabic,
              activeIndex: _activeTab,
              onChanged: (value) => setState(() => _activeTab = value),
            ),
            const SizedBox(height: 12),
            ...visibleMerchants.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MerchantCard(
                      merchant: entry.value,
                      feeText: _feeText(entry.value),
                      rating: _rating(entry.value),
                      completionTime: _completionTime(entry.value),
                      selectLabel: _t('Pay', 'دفع'),
                      isLoading: _loadingMerchantId == entry.value.id,
                      onSelect: () => _selectMerchant(entry.value),
                      isArabic: widget.isArabic,
                      isBestOffer: _activeTab != 0 && entry.key == 0,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _TransferReceiptPage extends StatefulWidget {
  final P2PServiceOption service;
  final P2PQuoteRequest request;
  final P2PQuote quote;
  final P2PMethodOption fromMethod;
  final P2PMethodOption toMethod;
  final P2PMerchantAccount account;
  final bool isArabic;

  const _TransferReceiptPage({
    required this.service,
    required this.request,
    required this.quote,
    required this.fromMethod,
    required this.toMethod,
    required this.account,
    required this.isArabic,
  });

  @override
  State<_TransferReceiptPage> createState() => _TransferReceiptPageState();
}

class _TransferReceiptPageState extends State<_TransferReceiptPage> {
  final _picker = ImagePicker();
  File? _receiptFile;
  bool _submitLoading = false;

  String _t(String en, String ar) => _tr(widget.isArabic, en, ar);

  Future<void> _pickReceipt() async {
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _receiptFile = File(file.path));
  }

  Future<void> _submit() async {
    if (_receiptFile == null) {
      _show(_t('Upload the receipt first.', 'ارفع الإيصال أولاً.'));
      return;
    }

    setState(() => _submitLoading = true);
    await P2PService.uploadReceipt(_receiptFile!);
    await P2PService.createOrder(
      request: widget.request,
      receiptName: _receiptFile!.path.split(Platform.pathSeparator).last,
      receiptPreviewSource: _receiptFile!.path,
    );
    if (!mounted) return;
    setState(() => _submitLoading = false);
    Navigator.of(context).pop(true);
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_t('Receipt & submit', 'الإيصال والإرسال')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppGradients.exchangeHeader,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Payment summary', 'ملخص الدفع'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _AmountSummary(
                    quote: widget.quote,
                    isArabic: widget.isArabic,
                    dark: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Customer summary', 'ملخص العميل'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  _KeyValueRow(
                    label: _t('Route', 'المسار'),
                    value: widget.quote.routeTitle,
                  ),
                  _KeyValueRow(
                    label: _t('Merchant', 'التاجر'),
                    value: widget.quote.merchantName,
                  ),
                  _KeyValueRow(
                    label: _t('Rate', 'السعر'),
                    value: widget.quote.rateLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Merchant payment details', 'بيانات دفع التاجر'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _KeyValueRow(
                    label: _t('Send by', 'الإرسال عبر'),
                    value: widget.fromMethod.name,
                  ),
                  _KeyValueRow(
                    label: _t('Account name', 'اسم الحساب'),
                    value: widget.account.accountName,
                  ),
                  _KeyValueRow(
                    label: _t('Account number', 'رقم الحساب'),
                    value: widget.account.accountNumber,
                  ),
                  _KeyValueRow(
                    label: _t('Bank / method', 'البنك / الوسيلة'),
                    value: widget.account.bankName,
                  ),
                  _KeyValueRow(
                    label: _t('Customer receives to', 'العميل يستلم إلى'),
                    value: widget.toMethod.name,
                  ),
                  if (widget.account.note.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoBanner(
                      icon: Icons.info_outline_rounded,
                      title: _t('Payment note', 'ملاحظة الدفع'),
                      value: widget.account.note,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Receipt upload', 'رفع الإيصال'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickReceipt,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.exchangeDark.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.upload_file_rounded,
                              color: AppColors.exchangeDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _receiptFile?.path
                                          .split(Platform.pathSeparator)
                                          .last ??
                                      _t(
                                        'Choose receipt image',
                                        'اختر صورة الإيصال',
                                      ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _t(
                                    'Upload a clear payment proof before submitting.',
                                    'ارفع إثبات دفع واضح قبل إرسال الطلب.',
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: _t('Submit P2P request', 'إرسال طلب P2P'),
              onPressed: _submit,
              isLoading: _submitLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodSelectorField extends StatelessWidget {
  final String title;
  final P2PMethodOption? method;
  final bool isArabic;
  final VoidCallback onTap;

  const _MethodSelectorField({
    required this.title,
    required this.method,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          children: [
            _MethodBadge(method: method),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  color: method == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodPickerSheet extends StatelessWidget {
  final String title;
  final List<P2PMethodOption> methods;
  final bool isArabic;

  const _MethodPickerSheet({
    required this.title,
    required this.methods,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FBFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD4DEE2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...methods.map(
              (method) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MethodSheetTile(
                  method: method,
                  isArabic: isArabic,
                  onTap: () => Navigator.of(context).pop(method),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodSheetTile extends StatelessWidget {
  final P2PMethodOption method;
  final bool isArabic;
  final VoidCallback onTap;

  const _MethodSheetTile({
    required this.method,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2EAEE)),
        ),
        child: Row(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          children: [
            _MethodBadge(method: method),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.name,
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final P2PMethodOption? method;

  const _MethodBadge({
    required this.method,
  });

  Color get _accent {
    switch (method?.type) {
      case 'wallet':
        return const Color(0xFF2E6BFF);
      case 'bank':
        return const Color(0xFF0E7C66);
      case 'international':
        return const Color(0xFFB16A00);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LogoBadge(
      logoUrl: method?.logoUrl,
      size: 38,
      borderRadius: 12,
      borderColor:
          method == null ? const Color(0xFFD7E2E6) : _accent.withOpacity(0.25),
      padding: 6,
    );
  }
}

class _LogoBadge extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final double borderRadius;
  final double padding;
  final Color borderColor;

  const _LogoBadge({
    required this.logoUrl,
    required this.size,
    required this.borderRadius,
    required this.borderColor,
    this.padding = 5,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Padding(
      padding: EdgeInsets.all(padding),
      child: Image.asset(
        'assets/images/app_icon.png',
        fit: BoxFit.contain,
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl == null || logoUrl!.trim().isEmpty
          ? fallback
          : Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }
                return fallback;
              },
            ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  final P2PMerchantOption merchant;
  final String feeText;
  final double rating;
  final String completionTime;
  final String selectLabel;
  final bool isLoading;
  final VoidCallback onSelect;
  final bool isArabic;
  final bool isBestOffer;

  const _MerchantCard({
    required this.merchant,
    required this.feeText,
    required this.rating,
    required this.completionTime,
    required this.selectLabel,
    required this.isLoading,
    required this.onSelect,
    required this.isArabic,
    this.isBestOffer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onSelect,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  isBestOffer ? AppColors.exchangeDark : AppColors.inputBorder,
              width: isBestOffer ? 1.3 : 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              Row(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  _BuyButton(
                    label: selectLabel,
                    onPressed: onSelect,
                    isLoading: isLoading,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection:
                              isArabic ? TextDirection.rtl : TextDirection.ltr,
                          children: [
                            Flexible(
                              child: Text(
                                merchant.name,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.exchangeDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.exchangeDark.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${rating.toStringAsFixed(1)} ★',
                            style: const TextStyle(
                              color: AppColors.exchangeDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MerchantMetric(
                      label: isArabic ? 'الرسوم' : 'Fee',
                      value: feeText,
                      icon: Icons.percent_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MerchantMetric(
                      label: isArabic ? 'زمن التنفيذ' : 'Completion',
                      value: completionTime,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTradeSummary extends StatelessWidget {
  final String fromLabel;
  final String toLabel;
  final String amountLabel;
  final String countLabel;
  final bool isArabic;

  const _CompactTradeSummary({
    required this.fromLabel,
    required this.toLabel,
    required this.amountLabel,
    required this.countLabel,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: isArabic ? 'من' : 'From',
              value: fromLabel,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: isArabic ? 'إلى' : 'To',
              value: toLabel,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: isArabic ? 'المبلغ' : 'Amount',
              value: amountLabel,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: isArabic ? 'العروض' : 'Offers',
              value: countLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantMarketTabs extends StatelessWidget {
  final bool isArabic;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const _MerchantMarketTabs({
    required this.isArabic,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MarketChip(
              label: isArabic ? 'الكل' : 'All',
              active: activeIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _MarketChip(
              label: isArabic ? 'الأفضل' : 'Best',
              active: activeIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
          Expanded(
            child: _MarketChip(
              label: isArabic ? 'السريع' : 'Fast',
              active: activeIndex == 2,
              onTap: () => onChanged(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool dark;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: dark ? const Color(0xFF9BA3AF) : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: dark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MarketChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _MarketChip({
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.exchangeDark : AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Align(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color color;

  const _OfferTag({
    required this.label,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MerchantMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool dark;

  const _MerchantMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? AppColors.exchangeDarkSoft : AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: dark ? null : Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: dark ? Colors.white : AppColors.exchangeDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: dark
                        ? const Color(0xFF9BA3AF)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: dark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const _BuyButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: 96,
        height: 38,
        decoration: BoxDecoration(
          gradient: AppGradients.exchangeButton,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppShadows.action,
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class _TransferHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _TransferHero({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.exchangeHeader,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFD0E1E7),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const _ProgressStrip({
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index == currentStep;
        final done = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active || done ? AppColors.exchangeDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active || done
                    ? AppColors.exchangeDark
                    : const Color(0xFFDCE5E9),
              ),
            ),
            child: Center(
              child: Text(
                labels[index],
                style: TextStyle(
                  color:
                      active || done ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _TransferSelectorCard extends StatelessWidget {
  final List<P2PServiceOption> services;
  final ValueChanged<P2PServiceOption> onSelected;
  final bool isArabic;

  const _TransferSelectorCard({
    required this.services,
    required this.onSelected,
    required this.isArabic,
  });

  String _titleFor(P2PServiceOption item) {
    return P2PService.titleFor(item.code, isArabic: isArabic);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: List.generate(services.length, (index) {
                final item = services[index];
                return Column(
                  children: [
                    _TransferServiceRow(
                      title: _titleFor(item),
                      leadingIcon: _TransferPatternIcon(
                        serviceCode: item.code,
                      ),
                      isArabic: isArabic,
                      onTap: () => onSelected(item),
                    ),
                    if (index != services.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE6EEF1),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferServiceRow extends StatelessWidget {
  final String title;
  final Widget leadingIcon;
  final bool isArabic;
  final VoidCallback onTap;

  const _TransferServiceRow({
    required this.title,
    required this.leadingIcon,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            children: [
              Icon(
                isArabic
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 44,
                child: Align(
                  alignment:
                      isArabic ? Alignment.centerRight : Alignment.centerLeft,
                  child: leadingIcon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferPatternIcon extends StatelessWidget {
  final String serviceCode;

  const _TransferPatternIcon({
    required this.serviceCode,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 30,
      child: serviceCode == P2PService.serviceInternationalTransfer
          ? const _CurrencyTransferGlyph()
          : const _WalletTransferGlyph(),
    );
  }
}

class _CurrencyTransferGlyph extends StatelessWidget {
  const _CurrencyTransferGlyph();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: _GlyphBubble(
            size: 18,
            child: const Text(
              '\$',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.exchangeDark,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: _GlyphBubble(
            size: 18,
            fill: const Color(0xFFEDF4FF),
            child: const Icon(
              Icons.currency_exchange_rounded,
              size: 12,
              color: Color(0xFF2E6BFF),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletTransferGlyph extends StatelessWidget {
  const _WalletTransferGlyph();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: const [
        Positioned(
          top: 6,
          left: 0,
          child: _DeviceGlyph(),
        ),
        Positioned(
          top: 2,
          left: 16,
          child: _DeviceGlyph(),
        ),
      ],
    );
  }
}

class _DeviceGlyph extends StatelessWidget {
  const _DeviceGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF2E6BFF),
          width: 1.6,
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(2, 3, 2, 2),
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1FF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 4,
            height: 2,
            decoration: BoxDecoration(
              color: const Color(0xFF2E6BFF),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlyphBubble extends StatelessWidget {
  final double size;
  final Color fill;
  final Widget child;

  const _GlyphBubble({
    required this.size,
    required this.child,
    this.fill = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.exchangeDark,
          width: 1.4,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.exchangeDark),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.exchangeDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountSummary extends StatelessWidget {
  final P2PQuote quote;
  final bool isArabic;
  final bool dark;

  const _AmountSummary({
    required this.quote,
    required this.isArabic,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.10) : AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: dark ? null : Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AmountColumn(
              label: isArabic ? 'يستلم العميل' : 'Customer receives',
              amount:
                  '${P2PService.fmtAmount(quote.receiveAmount)} ${quote.receiveCurrency}',
              emphasize: true,
              dark: dark,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withOpacity(0.14)
                  : AppColors.exchangeDark.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: dark ? Colors.white : AppColors.exchangeDark,
            ),
          ),
          Expanded(
            child: _AmountColumn(
              label: isArabic ? 'يدفع العميل' : 'Customer pays',
              amount:
                  '${P2PService.fmtAmount(quote.sendAmount)} ${quote.sendCurrency}',
              dark: dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final String amount;
  final bool emphasize;
  final bool dark;

  const _AmountColumn({
    required this.label,
    required this.amount,
    this.emphasize = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: dark ? Colors.white70 : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: dark
                ? Colors.white
                : (emphasize ? AppColors.exchangeDark : AppColors.textPrimary),
            fontWeight: FontWeight.w900,
            fontSize: emphasize ? 18 : 16,
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final Color backgroundColor;

  const _StatusPill({
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
