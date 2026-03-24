import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../shared/theme/app_theme.dart';

class AdminStatsGrid extends StatefulWidget {
  const AdminStatsGrid({super.key});
  @override
  State<AdminStatsGrid> createState() => _AdminStatsGridState();
}

class _AdminStatsGridState extends State<AdminStatsGrid> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(builder: (context, prov, _) {
      if (prov.statsLoading) {
        return const SizedBox(height: 120,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
      }

      final s = prov.stats;
      return LayoutBuilder(builder: (_, c) {
        final mobile = c.maxWidth < 600;
        return Wrap(spacing: 16, runSpacing: 16, children: [
          _StatCard(title: 'Total Analyses', value: s?.formattedAnalyses ?? '–',
              badge: s?.analysesGrowth ?? '+0%', subtitle: 'this month',
              isMobile: mobile, svgPath: 'assets/images/icons/total analyses.svg'),
          _StatCard(title: 'Total Users', value: s?.formattedUsers ?? '–',
              badge: s?.usersGrowth ?? '+0%', subtitle: 'registered',
              isMobile: mobile, svgPath: 'assets/images/icons/active users.svg'),
          _StatCard(title: 'AI Services', value: s?.aiServicesDisplay ?? '6 / 6',
              badge: 'All Online', subtitle: 'active',
              isMobile: mobile, svgPath: 'assets/images/icons/ai services.svg'),
          _StatCard(title: 'Most Used', value: s?.mostUsedService ?? 'Plant Disease',
              badge: 'Top', subtitle: 'Detection',
              isMobile: mobile, svgPath: 'assets/images/icons/avg response.svg'),
        ]);
      });
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.badge,
      required this.subtitle, required this.isMobile, required this.svgPath});
  final String title, value, badge, subtitle, svgPath;
  final bool   isMobile;

  @override
  Widget build(BuildContext context) {
    final w = isMobile
        ? (MediaQuery.of(context).size.width - 64) / 2
        : (MediaQuery.of(context).size.width / 4) - 32;

    return Container(
      width: w, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SvgPicture.asset(svgPath, width: 40, height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(badge, style: const TextStyle(color: AppColors.primary, fontSize: 10,
                fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
            color: Color(0xFF1A1C1E)), overflow: TextOverflow.ellipsis),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]),
    );
  }
}

/// Recent activity list (static — replace with live endpoint when available).
class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  static const _items = [
    ('John Farmer',  'Used Plant Disease Detection',    '2 minutes ago'),
    ('Sarah Miller', 'Completed Soil Analysis',          '15 minutes ago'),
    ('Mike Johnson', 'Requested Crop Recommendation',    '1 hour ago'),
    ('Emma Wilson',  'Used Animal Weight Estimation',    '2 hours ago'),
    ('David Brown',  'Analyzed Fruit Quality',           '3 hours ago'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recent System Activity', style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
          itemBuilder: (_, i) {
            final (user, action, time) = _items[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.person_outline, color: AppColors.primary, size: 20)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user,   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(action, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ])),
                Text(time, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ]),
            );
          },
        ),
      ]),
    );
  }
}
