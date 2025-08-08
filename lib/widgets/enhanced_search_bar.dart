import 'package:flutter/material.dart';

class EnhancedSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function()? onClear;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showFilters;
  final VoidCallback? onFilterTap;
  final int? filterCount;

  const EnhancedSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.leading,
    this.actions,
    this.showFilters = false,
    this.onFilterTap,
    this.filterCount,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isExpanded
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.4),
                width: _isExpanded ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                // Barre de recherche principale
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (widget.leading != null) ...[
                        widget.leading!,
                        const SizedBox(width: 12),
                      ] else
                        Icon(
                          Icons.search_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: widget.onChanged,
                          onTap: _toggleExpanded,
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            fillColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            border: InputBorder.none,
                            // contentPadding: const EdgeInsets.symmetric(
                            //   vertical: 16,
                            // ),
                          ),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_controller.text.isNotEmpty) ...[
                        IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            _controller.clear();
                            widget.onChanged('');
                            widget.onClear?.call();
                          },
                        ),
                      ],
                      if (widget.showFilters) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: widget.onFilterTap,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Badge(
                                isLabelVisible: widget.filterCount != null &&
                                    widget.filterCount! > 0,
                                label: Text('${widget.filterCount}'),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: widget.filterCount != null &&
                                          widget.filterCount! > 0
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (widget.actions != null) ...widget.actions!,
                    ],
                  ),
                ),

                // Actions étendues (si nécessaire)
                if (_isExpanded && widget.showFilters)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Divider(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Filtres avancés',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: widget.onFilterTap,
                              icon: const Icon(Icons.filter_list_rounded,
                                  size: 16),
                              label: const Text('Configurer'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
