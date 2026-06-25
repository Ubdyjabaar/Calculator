import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/converter_provider.dart';
import '../models/unit_data.dart';
import '../../../shared/widgets/glass_container.dart';

class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        children: [
          const _CategoryBar(),
          const SizedBox(height: 8),
          Expanded(
            child: Selector<ConverterProvider, UnitCategory>(
              selector: (_, p) => p.selectedCategory,
              builder: (context, cat, _) {
                if (cat.name == 'Tip') {
                  return const _TipCalculator();
                }
                return _UnitConverter(key: ValueKey(cat.name));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar();

  @override
  Widget build(BuildContext context) {
    final allCategories = [
      ...unitCategories,
      const UnitCategory(
        name: 'Tip',
        icon: Icons.receipt_long,
        baseUnitName: '',
        units: [],
      ),
    ];
    final selected = context.watch<ConverterProvider>().selectedCategory;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final cat = allCategories[i];
          final isSelected = cat.name == selected.name;
          return GestureDetector(
            onTap: () => context.read<ConverterProvider>().setCategory(cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon, size: 14,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null),
                  const SizedBox(width: 5),
                  Text(cat.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UnitConverter extends StatefulWidget {
  const _UnitConverter({super.key});

  @override
  State<_UnitConverter> createState() => _UnitConverterState();
}

class _UnitConverterState extends State<_UnitConverter> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Selector<ConverterProvider, UnitCategory>(
              selector: (_, p) => p.selectedCategory,
              builder: (context, cat, _) {
                final prov = context.read<ConverterProvider>();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _UnitDropdown(
                      label: 'From',
                      value: prov.fromUnit,
                      units: cat.units,
                      onChanged: (u) {
                        if (u != null) prov.setFromUnit(u);
                      },
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.swap_vert, size: 22),
                        onPressed: () => prov.swapUnits(),
                        tooltip: 'Swap units',
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                          foregroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _UnitDropdown(
                      label: 'To',
                      value: prov.toUnit,
                      units: cat.units,
                      onChanged: (u) {
                        if (u != null) prov.setToUnit(u);
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Enter value',
                  border: InputBorder.none,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
                style: TextStyle(
                  fontSize: 22,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                onChanged: (v) => context.read<ConverterProvider>().setInputValue(v),
              ),
            ),
            const SizedBox(height: 12),
            Selector<ConverterProvider, _ConverterResult>(
              selector: (_, p) => _ConverterResult(p.result, p.toUnit.abbreviation),
              builder: (context, data, _) {
                final theme = Theme.of(context);
                return GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.result.isEmpty ? '0' : data.result,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: data.result.isNotEmpty
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        data.abbreviation,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConverterResult {
  final String result;
  final String abbreviation;
  const _ConverterResult(this.result, this.abbreviation);
}

class _UnitDropdown extends StatelessWidget {
  final String label;
  final Unit value;
  final List<Unit> units;
  final ValueChanged<Unit?> onChanged;

  const _UnitDropdown({
    required this.label,
    required this.value,
    required this.units,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Unit>(
          value: value,
          isExpanded: true,
          dropdownColor: theme.colorScheme.surface,
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          items: units.map((u) {
            return DropdownMenuItem(
              value: u,
              child: Text('${u.name} (${u.abbreviation})'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TipCalculator extends StatefulWidget {
  const _TipCalculator();

  @override
  State<_TipCalculator> createState() => _TipCalculatorState();
}

class _TipCalculatorState extends State<_TipCalculator> {
  final _subtotalCtrl = TextEditingController();
  final _tipCtrl = TextEditingController(text: '15');
  final _peopleCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _subtotalCtrl.dispose();
    _tipCtrl.dispose();
    _peopleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ConverterProvider>();
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildField('Subtotal (\$)', _subtotalCtrl, prov.setTipSubtotal),
            const SizedBox(height: 10),
            _buildField('Tip %', _tipCtrl, prov.setTipPercent),
            const SizedBox(height: 10),
            _buildField('People', _peopleCtrl, prov.setTipPeople),
            const SizedBox(height: 16),
            _resultRow(context, 'Tip Amount', prov.tipData.tipAmount, theme),
            const SizedBox(height: 8),
            _resultRow(context, 'Total', prov.tipData.total, theme),
            const SizedBox(height: 8),
            _resultRow(context, 'Per Person', prov.tipData.perPerson, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, Function(String) onChanged) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 13,
          ),
        ),
        style: TextStyle(
          fontSize: 18,
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
      ),
    );
  }

  Widget _resultRow(BuildContext context, String label, double value, ThemeData theme) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              )),
          Text('\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
