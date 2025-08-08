import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String title;
  final List<FilterOption> options;
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheet({
    super.key,
    required this.title,
    required this.options,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _tempFilters;

  @override
  void initState() {
    super.initState();
    _tempFilters = Map.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempFilters.clear();
                    });
                  },
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
          ),

          // Filters
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final option = widget.options[index];
                return _buildFilterOption(option);
              },
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApplyFilters(_tempFilters);
                      Navigator.pop(context);
                    },
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(FilterOption option) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (option.type) {
      case FilterType.checkbox:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...option.values.map((value) {
              final isSelected = _tempFilters[option.key] is List
                  ? (_tempFilters[option.key] as List).contains(value.key)
                  : false;

              return CheckboxListTile(
                title: Text(value.label),
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (_tempFilters[option.key] == null) {
                      _tempFilters[option.key] = <String>[];
                    }
                    final list = _tempFilters[option.key] as List<String>;
                    if (selected == true) {
                      list.add(value.key);
                    } else {
                      list.remove(value.key);
                    }
                    if (list.isEmpty) {
                      _tempFilters.remove(option.key);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
          ],
        );

      case FilterType.radio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...option.values.map((value) {
              return RadioListTile<String>(
                title: Text(value.label),
                value: value.key,
                groupValue: _tempFilters[option.key],
                onChanged: (selected) {
                  setState(() {
                    if (selected != null) {
                      _tempFilters[option.key] = selected;
                    } else {
                      _tempFilters.remove(option.key);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        );

      case FilterType.range:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            RangeSlider(
              values: RangeValues(
                (_tempFilters['${option.key}_min'] ?? option.min).toDouble(),
                (_tempFilters['${option.key}_max'] ?? option.max).toDouble(),
              ),
              min: option.min.toDouble(),
              max: option.max.toDouble(),
              divisions: option.divisions,
              labels: RangeLabels(
                '${_tempFilters['${option.key}_min'] ?? option.min}',
                '${_tempFilters['${option.key}_max'] ?? option.max}',
              ),
              onChanged: (values) {
                setState(() {
                  _tempFilters['${option.key}_min'] = values.start.round();
                  _tempFilters['${option.key}_max'] = values.end.round();
                });
              },
            ),
          ],
        );

      case FilterType.dateRange:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _selectDate(context, '${option.key}_start'),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _tempFilters['${option.key}_start'] != null
                          ? _formatDate(_tempFilters['${option.key}_start'])
                          : 'Date début',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, '${option.key}_end'),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _tempFilters['${option.key}_end'] != null
                          ? _formatDate(_tempFilters['${option.key}_end'])
                          : 'Date fin',
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Future<void> _selectDate(BuildContext context, String key) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tempFilters[key] ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _tempFilters[key] = date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class FilterOption {
  final String key;
  final String label;
  final FilterType type;
  final List<FilterValue> values;
  final num min;
  final num max;
  final int? divisions;

  const FilterOption({
    required this.key,
    required this.label,
    required this.type,
    this.values = const [],
    this.min = 0,
    this.max = 100,
    this.divisions,
  });
}

class FilterValue {
  final String key;
  final String label;

  const FilterValue({
    required this.key,
    required this.label,
  });
}

enum FilterType {
  checkbox,
  radio,
  range,
  dateRange,
}

// Fonction utilitaire pour afficher le bottom sheet
Future<void> showFilterBottomSheet({
  required BuildContext context,
  required String title,
  required List<FilterOption> options,
  required Map<String, dynamic> currentFilters,
  required Function(Map<String, dynamic>) onApplyFilters,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FilterBottomSheet(
      title: title,
      options: options,
      currentFilters: currentFilters,
      onApplyFilters: onApplyFilters,
    ),
  );
}
