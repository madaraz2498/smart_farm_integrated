// lib/features/admin/reports/screens/admin_reports_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import 'package:smart_farm/features/notifications/providers/notification_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/theme/app_theme.dart';
import '../models/report_model.dart';
import '../providers/report_provider.dart';
import '../utils/label_mapper.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminReportProvider>().fetchAllReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AdminReportProvider>();
    final notifProvider = context.read<NotificationProvider>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final currentYear = DateTime.now().year.toString();
    final w = MediaQuery.sizeOf(context).width;
    final pagePadding = (w * 0.04).clamp(16.0, 24.0);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: () => provider.fetchAllReports(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Header Section
            Row(children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(l10n.nav_reports, style: AppTextStyles.pageTitle),
            ]),
            const SizedBox(height: 4),
            Text(
                isAr
                    ? 'تحليل مقاييس النظام والنمو لعام $currentYear'
                    : 'System metrics and growth analysis for $currentYear',
                style: AppTextStyles.pageSubtitle),
            const SizedBox(height: 24),

            // Filter Section
            _buildFilterCard(
              context,
              provider,
              l10n,
              isAr,
            ),
            const SizedBox(height: 24),

            // Main Content
            if (provider.isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 100),
                child: CircularProgressIndicator(),
              ))
            else if (provider.error != null)
              Center(
                  child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Failed to load reports: ${provider.error}'),
                  TextButton(
                    onPressed: () => provider.fetchAllReports(),
                    child: const Text('Retry'),
                  ),
                ],
              ))
            else ...[
              _buildChartCard(
                title: isAr
                    ? 'الاستخدام حسب الخدمة ($currentYear)'
                    : 'Usage by Service ($currentYear)',
                subtitle: isAr
                    ? 'إجمالي الاستخدام لكل خدمة'
                    : 'Total counts per service',
                chart: ServiceUsageBarChart(data: provider.usageList),
              ),
              const SizedBox(height: 24),
              _buildChartCard(
                title: isAr
                    ? 'نمو المستخدمين ($currentYear)'
                    : 'User Growth ($currentYear)',
                subtitle: isAr
                    ? 'التسجيلات الجديدة شهرياً'
                    : 'Monthly new registrations',
                chart: UserGrowthLineChart(data: provider.growthList),
              ),
              const SizedBox(height: 24),
              _buildChartCard(
                title: isAr
                    ? 'النشاط اليومي ($currentYear)'
                    : 'Daily Activity ($currentYear)',
                subtitle: isAr
                    ? 'النشاط في آخر 7 أيام'
                    : 'Active interactions in the last 7 days',
                chart: DailyActivityLineChart(data: provider.activityList),
              ),
              const SizedBox(height: 24),
              _buildGeneratedReportsCard(
                context: context,
                provider: provider,
                notifProvider: notifProvider,
                l10n: l10n,
              ),
              const SizedBox(height: 40),
            ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, AdminReportProvider provider,
      AppLocalizations l10n, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(l10n.report_filters, style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.date_range, style: AppTextStyles.label),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: provider.selectedRange,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            items: [
              DropdownMenuItem(
                  value: 'last_7_days', child: Text(l10n.last_7_days)),
              DropdownMenuItem(
                  value: 'last_30_days', child: Text(l10n.last_30_days)),
              DropdownMenuItem(value: 'last_year', child: Text(l10n.last_year)),
            ],
            onChanged: (value) {
              if (value != null) provider.setRange(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedReportsCard({
    required BuildContext context,
    required AdminReportProvider provider,
    required NotificationProvider notifProvider,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.generated_reports, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Text(l10n.download_historical_reports,
                      style: AppTextStyles.caption),
                ],
              ),
              const Icon(Icons.history_rounded, color: AppColors.textDisabled),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: provider.isGenerating
                  ? null
                  : () async {
                      try {
                        await provider.generateNewReport(notifProvider);
                      } catch (e) {
                        debugPrint('Error generating report: $e');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: provider.isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_chart_rounded),
                        const SizedBox(width: 10),
                        Text(l10n.generate_new_report,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (provider.generatedReports.isNotEmpty)
            Column(
              children: provider.generatedReports.map((report) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildReportHistoryItem(
                    context,
                    url: report['url'] as String,
                    time: report['time'] as DateTime,
                    l10n: l10n,
                  ),
                );
              }).toList(),
            )
          else
            _buildReportHistoryItem(
              context,
              url: 'Annual_Farm_Report_2025.pdf',
              time: DateTime(2025, 3, 20),
              l10n: l10n,
              isMock: true,
            ),
        ],
      ),
    );
  }

  Widget _buildReportHistoryItem(
    BuildContext context, {
    required String url,
    required DateTime time,
    required AppLocalizations l10n,
    bool isMock = false,
  }) {
    final fileName = url.split('/').last;
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(time);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text('${isMock ? "2.4 MB" : "PDF"} • $formattedDate',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            onPressed: isMock
                ? null
                : () async {
                    final uri = Uri.parse(url.trim());
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget chart,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption),
          const SizedBox(height: 32),
          // Fixed height and AspectRatio to prevent stretching/overlap
          AspectRatio(
            aspectRatio: 1.7,
            child: chart,
          ),
        ],
      ),
    );
  }
}

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
                // Removed problematic BackgroundBarChartRodData to avoid layering issues
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
