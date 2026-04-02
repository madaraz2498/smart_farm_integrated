// Farmer reports: GET /farmer_reports/stats/{uid} · /list/{uid}
// Admin reports:  POST /admin/reports/admin/reports/generate-pdf

class FarmerReportStats {
  const FarmerReportStats({
    required this.totalReports,
    required this.thisMonth,
    required this.growth,
  });

  factory FarmerReportStats.fromJson(Map<String, dynamic> j) {
    final t = j['top_cards'] as Map<String, dynamic>? ?? j;
    return FarmerReportStats(
      totalReports: _i(t['total_reports'] ?? t['total'] ?? 0),
      thisMonth:    _i(t['this_month']    ?? t['monthly'] ?? 0),
      growth:       t['growth'] as String? ?? '+0%',
    );
  }

  final int    totalReports, thisMonth;
  final String growth;
}

class FarmerReportItem {
  const FarmerReportItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
  });

  factory FarmerReportItem.fromJson(Map<String, dynamic> j) => FarmerReportItem(
        id:       (j['id'] ?? '').toString(),
        title:    j['title']    as String? ?? j['name']  as String? ?? 'Report',
        subtitle: j['subtitle'] as String? ?? j['description'] as String? ?? '',
        date:     j['date']     as String? ?? j['created_at'] as String? ?? '',
        type:     j['type']     as String? ?? 'Analysis',
      );

  final String id, title, subtitle, date, type;
}

int _i(dynamic v) {
  if (v is int)    return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
