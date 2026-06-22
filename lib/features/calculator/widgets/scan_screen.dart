import 'dart:io' show File, Directory;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/ocr.dart';
import '../providers/calculator_provider.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/responsive_wrapper.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _ocr = OcrService();
  String? _imagePath;
  String? _result;
  String? _expression;
  bool _showResult = false;
  bool _isSolving = false;
  bool _imageLoading = false;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      if (_textCtrl.text.isNotEmpty && _showResult) {
        setState(() => _showResult = false);
      }
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    _ocr.dispose();
    super.dispose();
  }

  void _solveText() {
    final text = _normalize(_textCtrl.text.trim());
    if (text.isEmpty) return;
    _solve(text);
  }

  Future<void> _solveImage() async {
    if (_imagePath == null) return;

    setState(() => _isSolving = true);

    String text = '';
    try {
      text = _normalize((await _ocr.extractText(_imagePath!)).trim());
    } catch (_) {}

    if (text.isEmpty) {
      setState(() => _isSolving = false);
      if (mounted) _showOcrFailed();
      return;
    }

    _textCtrl.text = text;
    if (mounted) {
      try {
        final result = context.read<CalculatorProvider>().evaluateExpression(text);
        if (result != 'Error') {
          setState(() {
            _expression = text;
            _result = result;
            _showResult = true;
            _isSolving = false;
          });
          return;
        }
      } catch (_) {}
    }

    // Solve failed — try aggressive cleanup for OCR noise
    final cleaned = _aggressiveClean(text);
    if (cleaned != text && cleaned.isNotEmpty && mounted) {
      _textCtrl.text = cleaned;
      try {
        final result = context.read<CalculatorProvider>().evaluateExpression(cleaned);
        if (result != 'Error') {
          setState(() {
            _expression = cleaned;
            _result = result;
            _showResult = true;
            _isSolving = false;
          });
          return;
        }
      } catch (_) {}
    }

    // Still failing — show snackbar, keep text for editing
    setState(() => _isSolving = false);
    if (mounted) _showOcrFailed();
  }

  void _showOcrFailed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_textCtrl.text.isEmpty
            ? 'Could not read text — type the expression manually'
            : 'Expression not recognized — edit and tap Solve'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
    _focusNode.requestFocus();
  }

  void _solve(String text) {
    setState(() => _isSolving = true);

    try {
      final result = context.read<CalculatorProvider>().evaluateExpression(text);
      setState(() {
        _expression = text;
        _result = result;
        _showResult = true;
        _isSolving = false;
      });
    } catch (_) {
      setState(() {
        _expression = text;
        _result = 'Error';
        _showResult = true;
        _isSolving = false;
      });
    }
  }

  String _normalize(String s) {
    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll('X', 'x');
    s = s.replaceAll('*', '×');
    s = s.replaceAll('/', '÷');
    s = s.replaceAll(RegExp(r'[−–—―]'), '-');
    s = s.replaceAll('∕', '÷');
    s = s.replaceAll('²', '^2');
    s = s.replaceAll('³', '^3');
    s = s.replaceAll('⁰', '^0');
    s = s.replaceAll('¹', '^1');
    s = s.replaceAll('⁴', '^4');
    s = s.replaceAll('⁵', '^5');
    s = s.replaceAll('⁶', '^6');
    s = s.replaceAll('⁷', '^7');
    s = s.replaceAll('⁸', '^8');
    s = s.replaceAll('⁹', '^9');
    s = s.replaceAll('·', '×');
    s = s.replaceAll('⋅', '×');
    s = s.replaceAll(RegExp(r'[:;?!,"@#<>]'), '');
    s = s.replaceAllMapped(RegExp(r'[a-zA-Z]+'), (m) {
      final w = m[0]!.toLowerCase();
      if (_mathTokens.contains(w)) return m[0]!;
      return '';
    });
    return s;
  }

  static const _mathTokens = {
    'x', 'y', 'z', 'a', 'b', 'c', 'd', 't',
    'sin', 'cos', 'tan', 'log', 'ln', 'sqrt',
    'asin', 'acos', 'atan', 'sec', 'csc', 'cot',
    'pi', 'e', 'abs',
  };

  String _aggressiveClean(String s) {
    s = s.replaceAll(RegExp(r'[^0-9+\-×÷^=πe.x()a-zA-Z]'), '');
    s = s.replaceAllMapped(RegExp(r'[a-zA-Z]+'), (m) {
      final w = m[0]!.toLowerCase();
      if (_mathTokens.contains(w)) return m[0]!;
      return '';
    });
    return s;
  }

  void _useResult() {
    if (_result == null || _result == 'Error' || _expression == null) return;
    context.read<CalculatorProvider>().loadFromHistory(_expression!, _result!);
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _imagePath = null;
      _result = null;
      _expression = null;
      _showResult = false;
      _textCtrl.clear();
      _imageLoading = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return;

      setState(() => _imageLoading = true);

      String path = picked.path;
      if (!kIsWeb && path.startsWith('content://')) {
        final dir = Directory.systemTemp;
        final tmp = File('${dir.path}/scanner_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await picked.saveTo(tmp.path);
        path = tmp.path;
      }

      setState(() {
        _imagePath = path;
        _showResult = false;
        _imageLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _imageLoading = false);
    }
  }

  // --- UI --- //

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            children: [
              _appBar(context),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final wide = constraints.maxWidth > 600;
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                      child: Column(
                        children: [
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _textSection(isDark, primary, textColor)),
                                const SizedBox(width: 12),
                                Expanded(child: _cameraSection(isDark, primary, textColor)),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _textSection(isDark, primary, textColor),
                                const SizedBox(height: 12),
                                _cameraSection(isDark, primary, textColor),
                              ],
                            ),
                          if (_isSolving) ...[
                            const SizedBox(height: 14),
                            _solvingPanel(primary),
                          ],
                          if (_showResult && !_isSolving) ...[
                            const SizedBox(height: 14),
                            _resultSection(isDark, primary, textColor),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      title: const Text('Scan & Solve'),
      centerTitle: true,
    );
  }

  // ========== LEFT: Text Input Section ========== //

  Widget _textSection(bool isDark, Color primary, Color? textColor) {
    return GlassContainer(
      borderRadius: 16, padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, size: 18, color: primary),
              const SizedBox(width: 6),
              Text('Text Input', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 80),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              textDirection: TextDirection.ltr,
              maxLines: 4,
              minLines: 2,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400,
                color: textColor, fontFamily: 'monospace', height: 1.4),
              decoration: InputDecoration(
                hintText: 'Type your question here...',
                hintStyle: TextStyle(fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
                border: InputBorder.none, isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 44,
            child: AnimatedButton(
              onTap: _solveText,
              borderRadius: 12,
              gradient: _textCtrl.text.trim().isNotEmpty
                ? LinearGradient(colors: [primary, primary.withValues(alpha: 0.75)])
                : null,
              backgroundColor: _textCtrl.text.trim().isNotEmpty ? null : Colors.grey.withValues(alpha: 0.2),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 16,
                      color: _textCtrl.text.trim().isNotEmpty ? Colors.white : Colors.white38),
                    const SizedBox(width: 6),
                    Text('Solve', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: _textCtrl.text.trim().isNotEmpty ? Colors.white : Colors.white38)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== RIGHT: Camera / Upload Section ========== //

  Widget _cameraSection(bool isDark, Color primary, Color? textColor) {
    final hasImage = _imagePath != null;

    return GlassContainer(
      borderRadius: 16, padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, size: 18, color: primary),
              const SizedBox(width: 6),
              Text('Camera / Upload', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImage ? _capturedImage() : _dropZone(isDark, primary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionBtn(Icons.camera_alt_rounded, 'Camera', () => _pickImage(ImageSource.camera)),
              _actionBtn(Icons.photo_library_rounded, 'Gallery', () => _pickImage(ImageSource.gallery)),
              _actionBtn(Icons.cloud_upload_outlined, 'Upload', () => _pickImage(ImageSource.gallery)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 44,
            child: AnimatedButton(
              onTap: _solveImage,
              borderRadius: 12,
              gradient: hasImage
                ? LinearGradient(colors: [primary, primary.withValues(alpha: 0.75)])
                : null,
              backgroundColor: hasImage ? null : Colors.grey.withValues(alpha: 0.2),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded, size: 16,
                      color: hasImage ? Colors.white : Colors.white38),
                    const SizedBox(width: 6),
                    Text('Solve Image', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: hasImage ? Colors.white : Colors.white38)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropZone(bool isDark, Color primary) {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 28, color: primary.withValues(alpha: 0.5)),
            const SizedBox(height: 6),
            Text('Tap to upload image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
            const SizedBox(height: 2),
            Text('JPG, PNG', style: TextStyle(fontSize: 10,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.35))),
          ],
        ),
      ),
    );
  }

  Widget _capturedImage() {
    Widget img;
    if (kIsWeb) {
      img = Image.network(_imagePath!, height: 100, width: double.infinity, fit: BoxFit.cover);
    } else {
      img = Image.file(File(_imagePath!), height: 100, width: double.infinity, fit: BoxFit.cover);
    }
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: img),
        if (!_imageLoading)
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: _clearImage,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        if (_imageLoading)
          const Positioned.fill(
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
          ),
      ],
    );
  }

  void _clearImage() {
    setState(() => _imagePath = null);
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    final p = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: p.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: p),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p)),
          ],
        ),
      ),
    );
  }

  // ========== Shared ========== //

  Widget _solvingPanel(Color primary) {
    return GlassContainer(
      borderRadius: 14, padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primary)),
          const SizedBox(width: 10),
          Text('Solving...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }

  Widget _resultSection(bool isDark, Color primary, Color? textColor) {
    final isError = _result == 'Error';
    final hasExpression = _expression != null && _expression!.isNotEmpty;

    return GlassContainer(
      borderRadius: 16, padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                size: 18, color: isError ? Colors.orange : Colors.green),
              const SizedBox(width: 6),
              Text(isError ? 'Error' : 'Solution',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
              const Spacer(),
              GestureDetector(
                onTap: _reset,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.refresh, size: 16, color: primary),
                ),
              ),
            ],
          ),
          if (hasExpression && !isError) ...[
            const SizedBox(height: 6),
            Text(_expression!, textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400,
                color: textColor?.withValues(alpha: 0.5), fontFamily: 'monospace')),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(_result!, textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: isError ? Colors.orange : primary)),
          ),
          const SizedBox(height: 14),
          if (!isError)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: AnimatedButton(
                      onTap: _useResult, borderRadius: 12,
                      backgroundColor: primary.withValues(alpha: 0.15),
                      child: Center(child: Text('Use Result', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: AnimatedButton(
                      onTap: _reset, borderRadius: 12,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                      child: Center(child: Text('New Scan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor))),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              height: 42,
              child: AnimatedButton(
                onTap: _reset, borderRadius: 12,
                backgroundColor: primary.withValues(alpha: 0.15),
                child: Center(child: Text('Try Again', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary))),
              ),
            ),
        ],
      ),
    );
  }
}
