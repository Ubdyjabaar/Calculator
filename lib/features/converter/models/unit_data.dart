import 'package:flutter/material.dart';

class Unit {
  final String name;
  final String abbreviation;
  final double Function(double) toBase;
  final double Function(double) fromBase;

  const Unit({
    required this.name,
    required this.abbreviation,
    required this.toBase,
    required this.fromBase,
  });
}

class UnitCategory {
  final String name;
  final IconData icon;
  final String baseUnitName;
  final List<Unit> units;

  const UnitCategory({
    required this.name,
    required this.icon,
    required this.baseUnitName,
    required this.units,
  });

  double convert(double value, Unit from, Unit to) {
    final baseValue = from.toBase(value);
    return to.fromBase(baseValue);
  }
}

class TipData {
  double subtotal = 0;
  double tipPercent = 15;
  int peopleCount = 1;

  double get tipAmount => subtotal * tipPercent / 100;
  double get total => subtotal + tipAmount;
  double get perPerson => total / peopleCount;
}

final List<UnitCategory> unitCategories = [
  UnitCategory(
    name: 'Length',
    icon: Icons.straighten,
    baseUnitName: 'meters',
    units: const [
      Unit(name: 'Millimeter', abbreviation: 'mm', toBase: _mmToM, fromBase: _mToMm),
      Unit(name: 'Centimeter', abbreviation: 'cm', toBase: _cmToM, fromBase: _mToCm),
      Unit(name: 'Meter', abbreviation: 'm', toBase: _id, fromBase: _id),
      Unit(name: 'Kilometer', abbreviation: 'km', toBase: _kmToM, fromBase: _mToKm),
      Unit(name: 'Inch', abbreviation: 'in', toBase: _inToM, fromBase: _mToIn),
      Unit(name: 'Foot', abbreviation: 'ft', toBase: _ftToM, fromBase: _mToFt),
      Unit(name: 'Yard', abbreviation: 'yd', toBase: _ydToM, fromBase: _mToYd),
      Unit(name: 'Mile', abbreviation: 'mi', toBase: _miToM, fromBase: _mToMi),
      Unit(name: 'Nautical Mile', abbreviation: 'NM', toBase: _nmToM, fromBase: _mToNm),
      Unit(name: 'Mil', abbreviation: 'mil', toBase: _milToM, fromBase: _mToMil),
    ],
  ),
  UnitCategory(
    name: 'Area',
    icon: Icons.square_foot,
    baseUnitName: 'sq meters',
    units: const [
      Unit(name: 'Acre', abbreviation: 'ac', toBase: _acToSqm, fromBase: _sqmToAc),
      Unit(name: 'Are', abbreviation: 'a', toBase: _areToSqm, fromBase: _sqmToAre),
      Unit(name: 'Hectare', abbreviation: 'ha', toBase: _haToSqm, fromBase: _sqmToHa),
      Unit(name: 'Square Centimeter', abbreviation: 'cm²', toBase: _sqcmToSqm, fromBase: _sqmToSqcm),
      Unit(name: 'Square Foot', abbreviation: 'ft²', toBase: _sqftToSqm, fromBase: _sqmToSqft),
      Unit(name: 'Square Inch', abbreviation: 'in²', toBase: _sqinToSqm, fromBase: _sqmToSqin),
      Unit(name: 'Square Meter', abbreviation: 'm²', toBase: _id, fromBase: _id),
    ],
  ),
  UnitCategory(
    name: 'Temperature',
    icon: Icons.thermostat,
    baseUnitName: '°C',
    units: const [
      Unit(name: 'Celsius', abbreviation: '°C', toBase: _id, fromBase: _id),
      Unit(name: 'Fahrenheit', abbreviation: '°F', toBase: _fToC, fromBase: _cToF),
      Unit(name: 'Kelvin', abbreviation: 'K', toBase: _kToC, fromBase: _cToK),
    ],
  ),
  UnitCategory(
    name: 'Volume',
    icon: Icons.water_drop,
    baseUnitName: 'liters',
    units: const [
      Unit(name: 'UK Gallon', abbreviation: 'UK gal', toBase: _ukgalToL, fromBase: _lToUkgal),
      Unit(name: 'US Gallon', abbreviation: 'US gal', toBase: _usgalToL, fromBase: _lToUsgal),
      Unit(name: 'Liter', abbreviation: 'L', toBase: _id, fromBase: _id),
      Unit(name: 'Milliliter', abbreviation: 'mL', toBase: _mlToL, fromBase: _lToMl),
      Unit(name: 'Cubic Centimeter', abbreviation: 'cc/cm³', toBase: _ccToL, fromBase: _lToCc),
      Unit(name: 'Cubic Meter', abbreviation: 'm³', toBase: _cumToL, fromBase: _lToCum),
      Unit(name: 'Cubic Inch', abbreviation: 'in³', toBase: _cuinToL, fromBase: _lToCuin),
      Unit(name: 'Cubic Foot', abbreviation: 'ft³', toBase: _cuftToL, fromBase: _lToCuft),
    ],
  ),
  UnitCategory(
    name: 'Mass',
    icon: Icons.monitor_weight,
    baseUnitName: 'kilograms',
    units: const [
      Unit(name: 'Metric Ton', abbreviation: 't', toBase: _tonToKg, fromBase: _kgToTon),
      Unit(name: 'UK Ton', abbreviation: 'UK t', toBase: _uktonToKg, fromBase: _kgToUkton),
      Unit(name: 'US Ton', abbreviation: 'US t', toBase: _ustonToKg, fromBase: _kgToUston),
      Unit(name: 'Pound', abbreviation: 'lb', toBase: _lbToKg, fromBase: _kgToLb),
      Unit(name: 'Ounce', abbreviation: 'oz', toBase: _ozToKg, fromBase: _kgToOz),
      Unit(name: 'Kilogram', abbreviation: 'kg', toBase: _id, fromBase: _id),
      Unit(name: 'Gram', abbreviation: 'g', toBase: _gToKg, fromBase: _kgToG),
    ],
  ),
  UnitCategory(
    name: 'Data',
    icon: Icons.storage,
    baseUnitName: 'bytes',
    units: const [
      Unit(name: 'Bit', abbreviation: 'bit', toBase: _bitToB, fromBase: _bToBit),
      Unit(name: 'Byte', abbreviation: 'B', toBase: _id, fromBase: _id),
      Unit(name: 'Kilobyte', abbreviation: 'KB', toBase: _kbToB, fromBase: _bToKb),
      Unit(name: 'Kibibyte', abbreviation: 'KiB', toBase: _kibToB, fromBase: _bToKib),
      Unit(name: 'Megabyte', abbreviation: 'MB', toBase: _mbToB, fromBase: _bToMb),
      Unit(name: 'Mebibyte', abbreviation: 'MiB', toBase: _mibToB, fromBase: _bToMib),
      Unit(name: 'Gigabyte', abbreviation: 'GB', toBase: _gbToB, fromBase: _bToGb),
      Unit(name: 'Gibibyte', abbreviation: 'GiB', toBase: _gibToB, fromBase: _bToGib),
      Unit(name: 'Terabyte', abbreviation: 'TB', toBase: _tbToB, fromBase: _bToTb),
      Unit(name: 'Tebibyte', abbreviation: 'TiB', toBase: _tibToB, fromBase: _bToTib),
    ],
  ),
  UnitCategory(
    name: 'Speed',
    icon: Icons.speed,
    baseUnitName: 'm/s',
    units: const [
      Unit(name: 'Meter/Second', abbreviation: 'm/s', toBase: _id, fromBase: _id),
      Unit(name: 'Meter/Hour', abbreviation: 'm/h', toBase: _mhToMs, fromBase: _msToMh),
      Unit(name: 'Kilometer/Second', abbreviation: 'km/s', toBase: _kmsToMs, fromBase: _msToKms),
      Unit(name: 'Inch/Second', abbreviation: 'in/s', toBase: _insToMs, fromBase: _msToIns),
      Unit(name: 'Inch/Hour', abbreviation: 'in/h', toBase: _inhToMs, fromBase: _msToInh),
      Unit(name: 'Foot/Hour', abbreviation: 'ft/h', toBase: _fthToMs, fromBase: _msToFth),
      Unit(name: 'Mile/Second', abbreviation: 'mi/s', toBase: _misToMs, fromBase: _msToMis),
      Unit(name: 'Mile/Hour', abbreviation: 'mi/h', toBase: _mihToMs, fromBase: _msToMih),
      Unit(name: 'Knot', abbreviation: 'kn', toBase: _knToMs, fromBase: _msToKn),
    ],
  ),
  UnitCategory(
    name: 'Time',
    icon: Icons.timer,
    baseUnitName: 'seconds',
    units: const [
      Unit(name: 'Millisecond', abbreviation: 'ms', toBase: _msToS, fromBase: _sToMs),
      Unit(name: 'Second', abbreviation: 's', toBase: _id, fromBase: _id),
      Unit(name: 'Minute', abbreviation: 'min', toBase: _minToS, fromBase: _sToMin),
      Unit(name: 'Hour', abbreviation: 'h', toBase: _hToS, fromBase: _sToH),
      Unit(name: 'Day', abbreviation: 'd', toBase: _dToS, fromBase: _sToD),
      Unit(name: 'Week', abbreviation: 'wk', toBase: _wkToS, fromBase: _sToWk),
    ],
  ),
];

// --- Conversion helpers ---

double _id(double v) => v;

// Length (base: meter)
double _mmToM(double v) => v / 1000;
double _mToMm(double v) => v * 1000;
double _cmToM(double v) => v / 100;
double _mToCm(double v) => v * 100;
double _kmToM(double v) => v * 1000;
double _mToKm(double v) => v / 1000;
double _inToM(double v) => v * 0.0254;
double _mToIn(double v) => v / 0.0254;
double _ftToM(double v) => v * 0.3048;
double _mToFt(double v) => v / 0.3048;
double _ydToM(double v) => v * 0.9144;
double _mToYd(double v) => v / 0.9144;
double _miToM(double v) => v * 1609.344;
double _mToMi(double v) => v / 1609.344;
double _nmToM(double v) => v * 1852;
double _mToNm(double v) => v / 1852;
double _milToM(double v) => v * 0.0000254;
double _mToMil(double v) => v / 0.0000254;

// Area (base: sq meter)
double _acToSqm(double v) => v * 4046.856;
double _sqmToAc(double v) => v / 4046.856;
double _areToSqm(double v) => v * 100;
double _sqmToAre(double v) => v / 100;
double _haToSqm(double v) => v * 10000;
double _sqmToHa(double v) => v / 10000;
double _sqcmToSqm(double v) => v / 10000;
double _sqmToSqcm(double v) => v * 10000;
double _sqftToSqm(double v) => v * 0.092903;
double _sqmToSqft(double v) => v / 0.092903;
double _sqinToSqm(double v) => v * 0.00064516;
double _sqmToSqin(double v) => v / 0.00064516;

// Temperature (base: Celsius)
double _fToC(double v) => (v - 32) * 5 / 9;
double _cToF(double v) => v * 9 / 5 + 32;
double _kToC(double v) => v - 273.15;
double _cToK(double v) => v + 273.15;

// Volume (base: liter)
double _ukgalToL(double v) => v * 4.54609;
double _lToUkgal(double v) => v / 4.54609;
double _usgalToL(double v) => v * 3.78541;
double _lToUsgal(double v) => v / 3.78541;
double _mlToL(double v) => v / 1000;
double _lToMl(double v) => v * 1000;
double _ccToL(double v) => v / 1000;
double _lToCc(double v) => v * 1000;
double _cumToL(double v) => v * 1000;
double _lToCum(double v) => v / 1000;
double _cuinToL(double v) => v * 0.0163871;
double _lToCuin(double v) => v / 0.0163871;
double _cuftToL(double v) => v * 28.3168;
double _lToCuft(double v) => v / 28.3168;

// Mass (base: kilogram)
double _tonToKg(double v) => v * 1000;
double _kgToTon(double v) => v / 1000;
double _uktonToKg(double v) => v * 1016.047;
double _kgToUkton(double v) => v / 1016.047;
double _ustonToKg(double v) => v * 907.185;
double _kgToUston(double v) => v / 907.185;
double _lbToKg(double v) => v * 0.453592;
double _kgToLb(double v) => v / 0.453592;
double _ozToKg(double v) => v * 0.0283495;
double _kgToOz(double v) => v / 0.0283495;
double _gToKg(double v) => v / 1000;
double _kgToG(double v) => v * 1000;

// Data (base: byte)
double _bitToB(double v) => v / 8;
double _bToBit(double v) => v * 8;
double _kbToB(double v) => v * 1000;
double _bToKb(double v) => v / 1000;
double _kibToB(double v) => v * 1024;
double _bToKib(double v) => v / 1024;
double _mbToB(double v) => v * 1e6;
double _bToMb(double v) => v / 1e6;
double _mibToB(double v) => v * 1048576;
double _bToMib(double v) => v / 1048576;
double _gbToB(double v) => v * 1e9;
double _bToGb(double v) => v / 1e9;
double _gibToB(double v) => v * 1073741824;
double _bToGib(double v) => v / 1073741824;
double _tbToB(double v) => v * 1e12;
double _bToTb(double v) => v / 1e12;
double _tibToB(double v) => v * 1099511627776;
double _bToTib(double v) => v / 1099511627776;

// Speed (base: m/s)
double _mhToMs(double v) => v / 3600;
double _msToMh(double v) => v * 3600;
double _kmsToMs(double v) => v * 1000;
double _msToKms(double v) => v / 1000;
double _insToMs(double v) => v * 0.0254;
double _msToIns(double v) => v / 0.0254;
double _inhToMs(double v) => v * 0.0254 / 3600;
double _msToInh(double v) => v / 0.0254 * 3600;
double _fthToMs(double v) => v * 0.3048 / 3600;
double _msToFth(double v) => v / 0.3048 * 3600;
double _misToMs(double v) => v * 1609.344;
double _msToMis(double v) => v / 1609.344;
double _mihToMs(double v) => v * 1609.344 / 3600;
double _msToMih(double v) => v / 1609.344 * 3600;
double _knToMs(double v) => v * 0.514444;
double _msToKn(double v) => v / 0.514444;

// Time (base: second)
double _msToS(double v) => v / 1000;
double _sToMs(double v) => v * 1000;
double _minToS(double v) => v * 60;
double _sToMin(double v) => v / 60;
double _hToS(double v) => v * 3600;
double _sToH(double v) => v / 3600;
double _dToS(double v) => v * 86400;
double _sToD(double v) => v / 86400;
double _wkToS(double v) => v * 604800;
double _sToWk(double v) => v / 604800;
