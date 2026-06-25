import 'package:flutter/material.dart';
import '../models/unit_data.dart';

class ConverterProvider extends ChangeNotifier {
  UnitCategory _selectedCategory = unitCategories[0];
  Unit _fromUnit = unitCategories[0].units[2]; // meter
  Unit _toUnit = unitCategories[0].units[1]; // centimeter
  String _inputValue = '';
  String _result = '';

  UnitCategory get selectedCategory => _selectedCategory;
  Unit get fromUnit => _fromUnit;
  Unit get toUnit => _toUnit;
  String get inputValue => _inputValue;
  String get result => _result;

  // Tip state
  final TipData tipData = TipData();
  String _tipSubtotal = '';
  String _tipPercent = '15';
  String _tipPeople = '1';

  String get tipSubtotal => _tipSubtotal;
  String get tipPercent => _tipPercent;
  String get tipPeople => _tipPeople;

  void setCategory(UnitCategory category) {
    _selectedCategory = category;
    if (category.units.isNotEmpty) {
      _fromUnit = category.units.first;
      _toUnit = category.units.length > 1 ? category.units[1] : category.units.first;
    }
    _inputValue = '';
    _result = '';
    notifyListeners();
  }

  void setFromUnit(Unit unit) {
    _fromUnit = unit;
    _convert();
    notifyListeners();
  }

  void setToUnit(Unit unit) {
    _toUnit = unit;
    _convert();
    notifyListeners();
  }

  void setInputValue(String value) {
    _inputValue = value;
    _convert();
    notifyListeners();
  }

  void swapUnits() {
    final temp = _fromUnit;
    _fromUnit = _toUnit;
    _toUnit = temp;
    _inputValue = _result;
    _convert();
    notifyListeners();
  }

  void _convert() {
    if (_inputValue.isEmpty) {
      _result = '';
      return;
    }
    final parsed = double.tryParse(_inputValue);
    if (parsed == null) {
      _result = 'Invalid';
      return;
    }
    try {
      final converted = _selectedCategory.convert(parsed, _fromUnit, _toUnit);
      _result = _formatResult(converted);
    } catch (_) {
      _result = 'Error';
    }
  }

  String _formatResult(double value) {
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value == 0) return '0';
    if (value.abs() < 1e-10) return '0';
    final str = value.toStringAsFixed(10);
    final trimmed = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return trimmed;
  }

  void setTipSubtotal(String value) {
    _tipSubtotal = value;
    tipData.subtotal = double.tryParse(value) ?? 0;
    _calculateTip();
    notifyListeners();
  }

  void setTipPercent(String value) {
    _tipPercent = value;
    tipData.tipPercent = double.tryParse(value) ?? 0;
    _calculateTip();
    notifyListeners();
  }

  void setTipPeople(String value) {
    _tipPeople = value;
    tipData.peopleCount = int.tryParse(value) ?? 1;
    _calculateTip();
    notifyListeners();
  }

  void _calculateTip() {
    notifyListeners();
  }
}
