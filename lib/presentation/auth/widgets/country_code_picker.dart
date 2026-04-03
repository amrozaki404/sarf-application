import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CountryItem {
  final String name;
  final String code;
  final String flag;

  const CountryItem({required this.name, required this.code, required this.flag});
}

const List<CountryItem> kCountries = [
  CountryItem(name: 'Sudan', code: '249', flag: '🇸🇩'),
  CountryItem(name: 'Saudi Arabia', code: '966', flag: '🇸🇦'),
  CountryItem(name: 'Egypt', code: '20', flag: '🇪🇬'),
];

class CountryCodePicker extends StatefulWidget {
  final TextEditingController controller;

  const CountryCodePicker({super.key, required this.controller});

  @override
  State<CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  late CountryItem _selected;

  @override
  void initState() {
    super.initState();
    // Default to Sudan (249)
    _selected = kCountries.firstWhere(
      (c) => c.code == widget.controller.text,
      orElse: () => kCountries.first,
    );
    widget.controller.text = _selected.code;
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Country',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...kCountries.map((c) => ListTile(
                  leading: Text(c.flag, style: const TextStyle(fontSize: 26)),
                  title: Text(c.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                  trailing: Text('+${c.code}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                  selected: _selected.code == c.code,
                  selectedColor: AppColors.primary,
                  selectedTileColor: AppColors.primary.withOpacity(0.06),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    setState(() {
                      _selected = c;
                      widget.controller.text = c.code;
                    });
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPicker,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selected.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text('+${_selected.code}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
