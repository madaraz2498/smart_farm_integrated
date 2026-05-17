import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/reports_provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Reports are loaded from welcome page to prevent duplicate calls
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedDateRange == null) {
      final l10n = AppLocalizations.of(context)!;
      _selectedDateRange = l10n.all_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ReportsProvider>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pagePadding = Responsive.responsivePadding(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: () => prov.load(force: true),
            color: colorScheme.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(pagePadding),
              children: [
                // ── Header ──────────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nav_reports,
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.reports_subtitle,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Stats Row ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.description_outlined,
                        value: '${prov.stats?.totalReports ?? 0}',
                        label: l10n.total_reports,
                        accent: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.calendar_today_outlined,
                        value: '${prov.stats?.thisMonth ?? 0}',
                        label: l10n.this_month,
                        accent: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.trending_up_rounded,
                        value: prov.stats?.growth ?? 'N/A',
                        label: l10n.vs_last_month,
                        accent: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Filters Card ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.filter_list_rounded,
                                color: colorScheme.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.report_filters,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.date_range,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDateRange,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                color: colorScheme.primary),
                            items: [
                              l10n.all_time,
                              l10n.last_month,
                              l10n.last_3_months
                            ]
                                .map<DropdownMenuItem<String>>(
                                    (String s) => DropdownMenuItem<String>(
                                          value: s,
                                          child: Text(s,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500)),
                                        ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedDateRange = v);
                                // Map label to API period
                                String period = 'all';
                                if (v == l10n.last_month) period = 'month';
                                if (v == l10n.last_3_months) period = 'quarter';
                                prov.load(force: true, period: period);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Generate Reports Card ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outline),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.description_outlined,
                            color: colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.generated_reports,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.download_reports_desc,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _GenerateButton(
                        isGenerating: prov.isGenerating,
                        onPressed: () async {
                          if (prov.isGenerating) return;
                          // Generate only — no download
                          final ok = await prov.generate();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? l10n.success_msg
                                : (prov.error ?? l10n.error_msg)),
                            backgroundColor:
                                ok ? colorScheme.primary : colorScheme.error,
                          ));
                        },
                        label: l10n.generate_new_report,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Report List / Empty State ────────────────────────────
                if (prov.isLoading && prov.reports.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child:
                          CircularProgressIndicator(color: colorScheme.primary),
                    ),
                  )
                else if (prov.reports.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.insert_drive_file_outlined,
                                size: 48, color: colorScheme.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.no_reports_yet,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.nav_reports,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface)),
                          const SizedBox(height: 4),
                          Text(l10n.reports_subtitle,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${prov.reports.length} reports',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...prov.reports.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ReportListItem(report: r),
                      )),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Generate Button ───────────────────────────────────────────────────────────

class _GenerateButton extends StatelessWidget {
  final bool isGenerating;
  final VoidCallback? onPressed;
  final String label;

  const _GenerateButton({
    required this.isGenerating,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IntrinsicWidth(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
        ),
        child: isGenerating
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: colorScheme.onPrimary),
              )
            : Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}

// ── Report List Item ──────────────────────────────────────────────────────────

class _ReportListItem extends StatefulWidget {
  final dynamic report;
  const _ReportListItem({required this.report});

  @override
  State<_ReportListItem> createState() => _ReportListItemState();
}

class _ReportListItemState extends State<_ReportListItem> {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  String? _localPath;

  Future<void> _download(ReportsProvider prov) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Downloading report...'),
      duration: Duration(seconds: 2),
    ));

    final path = await prov.downloadReportToFile(
      widget.report.id,
      url: widget.report.url,
    );

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      if (path != null) {
        _isDownloaded = true;
        _localPath = path;
      }
    });

    if (path == null && prov.error != null) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(prov.error!),
        backgroundColor: colorScheme.error,
      ));
      prov.clearError();
    }
  }

  Future<void> _open(ReportsProvider prov) async {
    if (_localPath == null) return;
    await prov.openLocalReport(_localPath!);
    if (!mounted) return;
    if (prov.error != null) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(prov.error!),
        backgroundColor: colorScheme.error,
      ));
      prov.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<ReportsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      // Tap container → open if downloaded, else download first then open
      onTap: () async {
        if (_isDownloaded && _localPath != null) {
          await _open(prov);
        } else {
          await _download(prov);
          // After download, open automatically
          if (_localPath != null && mounted) {
            await _open(prov);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isDownloaded
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isDownloaded
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isDownloaded
                    ? Icons.picture_as_pdf_rounded
                    : Icons.description_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.report.title,
                    style: textTheme.titleSmall
                        ?.copyWith(color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.report.date,
                    style: textTheme.bodySmall,
                  ),
                  if (_isDownloaded)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'Tap to open',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Download button — only shows if NOT downloaded yet
            if (!_isDownloaded)
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isDownloading
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.download_rounded,
                            color: colorScheme.primary, size: 20),
                        onPressed: () => _download(prov),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        tooltip: 'Download',
                      ),
              )
            else
              // Open icon when downloaded
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.open_in_new_rounded,
                      color: colorScheme.primary, size: 20),
                  onPressed: () => _open(prov),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  tooltip: 'Open',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
