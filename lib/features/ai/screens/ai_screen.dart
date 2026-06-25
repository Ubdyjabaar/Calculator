import 'dart:io' show File, Directory;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../../../core/utils/ocr.dart';
import '../../../shared/widgets/glass_container.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _ocr = OcrService();
  String? _pendingImagePath;
  bool _imageLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _ocr.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty && _pendingImagePath == null) return;

    String finalText = text.trim();

    if (_pendingImagePath != null) {
      if (finalText.isEmpty) finalText = 'Solve this:';
      context.read<AIProvider>().sendMessageWithImage(finalText, _pendingImagePath!);
      setState(() => _pendingImagePath = null);
    } else {
      context.read<AIProvider>().sendMessage(finalText);
    }

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
        final tmp = File('${dir.path}/ai_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await picked.saveTo(tmp.path);
        path = tmp.path;
      }

      // Extract text
      String extracted;
      try {
        extracted = (await _ocr.extractText(path)).trim();
      } catch (_) {
        extracted = '';
      }

      if (extracted.isNotEmpty) {
        _controller.text = extracted;
      }

      setState(() {
        _pendingImagePath = path;
        _imageLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _imageLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AIProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Math Solver'),
        centerTitle: true,
        actions: [
          if (prov.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear chat',
              onPressed: () => prov.clearMessages(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: prov.messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: prov.messages.length,
                    itemBuilder: (context, i) => _MessageBubble(
                      message: prov.messages[i],
                      theme: theme,
                    ),
                  ),
          ),
          if (_pendingImagePath != null)
            _buildImagePreview(theme),
          if (prov.loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_pendingImagePath!),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Image attached',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  )),
            ),
            GestureDetector(
              onTap: () => setState(() => _pendingImagePath = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.close, size: 14,
                    color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 56,
                color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Ask me anything about math!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                )),
            const SizedBox(height: 8),
            Text(
              'Type any math problem or snap a photo.\nSolve, derive, integrate, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 4,
        right: 4,
        bottom: MediaQuery.of(context).padding.bottom + 4,
        top: 4,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
            onPressed: () => _pickImage(ImageSource.camera),
            tooltip: 'Camera',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
            onPressed: () => _pickImage(ImageSource.gallery),
            tooltip: 'Gallery',
          ),
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type a math problem...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            color: theme.colorScheme.primary,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AIMessage message;
  final ThemeData theme;

  const _MessageBubble({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_awesome, size: 16,
                  color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person, size: 16,
                  color: theme.colorScheme.secondary),
            ),
          ],
        ],
      ),
    );
  }
}
