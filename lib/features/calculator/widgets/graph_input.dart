import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../../../shared/widgets/glass_container.dart';

class GraphInput extends StatefulWidget {
  const GraphInput({super.key});

  @override
  State<GraphInput> createState() => _GraphInputState();
}

class _GraphInputState extends State<GraphInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final calc = context.read<CalculatorProvider>();
    _controller = TextEditingController(text: calc.graphFunction);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    context.read<CalculatorProvider>().setGraphFunction(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Text(
              'y = ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: theme.textTheme.bodyLarge?.color,
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
