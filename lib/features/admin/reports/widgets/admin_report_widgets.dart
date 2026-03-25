// lib/features/admin/reports/widgets/admin_report_widgets.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_farm/l10n/app_localizations.dart';

import '../../../../shared/theme/app_theme.dart';
import '../models/report_model.dart';
import '../utils/label_mapper.dart';

// ── Service Usage Bar Chart ──────────────────────────────────────────────────

class ServiceUsageBarChart extends StatelessWidget {
  final List<ServiceUsage> data;
  const ServiceUsageBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data available'));
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final maxVal =
        data.map((e) => e.count).fold(0, (p, c) => c > p ? c : p).toDouble();
    final maxY = maxVal == 0 ? 10.0 : maxVal * 1.4;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.textDark.withValues(alpha: 0.9),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = LabelMapper.getLocalizedService(
                  data[groupIndex].service, l10n);
              final isLabelArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(label);
              // Use RTL marker for Arabic text in tooltips
              final formattedLabel = isLabelArabic ? '\u200F$label' : label;

              return BarTooltipItem(
                '$formattedLabel\n',
                const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
                children: [
                  TextSpan(
                    text: '${l10n.total}: ${rod.toY.toInt()}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 ||
                    index >= data.length ||
                    value != index.toDouble()) return const SizedBox();
                final rawLabel = data[index].service;
                final localizedLabel =
                    LabelMapper.getLocalizedService(rawLabel, l10n);
                final isLabelArabic =
                    RegExp(r'[\u0600-\u06FF]').hasMatch(localizedLabel);

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 12,
                  angle: isAr ? 0.4 : -0.4,
                  child: Directionality(
                    textDirection:
                        isLabelArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 70),
                      child: Text(
                        localizedLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textSubtle,
                            fontSize: 9,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.count.toDouble(),
                color: AppColors.primary,
                width: 22,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── User Growth Line Chart ────────────────────────────────────────────────────

class UserGrowthLineChart extends StatelessWidget {
  final List<UserGrowth> data;
  const UserGrowthLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data available'));
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return LineChart(
      LineChartData(
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textDark.withValues(alpha: 0.9),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final month = LabelMapper.getLocalizedMonth(
                    data[spot.x.toInt()].month, l10n);
                final isLabelArabic =
                    RegExp(r'[\u0600-\u06FF]').hasMatch(month);
                final label = isLabelArabic ? '\u200F$month' : month;

                return LineTooltipItem(
                  '$label: ${spot.y.toInt()} ${l10n.registered}',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 ||
                    index >= data.length ||
                    value != index.toDouble()) return const SizedBox();
                final label =
                    LabelMapper.getLocalizedMonth(data[index].month, l10n);

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Directionality(
                    textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                    child: Text(label,
                        style: const TextStyle(
                            color: AppColors.textSubtle, fontSize: 10)),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.4,
            preventCurveOverShooting: true,
            color: AppColors.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.users.toDouble());
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Daily Activity Line Chart ─────────────────────────────────────────────────

class DailyActivityLineChart extends StatelessWidget {
  final List<DailyActivity> data;
  const DailyActivityLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data available'));
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return LineChart(
      LineChartData(
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textDark,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final day =
                    LabelMapper.getLocalizedDay(data[spot.x.toInt()].day, l10n);
                final isLabelArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(day);
                final label = isLabelArabic ? '\u200F$day' : day;

                return LineTooltipItem(
                  '$label: ${spot.y.toInt()}',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 ||
                    index >= data.length ||
                    value != index.toDouble()) return const SizedBox();
                final label =
                    LabelMapper.getLocalizedDay(data[index].day, l10n);

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Directionality(
                    textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                    child: Text(label,
                        style: const TextStyle(
                            color: AppColors.textSubtle, fontSize: 10)),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.4,
            preventCurveOverShooting: true,
            color: AppColors.primary,
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isPeak = spot.y ==
                    data
                        .map((e) => e.activity)
                        .fold(0, (p, c) => c > p ? c : p)
                        .toDouble();
                return FlDotCirclePainter(
                  radius: isPeak ? 6 : 3,
                  color: isPeak ? AppColors.adminAccent : AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.activity.toDouble());
            }).toList(),
          ),
        ],
      ),
    );
  }
}
