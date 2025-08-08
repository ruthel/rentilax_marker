import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';

class AdvancedLineChart extends StatefulWidget {
  final List<ChartDataPoint> data;
  final String title;
  final String? subtitle;
  final Color? primaryColor;
  final String? unit;
  final bool showGrid;
  final bool showDots;
  final bool enableTouch;
  final double height;

  const AdvancedLineChart({
    super.key,
    required this.data,
    required this.title,
    this.subtitle,
    this.primaryColor,
    this.unit,
    this.showGrid = true,
    this.showDots = true,
    this.enableTouch = true,
    this.height = 300,
  });

  @override
  State<AdvancedLineChart> createState() => _AdvancedLineChartState();
}

class _AdvancedLineChartState extends State<AdvancedLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = widget.primaryColor ?? colorScheme.primary;

    if (widget.data.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return Container(
      height: widget.height + 80,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, colorScheme),
          const SizedBox(height: 20),
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return LineChart(
                  _buildLineChartData(primaryColor, colorScheme),
                  duration: const Duration(milliseconds: 250),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (_touchedIndex != null && _touchedIndex! < widget.data.length)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.primaryColor?.withValues(alpha: 0.1) ??
                      colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.data[_touchedIndex!].value.toStringAsFixed(1)} ${widget.unit ?? ''}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.primaryColor ?? colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: widget.height + 80,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData(
      Color primaryColor, ColorScheme colorScheme) {
    final maxY =
        widget.data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minY =
        widget.data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;

    // Éviter la division par zéro pour horizontalInterval
    final horizontalInterval = range > 0
        ? range / 5
        : maxY > 0
            ? maxY / 5
            : 1.0;

    return LineChartData(
      gridData: FlGridData(
        show: widget.showGrid,
        drawVerticalLine: false,
        horizontalInterval: horizontalInterval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: colorScheme.outline.withValues(alpha: 0.2),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (widget.data.length / 6).ceil().toDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < widget.data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.data[index].label,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: range > 0
                ? range / 4
                : maxY > 0
                    ? maxY / 4
                    : 1.0,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatValue(value),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (widget.data.length - 1).toDouble(),
      minY: minY - (range * 0.1),
      maxY: maxY + (range * 0.1),
      lineBarsData: [
        LineChartBarData(
          spots: widget.data.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value.value * _animation.value,
            );
          }).toList(),
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withValues(alpha: 0.7),
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: widget.showDots,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: _touchedIndex == index ? 6 : 4,
                color: primaryColor,
                strokeWidth: 2,
                strokeColor: colorScheme.surface,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.3),
                primaryColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: widget.enableTouch
          ? LineTouchData(
              enabled: true,
              touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                setState(() {
                  if (response != null && response.lineBarSpots != null) {
                    _touchedIndex = response.lineBarSpots!.first.spotIndex;
                  } else {
                    _touchedIndex = null;
                  }
                });
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => colorScheme.inverseSurface,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final index = barSpot.spotIndex;
                    if (index < widget.data.length) {
                      return LineTooltipItem(
                        '${widget.data[index].label}\n${barSpot.y.toStringAsFixed(1)} ${widget.unit ?? ''}',
                        TextStyle(
                          color: colorScheme.onInverseSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            )
          : LineTouchData(enabled: false),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

class AdvancedBarChart extends StatefulWidget {
  final List<ChartDataPoint> data;
  final String title;
  final String? subtitle;
  final Color? primaryColor;
  final String? unit;
  final bool showGrid;
  final bool enableTouch;
  final double height;

  const AdvancedBarChart({
    super.key,
    required this.data,
    required this.title,
    this.subtitle,
    this.primaryColor,
    this.unit,
    this.showGrid = true,
    this.enableTouch = true,
    this.height = 300,
  });

  @override
  State<AdvancedBarChart> createState() => _AdvancedBarChartState();
}

class _AdvancedBarChartState extends State<AdvancedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = widget.primaryColor ?? colorScheme.primary;

    if (widget.data.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return Container(
      height: widget.height + 80,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, colorScheme),
          const SizedBox(height: 20),
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return BarChart(
                  _buildBarChartData(primaryColor, colorScheme),
                  swapAnimationDuration: const Duration(milliseconds: 250),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (_touchedIndex != null && _touchedIndex! < widget.data.length)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.primaryColor?.withValues(alpha: 0.1) ??
                      colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.data[_touchedIndex!].value.toStringAsFixed(1)} ${widget.unit ?? ''}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.primaryColor ?? colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: widget.height + 80,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _buildBarChartData(Color primaryColor, ColorScheme colorScheme) {
    final maxY = widget.data.isEmpty
        ? 10.0
        : widget.data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY * 1.2,
      barTouchData: widget.enableTouch
          ? BarTouchData(
              enabled: true,
              touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                setState(() {
                  if (response != null && response.spot != null) {
                    _touchedIndex = response.spot!.touchedBarGroupIndex;
                  } else {
                    _touchedIndex = null;
                  }
                });
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => colorScheme.inverseSurface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (groupIndex < widget.data.length) {
                    return BarTooltipItem(
                      '${widget.data[groupIndex].label}\n${rod.toY.toStringAsFixed(1)} ${widget.unit ?? ''}',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return null;
                },
              ),
            )
          : BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < widget.data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.data[index].label,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatValue(value),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: widget.data.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final isTouched = _touchedIndex == index;

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: data.value * _animation.value,
              color: isTouched
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.8),
              width: isTouched ? 25 : 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        );
      }).toList(),
      gridData: FlGridData(
        show: widget.showGrid,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? maxY / 5 : 1.0,
        getDrawingHorizontalLine: (value) => FlLine(
          color: colorScheme.outline.withValues(alpha: 0.2),
          strokeWidth: 1,
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

class AdvancedPieChart extends StatefulWidget {
  final List<ChartDataPoint> data;
  final String title;
  final String? subtitle;
  final List<Color>? colors;
  final bool showPercentage;
  final bool enableTouch;
  final double height;

  const AdvancedPieChart({
    super.key,
    required this.data,
    required this.title,
    this.subtitle,
    this.colors,
    this.showPercentage = true,
    this.enableTouch = true,
    this.height = 300,
  });

  @override
  State<AdvancedPieChart> createState() => _AdvancedPieChartState();
}

class _AdvancedPieChartState extends State<AdvancedPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.data.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    final total = widget.data.fold(0.0, (sum, item) => sum + item.value);

    return Container(
      height: widget.height + 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, colorScheme),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return PieChart(
                        _buildPieChartData(colorScheme, total),
                        swapAnimationDuration:
                            const Duration(milliseconds: 250),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildLegend(theme, colorScheme, total),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: widget.height + 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, ColorScheme colorScheme, double total) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.data.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final color = _getColor(index, colorScheme);
        final percentage = total > 0 ? (data.value / total) * 100 : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.showPercentage)
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  PieChartData _buildPieChartData(ColorScheme colorScheme, double total) {
    return PieChartData(
      pieTouchData: widget.enableTouch
          ? PieTouchData(
              enabled: true,
              touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                setState(() {
                  if (response != null && response.touchedSection != null) {
                    _touchedIndex =
                        response.touchedSection!.touchedSectionIndex;
                  } else {
                    _touchedIndex = null;
                  }
                });
              },
            )
          : PieTouchData(enabled: false),
      borderData: FlBorderData(show: false),
      sectionsSpace: 2,
      centerSpaceRadius: 50,
      sections: widget.data.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final isTouched = _touchedIndex == index;
        final color = _getColor(index, colorScheme);
        final percentage = total > 0 ? (data.value / total) * 100 : 0.0;

        return PieChartSectionData(
          color: color,
          value: data.value * _animation.value,
          title:
              widget.showPercentage ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: isTouched ? 70 : 60,
          titleStyle: TextStyle(
            fontSize: isTouched ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.6,
        );
      }).toList(),
    );
  }

  Color _getColor(int index, ColorScheme colorScheme) {
    if (widget.colors != null && index < widget.colors!.length) {
      return widget.colors![index];
    }

    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];

    return colors[index % colors.length];
  }
}
