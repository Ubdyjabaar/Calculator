import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../widgets/history_tile.dart';
import '../../calculator/providers/calculator_provider.dart';
import '../../../shared/widgets/responsive_wrapper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            children: [
              _buildAppBar(context, isDark),
              if (_showSearch) _buildSearchBar(context),
              Expanded(
                child: Consumer<HistoryProvider>(
                  builder: (context, history, _) {
                    if (history.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (history.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return Scrollbar(
                      thumbVisibility: true,
                      thickness: 6,
                      radius: const Radius.circular(8),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: history.entries.length,
                        itemBuilder: (context, index) {
                          final entry = history.entries[index];
                          return HistoryTile(
                            entry: entry,
                            index: index,
                            onTap: () {
                              context
                                  .read<CalculatorProvider>()
                                  .loadFromHistory(
                                      entry.expression, entry.result);
                              Navigator.of(context).pop();
                            },
                            onDelete: () {
                              if (entry.id != null) {
                                history.deleteEntry(entry.id!, index);
                              }
                            },
                          );
                        },
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

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text(
            'History',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  context.read<HistoryProvider>().setSearchQuery('');
                }
              });
            },
          ),
          Consumer<HistoryProvider>(
            builder: (context, history, _) {
              if (history.isEmpty) return const SizedBox(width: 48);
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _confirmClear(context, history),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) {
          context.read<HistoryProvider>().setSearchQuery(value);
        },
        decoration: InputDecoration(
          hintText: 'Search calculations...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calculate_outlined,
            size: 64,
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No calculations yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, HistoryProvider history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear History'),
        content: const Text('Delete all calculation history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              history.clearAll();
              Navigator.pop(ctx);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Colors.red.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
