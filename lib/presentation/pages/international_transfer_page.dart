import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_flag_helper.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/international_transfer_models.dart';
import '../../data/services/international_transfer_service.dart';
import 'p2p_history_page.dart';

// ── Receive method icon helper ────────────────────────────────────────────────

IconData _receiveMethodIcon(String code) {
  switch (code.toUpperCase()) {
    case 'BANK_ACCOUNT':
      return Icons.account_balance_rounded;
    case 'MOBILE_WALLET':
      return Icons.phone_android_rounded;
    case 'CASH':
      return Icons.payments_rounded;
    default:
      return Icons.more_horiz_rounded;
  }
}

// ── Amount formatter ──────────────────────────────────────────────────────────

String _fmtAmount(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$whole.${parts.last}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class InternationalTransferPage extends StatefulWidget {
  const InternationalTransferPage({super.key});

  @override
  State<InternationalTransferPage> createState() =>
      _InternationalTransferPageState();
}

class _InternationalTransferPageState
    extends State<InternationalTransferPage> {
  int _currentStep = 0;

  // Loading
  bool _loadingExchanges = true;
  bool _loadingProviders = false;
  bool _fetchingRate = false;
  bool _submitting = false;

  // Step 0 — Exchange & Provider
  List<ExchangeOption> _exchanges = [];
  ExchangeOption? _selectedExchange;
  List<ProviderOption> _providers = [];
  ProviderOption? _selectedProvider;

  // Step 1 — Amount & Currency
  String _sendCurrency = 'USD';
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  bool _isFormattingAmount = false;
  RateInfo? _rateInfo;
  Timer? _rateTimer;
  String? _rateError;

  // Step 1 — Focus nodes
  final _amountFocusNode = FocusNode();
  final _referenceFocusNode = FocusNode();

  // Step 2 — KYC
  final _senderCtrl = TextEditingController();
  final _receiverCtrl = TextEditingController();
  File? _kycFile;
  final _picker = ImagePicker();

  // Step 1 — Dynamic currencies per exchange
  List<CurrencyOption> _currencies = [];
  bool _loadingCurrencies = false;

  // Step 3 — Dynamic receive methods per exchange
  List<ReceiveMethodOption> _receiveMethods = [];
  bool _loadingReceiveMethods = false;
  String _receiveMethodCode = '';
  final _accountCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String en, String ar) => _isAr ? ar : en;

  @override
  void initState() {
    super.initState();
    _loadExchanges();
    _amountCtrl.addListener(_onAmountTyped);
    _amountFocusNode.addListener(() => setState(() {}));
    _referenceFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _rateTimer?.cancel();
    _amountCtrl
      ..removeListener(_onAmountTyped)
      ..dispose();
    _referenceCtrl.dispose();
    _senderCtrl.dispose();
    _receiverCtrl.dispose();
    _accountCtrl.dispose();
    _holderCtrl.dispose();
    _amountFocusNode.dispose();
    _referenceFocusNode.dispose();
    super.dispose();
  }

  // ── Amount formatting ─────────────────────────────────────────────────────

  void _onAmountTyped() {
    _formatAmount();
    setState(() {});
  }

  void _formatAmount() {
    if (_isFormattingAmount) return;
    final raw = _amountCtrl.text.replaceAll(',', '');
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
    if (formatted == _amountCtrl.text) return;
    _isFormattingAmount = true;
    _amountCtrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingAmount = false;
  }

  // ── Rate ─────────────────────────────────────────────────────────────────

  void _scheduleRateFetch() {
    _rateTimer?.cancel();
    if (_selectedExchange == null) return;
    _rateTimer =
        Timer(const Duration(milliseconds: 500), _fetchRate);
  }

  Future<void> _fetchRate() async {
    if (_selectedExchange == null) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    setState(() {
      _fetchingRate = true;
      _rateError = null;
    });
    final rate = await InternationalTransferService.getRate(
      exchangeCode: _selectedExchange!.code,
      sendCurrency: _sendCurrency,
      sendAmount: amount,
    );
    if (!mounted) return;
    setState(() {
      _rateInfo = rate;
      _rateError = rate == null
          ? _t(
              'Rate not available for this currency.',
              'السعر غير متاح لهذه العملة.',
            )
          : null;
      _fetchingRate = false;
    });
  }

  // ── Loaders ───────────────────────────────────────────────────────────────

  Future<void> _loadExchanges() async {
    setState(() => _loadingExchanges = true);
    final list = await InternationalTransferService.getExchanges();
    if (!mounted) return;
    setState(() {
      _exchanges = list;
      _loadingExchanges = false;
    });
  }

  Future<void> _loadExchangeData(String code) async {
    setState(() {
      _loadingProviders = true;
      _loadingCurrencies = true;
      _loadingReceiveMethods = true;
      _providers = [];
      _currencies = [];
      _receiveMethods = [];
      _selectedProvider = null;
      _sendCurrency = '';
      _receiveMethodCode = '';
      _rateInfo = null;
      _rateError = null;
    });

    final results = await Future.wait([
      InternationalTransferService.getProviders(code),
      InternationalTransferService.getCurrencies(code),
      InternationalTransferService.getReceiveMethods(code),
    ]);
    if (!mounted) return;

    final providers = results[0] as List<ProviderOption>;
    final currencies = results[1] as List<CurrencyOption>;
    final methods = results[2] as List<ReceiveMethodOption>;

    setState(() {
      _providers = providers;
      _currencies = currencies;
      _receiveMethods = methods;
      _loadingProviders = false;
      _loadingCurrencies = false;
      _loadingReceiveMethods = false;
      if (currencies.isNotEmpty) _sendCurrency = currencies.first.code;
      if (methods.isNotEmpty) _receiveMethodCode = methods.first.code;
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  double? get _sendAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', ''));

  bool _validate() {
    switch (_currentStep) {
      case 0:
        if (_selectedExchange == null) {
          _snack(_t('Choose an exchange first.', 'اختر دار صرافة أولاً.'));
          return false;
        }
        if (_selectedProvider == null) {
          _snack(_t(
              'Choose a transfer provider.', 'اختر جهة الحوالة.'));
          return false;
        }
        return true;
      case 1:
        final a = _sendAmount;
        if (a == null || a <= 0) {
          _snack(_t('Enter a valid amount.', 'أدخل مبلغاً صحيحاً.'));
          return false;
        }
        if (_rateInfo == null) {
          _snack(_t(
              'Rate unavailable. Choose a different currency.',
              'السعر غير متاح. اختر عملة أخرى.'));
          return false;
        }
        final p = _selectedProvider;
        if (p != null &&
            p.referenceRequired &&
            _referenceCtrl.text.trim().isEmpty) {
          _snack(_t(
              'Enter the reference number.', 'أدخل رقم المرجع.'));
          return false;
        }
        return true;
      case 2:
        if (_senderCtrl.text.trim().isEmpty ||
            _receiverCtrl.text.trim().isEmpty) {
          _snack(_t(
              'Enter sender and receiver names.',
              'أدخل اسمي المرسل والمستلم.'));
          return false;
        }
        return true;
      case 3:
        if (_receiveMethodCode.isEmpty) {
          _snack(_t('Choose a receive method.', 'اختر وسيلة الاستلام.'));
          return false;
        }
        if (_accountCtrl.text.trim().isEmpty ||
            _holderCtrl.text.trim().isEmpty) {
          _snack(
              _t('Complete receive details.', 'أكمل بيانات الاستلام.'));
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _continue() async {
    if (!_validate()) return;
    // Moving to step 1 — pre-fetch rate
    if (_currentStep == 0) {
      _fetchRate();
    }
    // Auto-fill holder from receiver
    if (_currentStep == 2 && _holderCtrl.text.trim().isEmpty) {
      _holderCtrl.text = _receiverCtrl.text.trim();
    }
    setState(() => _currentStep++);
  }

  void _appBarBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_validate()) return;
    final amount = _sendAmount;
    if (amount == null) return;

    setState(() => _submitting = true);
    try {
      final order = await InternationalTransferService.createOrder(
        IntlOrderRequest(
          exchangeCode: _selectedExchange!.code,
          providerCode: _selectedProvider!.code,
          providerReference: _referenceCtrl.text.trim().isNotEmpty
              ? _referenceCtrl.text.trim()
              : null,
          sendCurrencyCode: _sendCurrency,
          sendAmount: amount,
          senderName: _senderCtrl.text.trim(),
          receiverName: _receiverCtrl.text.trim(),
          receiveMethodCode: _receiveMethodCode,
          destinationAccountNumber: _accountCtrl.text.trim(),
          destinationAccountHolder: _holderCtrl.text.trim(),
        ),
      );

      if (order == null) {
        if (!mounted) return;
        setState(() => _submitting = false);
        _snack(_t(
            'Failed to submit. Please try again.',
            'فشل الإرسال. حاول مرة أخرى.'));
        return;
      }

      // Upload KYC document if provided
      if (_kycFile != null) {
        await InternationalTransferService.uploadAttachment(
          uuid: order.uuid,
          kind: 'KYC_DOCUMENT',
          file: _kycFile!,
        );
      }

      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(_t('An error occurred.', 'حدث خطأ.'));
    }
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _openExchangePicker() async {
    final picked = await showModalBottomSheet<ExchangeOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ApiExchangePickerSheet(
        title: _t('Choose exchange', 'إختر الصرافة'),
        exchanges: _exchanges,
        selectedCode: _selectedExchange?.code,
        isArabic: _isAr,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedExchange = picked;
    });
    await _loadExchangeData(picked.code);
  }

  Future<void> _openProviderPicker() async {
    if (_loadingProviders) return;
    final picked = await showModalBottomSheet<ProviderOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ApiProviderPickerSheet(
        title: _t('Transfer provider', 'جهة الحوالة'),
        providers: _providers,
        selectedCode: _selectedProvider?.code,
        isArabic: _isAr,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedProvider = picked);
  }

  Future<void> _openCurrencyPicker() async {
    if (_currencies.isEmpty) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CurrencyPickerSheet(
        title: _t('Currency', 'العملة'),
        currencies: _currencies,
        selectedCurrency: _sendCurrency,
        isArabic: _isAr,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _sendCurrency = picked;
      _rateInfo = null;
      _rateError = null;
    });
    _fetchRate();
  }

  Future<void> _openReceiveMethodPicker() async {
    if (_receiveMethods.isEmpty) return;
    final picked = await showModalBottomSheet<ReceiveMethodOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ReceiveMethodPickerSheet(
        title: _t('Receive method', 'وسيلة الاستلام'),
        methods: _receiveMethods,
        selectedCode: _receiveMethodCode,
        isArabic: _isAr,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _receiveMethodCode = picked.code);
  }

  Future<void> _pickKycDocument() async {
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _kycFile = File(file.path));
  }

  Future<void> _previewDocument(File file) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DocPreviewSheet(
        title: _t('ID document', 'وثيقة الهوية'),
        file: file,
        isArabic: _isAr,
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _fileName(File file) =>
      file.path.split(Platform.pathSeparator).last;

  CurrencyOption? get _selectedCurrency =>
      _currencies.isEmpty
          ? null
          : _currencies.firstWhere(
              (c) => c.code == _sendCurrency,
              orElse: () => _currencies.first,
            );

  ReceiveMethodOption? get _selectedReceiveMethod =>
      _receiveMethods.isEmpty
          ? null
          : _receiveMethods.firstWhere(
              (m) => m.code == _receiveMethodCode,
              orElse: () => _receiveMethods.first,
            );

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      child: _loadingExchanges
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : Scaffold(
              backgroundColor: const Color(0xFFF3F6F8),
              appBar: AppBar(
                leading: BackButton(onPressed: _appBarBack),
                title: Text(_t('International Transfer', 'التحويل الدولي')),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.receipt_long_rounded),
                    tooltip: _t('History', 'السجل'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const P2PHistoryPage()),
                    ),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: [
                  _IntlNumericStepper(
                      currentStep: _currentStep, isArabic: _isAr),
                  const SizedBox(height: 14),
                  if (_currentStep < 4)
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_buildStepBody()],
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
                      label: _t('Submit request', 'إرسال الطلب'),
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

  // ── Step 0: Exchange & Provider ───────────────────────────────────────────

  Widget _buildExchangeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.call_made_rounded,
          label: _t('Exchange house', 'دار الصرافة'),
        ),
        const SizedBox(height: 8),
        _IntlSelectorField(
          title: _selectedExchange == null
              ? _t('Choose exchange', 'إختر الصرافة')
              : _selectedExchange!.name,
          subtitle: null,
          isArabic: _isAr,
          leading: _ApiExchangeBadge(exchange: _selectedExchange),
          onTap: _openExchangePicker,
        ),
        const SizedBox(height: 16),
        _SectionLabel(
          icon: Icons.call_received_rounded,
          label: _t('Transfer provider', 'جهة الحوالة'),
        ),
        const SizedBox(height: 8),
        _loadingProviders
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _IntlSelectorField(
                title: _selectedExchange == null
                    ? _t('Choose exchange first', 'اختر الصرافة أولاً')
                    : _selectedProvider == null
                        ? _t('Choose provider', 'اختر المزود')
                        : _selectedProvider!.name,
                subtitle: _selectedProvider?.notes,
                isArabic: _isAr,
                leading:
                    _ApiProviderBadge(provider: _selectedProvider),
                onTap: _selectedExchange == null
                    ? () => _snack(_t(
                        'Choose an exchange first.',
                        'اختر الصرافة أولاً.'))
                    : _openProviderPicker,
              ),
      ],
    );
  }

  // ── Step 1: Amount & Currency ─────────────────────────────────────────────

  Widget _buildDetailsStep() {
    final provider = _selectedProvider;
    final showRef = provider != null &&
        (provider.referenceRequired ||
            (provider.referenceLabelEn?.isNotEmpty ?? false));
    final refLabel = _isAr
        ? (provider?.referenceLabelAr ?? 'رقم المرجع')
        : (provider?.referenceLabelEn ?? 'Reference number');
    final refHint = _isAr
        ? (provider?.referenceHelpAr ?? '')
        : (provider?.referenceHelpEn ?? '');

    final rate = _rateInfo;
    final receiveAmount = rate != null && _sendAmount != null
        ? _sendAmount! * rate.rate
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Reference field ─────────────────────────────────────────
        if (showRef) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _referenceFocusNode.hasFocus
                    ? AppColors.exchangeDark
                    : AppColors.borderSoft,
                width: _referenceFocusNode.hasFocus ? 1.5 : 1,
              ),
              boxShadow: AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    refLabel,
                    style: TextStyle(
                      color: _referenceFocusNode.hasFocus
                          ? AppColors.exchangeDark
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _referenceCtrl,
                    focusNode: _referenceFocusNode,
                    keyboardType: (provider?.fieldType == 'number')
                        ? TextInputType.number
                        : TextInputType.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: refHint.isNotEmpty
                          ? refHint
                          : _t('Enter value', 'أدخل القيمة'),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Amount + Currency card ──────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _amountFocusNode.hasFocus
                  ? AppColors.exchangeDark
                  : AppColors.borderSoft,
              width: _amountFocusNode.hasFocus ? 1.5 : 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Send amount', 'مبلغ الإرسال'),
                      style: TextStyle(
                        color: _amountFocusNode.hasFocus
                            ? AppColors.exchangeDark
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountCtrl,
                      focusNode: _amountFocusNode,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textHint,
                          height: 1.1,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: _amountFocusNode.hasFocus
                    ? AppColors.exchangeDark.withOpacity(0.2)
                    : AppColors.borderSoft,
              ),
              _loadingCurrencies
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : InkWell(
                      onTap: _currencies.isEmpty ? null : _openCurrencyPicker,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            _CurrencyBadge(
                                currency: _sendCurrency.isEmpty
                                    ? null
                                    : _sendCurrency),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _sendCurrency.isEmpty
                                    ? _t('Choose currency', 'اختر العملة')
                                    : (_selectedCurrency?.name(_isAr) ??
                                        _sendCurrency),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _sendCurrency.isEmpty
                                      ? AppColors.textHint
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),

        // ── Rate result ─────────────────────────────────────────────
        const SizedBox(height: 12),
        if (_fetchingRate)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppShadows.card,
            ),
            child:
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_rateError != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _rateError!,
                    style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else if (rate != null)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.exchangeDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '1 $_sendCurrency = ${_fmtAmount(rate.rate)} ${rate.receiveCurrencyCode}',
                      style: const TextStyle(
                        color: AppColors.exchangeDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderSoft),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Estimated payout', 'الصرف المتوقع'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        receiveAmount == null
                            ? '--'
                            : '${_fmtAmount(receiveAmount)} ${rate.receiveCurrencyCode}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Step 2: KYC ───────────────────────────────────────────────────────────

  Widget _buildKycStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _senderCtrl,
          decoration: InputDecoration(
            labelText: _t('Sender full name', 'الاسم الكامل للمرسل'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _receiverCtrl,
          decoration: InputDecoration(
            labelText:
                _t('Receiver full name', 'الاسم الكامل للمستلم'),
          ),
        ),
        const SizedBox(height: 16),
        _UploadDocumentCard(
          title: _t('ID document', 'وثيقة الهوية'),
          subtitle: _t(
            'Passport or national ID (optional)',
            'جواز السفر أو الهوية الوطنية (اختياري)',
          ),
          fileName: _kycFile == null ? null : _fileName(_kycFile!),
          previewFile: _kycFile,
          onPreview: _kycFile == null
              ? null
              : () => _previewDocument(_kycFile!),
          onTap: _pickKycDocument,
        ),
      ],
    );
  }

  // ── Step 3: Receive ───────────────────────────────────────────────────────

  Widget _buildReceiveStep() {
    final method = _selectedReceiveMethod;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.account_balance_rounded,
          label: _t('Receive method', 'وسيلة الاستلام'),
        ),
        const SizedBox(height: 8),
        _loadingReceiveMethods
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _IntlSelectorField(
                title: method?.name(_isAr) ??
                    _t('Choose method', 'اختر الطريقة'),
                subtitle: null,
                isArabic: _isAr,
                leading: _ReceiveMethodBadge(method: method),
                onTap: _receiveMethods.isEmpty ? null : _openReceiveMethodPicker,
              ),
        const SizedBox(height: 14),
        TextField(
          controller: _accountCtrl,
          decoration: InputDecoration(
            labelText: _t('Account number', 'رقم الحساب'),
            hintText: _t(
                'Bank / IBAN / Wallet number',
                'رقم البنك / الآيبان / المحفظة'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _holderCtrl,
          decoration: InputDecoration(
            labelText:
                _t('Account holder name', 'اسم صاحب الحساب'),
            hintText: _t(
              'Defaults to receiver name',
              'يتم تعبئته باسم المستلم افتراضياً',
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 4: Review ────────────────────────────────────────────────────────

  Widget _buildReviewStep() {
    final rate = _rateInfo;
    final amount = _sendAmount ?? 0;
    final receiveAmount =
        rate != null ? amount * rate.rate : null;
    final method = _selectedReceiveMethod;
    final provider = _selectedProvider;
    final showRef = _referenceCtrl.text.trim().isNotEmpty;
    final methodName = method?.name(_isAr) ?? _receiveMethodCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IntlReviewSection(
          title: _t('Transfer summary', 'ملخص التحويل'),
          icon: Icons.receipt_long_rounded,
          child: Column(
            children: [
              _KeyValueRow(
                label: _t('Exchange', 'دار الصرافة'),
                value: _selectedExchange?.name ?? '-',
              ),
              _KeyValueRow(
                label: _t('Provider', 'جهة الحوالة'),
                value: provider?.name ?? '-',
              ),
              _KeyValueRow(
                label: _t('Send currency', 'عملة الإرسال'),
                value: _sendCurrency,
              ),
              _KeyValueRow(
                label: _t('Transfer amount', 'مبلغ التحويل'),
                value: '${_fmtAmount(amount)} $_sendCurrency',
              ),
              if (rate != null) ...[
                _KeyValueRow(
                  label: _t('Rate', 'السعر'),
                  value:
                      '1 $_sendCurrency = ${_fmtAmount(rate.rate)} ${rate.receiveCurrencyCode}',
                ),
                _KeyValueRow(
                  label: _t('Received amount', 'المبلغ المستلم'),
                  value: receiveAmount != null
                      ? '${_fmtAmount(receiveAmount)} ${rate.receiveCurrencyCode}'
                      : '--',
                ),
              ],
              if (showRef)
                _KeyValueRow(
                  label: _isAr
                      ? (provider?.referenceLabelAr ?? 'المرجع')
                      : (provider?.referenceLabelEn ?? 'Reference'),
                  value: _referenceCtrl.text.trim(),
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
                value: methodName,
              ),
              _KeyValueRow(
                label: _t('Account number', 'رقم الحساب'),
                value: _accountCtrl.text.trim(),
              ),
              _KeyValueRow(
                label: _t('Account holder', 'صاحب الحساب'),
                value: _holderCtrl.text.trim(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _IntlReviewSection(
          title: _t('Customer', 'العميل'),
          icon: Icons.badge_outlined,
          child: Column(
            children: [
              _KeyValueRow(
                label: _t('Sender', 'المرسل'),
                value: _senderCtrl.text.trim(),
              ),
              _KeyValueRow(
                label: _t('Receiver', 'المستلم'),
                value: _receiverCtrl.text.trim(),
              ),
              if (_kycFile != null)
                _IntlDocumentRow(
                  label: _t('ID document', 'وثيقة الهوية'),
                  value: _fileName(_kycFile!),
                  previewFile: _kycFile,
                  onTapPreview: () => _previewDocument(_kycFile!),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ApiExchangeBadge extends StatelessWidget {
  final ExchangeOption? exchange;
  const _ApiExchangeBadge({required this.exchange});

  @override
  Widget build(BuildContext context) {
    return _LogoBadge(
      logoUrl: exchange?.logoUrl,
      size: 40,
      borderRadius: 14,
      borderColor: const Color(0xFFD7E2E6),
      padding: 6,
    );
  }
}

class _ApiProviderBadge extends StatelessWidget {
  final ProviderOption? provider;
  const _ApiProviderBadge({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _LogoBadge(
      logoUrl: provider?.logoUrl,
      size: 38,
      borderRadius: 12,
      borderColor: const Color(0xFFD5E3FF),
      padding: 6,
    );
  }
}

class _CurrencyBadge extends StatelessWidget {
  final String? currency;
  const _CurrencyBadge({required this.currency});

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
          ? const Icon(Icons.attach_money_rounded,
              color: Color(0xFFB16A00), size: 18)
          : Text(flag, style: const TextStyle(fontSize: 18)),
    );
  }
}

class _ReceiveMethodBadge extends StatelessWidget {
  final ReceiveMethodOption? method;
  const _ReceiveMethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    if (method?.logoUrl != null) {
      return _LogoBadge(
        logoUrl: method!.logoUrl,
        size: 38,
        borderRadius: 12,
        borderColor: const Color(0xFFD7E8E6),
        padding: 6,
      );
    }
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.exchangeDark.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        method != null
            ? _receiveMethodIcon(method!.code)
            : Icons.more_horiz_rounded,
        color: AppColors.exchangeDark,
        size: 20,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Picker sheets
// ─────────────────────────────────────────────────────────────────────────────

class _ApiExchangePickerSheet extends StatelessWidget {
  final String title;
  final List<ExchangeOption> exchanges;
  final String? selectedCode;
  final bool isArabic;

  const _ApiExchangePickerSheet({
    required this.title,
    required this.exchanges,
    required this.selectedCode,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerSheet(
      title: title,
      children: exchanges.map(
        (ex) => _IntlSheetTile(
          isArabic: isArabic,
          selected: ex.code == selectedCode,
          leading: _ApiExchangeBadge(exchange: ex),
          title: ex.name,
          onTap: () => Navigator.of(context).pop(ex),
        ),
      ),
    );
  }
}

class _ApiProviderPickerSheet extends StatelessWidget {
  final String title;
  final List<ProviderOption> providers;
  final String? selectedCode;
  final bool isArabic;

  const _ApiProviderPickerSheet({
    required this.title,
    required this.providers,
    required this.selectedCode,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerSheet(
      title: title,
      children: providers.map(
        (p) => _IntlSheetTile(
          isArabic: isArabic,
          selected: p.code == selectedCode,
          leading: _ApiProviderBadge(provider: p),
          title: p.name,
          subtitle: p.notes,
          onTap: () => Navigator.of(context).pop(p),
        ),
      ),
    );
  }
}

class _CurrencyPickerSheet extends StatelessWidget {
  final String title;
  final List<CurrencyOption> currencies;
  final String? selectedCurrency;
  final bool isArabic;

  const _CurrencyPickerSheet({
    required this.title,
    required this.currencies,
    required this.selectedCurrency,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerSheet(
      title: title,
      children: currencies.map(
        (c) => _IntlSheetTile(
          isArabic: isArabic,
          selected: c.code == selectedCurrency,
          leading: _CurrencyBadge(currency: c.code),
          title: c.name(isArabic),
          onTap: () => Navigator.of(context).pop(c.code),
        ),
      ),
    );
  }
}

class _ReceiveMethodPickerSheet extends StatelessWidget {
  final String title;
  final List<ReceiveMethodOption> methods;
  final String selectedCode;
  final bool isArabic;

  const _ReceiveMethodPickerSheet({
    required this.title,
    required this.methods,
    required this.selectedCode,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerSheet(
      title: title,
      children: methods.map(
        (m) => _IntlSheetTile(
          isArabic: isArabic,
          selected: m.code == selectedCode,
          leading: _ReceiveMethodBadge(method: m),
          title: m.name(isArabic),
          onTap: () => Navigator.of(context).pop(m),
        ),
      ),
    );
  }
}

// Common sheet wrapper
class _PickerSheet extends StatelessWidget {
  final String title;
  final Iterable<Widget> children;

  const _PickerSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DBE0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
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
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textSecondary,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F5F7),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1, color: Color(0xFFF0F2F5)),
            // ── Items ──
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                shrinkWrap: true,
                children: [...children],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI widgets (same design as p2p_exchange_page)
// ─────────────────────────────────────────────────────────────────────────────

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

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

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

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({required this.label, required this.value});

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

class _IntlNumericStepper extends StatelessWidget {
  final int currentStep;
  final bool isArabic;

  const _IntlNumericStepper({
    required this.currentStep,
    required this.isArabic,
  });

  String _t(String en, String ar) => isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final labels = [
      _t('Exchange', 'الصرافة'),
      _t('Details', 'التفاصيل'),
      _t('KYC', 'الهوية'),
      _t('Receive', 'الاستلام'),
      _t('Review', 'المراجعة'),
    ];
    final total = labels.length;
    final progress = (currentStep + 1) / total;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Step counter + label ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.exchangeDark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${currentStep + 1}/$total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.exchangeDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  labels[currentStep],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Segmented bar ──
          Row(
            children: List.generate(total, (i) {
              final done = i < currentStep;
              final active = i == currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: done ? 1.0 : active ? 0.45 : 0.0,
                    ),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (_, fill, __) => Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: const Color(0xFFE4E9EE),
                      ),
                      alignment: isArabic
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: fill,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            color: AppColors.exchangeDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _IntlSelectorField extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget leading;
  final bool isArabic;
  final VoidCallback? onTap;

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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          textDirection:
              isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                    textAlign:
                        isArabic ? TextAlign.right : TextAlign.left,
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
                      textAlign:
                          isArabic ? TextAlign.right : TextAlign.left,
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
            _DocThumbnail(file: previewFile!, onTap: onTapPreview, size: 42)
          else
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.exchangeDark.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.description_outlined,
                  size: 18, color: AppColors.exchangeDark),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (onTapPreview != null) ...[
            const SizedBox(width: 8),
            const Text('Preview',
                style: TextStyle(
                    color: AppColors.exchangeDark,
                    fontWeight: FontWeight.w800)),
          ],
        ],
      ),
    );

    return onTapPreview == null
        ? content
        : InkWell(
            onTap: onTapPreview,
            borderRadius: BorderRadius.circular(14),
            child: content,
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
              _DocThumbnail(file: previewFile!, onTap: onPreview, size: 52)
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.exchangeDark.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.upload_file_rounded,
                    color: AppColors.exchangeDark),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fileName ?? title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.35)),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (previewFile != null && onPreview != null) ...[
                  GestureDetector(
                    onTap: onPreview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.exchangeDark.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('Preview',
                          style: TextStyle(
                              color: AppColors.exchangeDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DocThumbnail extends StatelessWidget {
  final File file;
  final VoidCallback? onTap;
  final double size;

  const _DocThumbnail(
      {required this.file, this.onTap, this.size = 48});

  @override
  Widget build(BuildContext context) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(file,
                width: size, height: size, fit: BoxFit.cover),
          ),
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
                    child: const Icon(Icons.zoom_in_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocPreviewSheet extends StatelessWidget {
  final String title;
  final File file;
  final bool isArabic;

  const _DocPreviewSheet({
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DBE0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  textDirection: isArabic
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppColors.textSecondary,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF2F5F7),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1, color: Color(0xFFF0F2F5)),
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
                        child: Image.file(file,
                            fit: BoxFit.contain,
                            width: double.infinity),
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

class _IntlSheetTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool isArabic;
  final VoidCallback onTap;

  const _IntlSheetTile({
    required this.title,
    required this.selected,
    required this.isArabic,
    required this.onTap,
    this.leading,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasLeading = leading != null && leading is! SizedBox;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.exchangeDark.withOpacity(0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColors.exchangeDark.withOpacity(0.30)
                    : const Color(0xFFECEFF3),
              ),
            ),
            child: Row(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              children: [
                if (hasLeading) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: isArabic
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 14,
                          color: selected ? AppColors.exchangeDark : AppColors.textPrimary,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: selected
                      ? const Icon(Icons.check_circle_rounded,
                          key: ValueKey('checked'),
                          color: AppColors.exchangeDark, size: 20)
                      : const Icon(Icons.radio_button_unchecked_rounded,
                          key: ValueKey('unchecked'),
                          color: Color(0xFFCDD3DA), size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
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
      child: Image.asset('assets/images/app_icon.png',
          fit: BoxFit.contain),
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
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}
