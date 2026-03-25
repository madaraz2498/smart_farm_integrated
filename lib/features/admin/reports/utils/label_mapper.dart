// lib/features/admin/reports/utils/label_mapper.dart

import 'package:smart_farm/l10n/app_localizations.dart';

class LabelMapper {
  static String getLocalizedService(String apiLabel, AppLocalizations l10n) {
    final cleanLabel = apiLabel.toLowerCase().trim();

    if (cleanLabel.contains('plant') ||
        cleanLabel.contains('disease') ||
        cleanLabel.contains('نبات')) return l10n.plant_disease;
    if (cleanLabel.contains('animal') ||
        cleanLabel.contains('weight') ||
        cleanLabel.contains('حيوان')) return l10n.animal_weight;
    if (cleanLabel.contains('crop') || cleanLabel.contains('محاصيل'))
      return l10n.crop_recommendation;
    if (cleanLabel.contains('soil') || cleanLabel.contains('تربة'))
      return l10n.soil_analysis;
    if (cleanLabel.contains('fruit') || cleanLabel.contains('فاكهة'))
      return l10n.fruit_quality;
    if (cleanLabel.contains('chat') ||
        cleanLabel.contains('مساعد') ||
        cleanLabel.contains('بوت')) return l10n.chatbot;

    return apiLabel;
  }

  static String getLocalizedMonth(String month, AppLocalizations l10n) {
    switch (month.toLowerCase().substring(0, 3)) {
      case 'jan':
        return l10n.jan;
      case 'feb':
        return l10n.feb;
      case 'mar':
        return l10n.mar;
      case 'apr':
        return l10n.apr;
      case 'may':
        return l10n.may;
      case 'jun':
        return l10n.jun;
      case 'jul':
        return l10n.jul;
      case 'aug':
        return l10n.aug;
      case 'sep':
        return l10n.sep;
      case 'oct':
        return l10n.oct;
      case 'nov':
        return l10n.nov;
      case 'dec':
        return l10n.dec;
      default:
        return month;
    }
  }

  static String getLocalizedDay(String day, AppLocalizations l10n) {
    final clean = day.toLowerCase().trim();

    if (clean.contains('mon')) return l10n.mon;
    if (clean.contains('tue')) return l10n.tue;
    if (clean.contains('wed')) return l10n.wed;
    if (clean.contains('thu')) return l10n.thu;
    if (clean.contains('fri')) return l10n.fri;
    if (clean.contains('sat')) return l10n.sat;
    if (clean.contains('sun')) return l10n.sun;

    // Handle "Month Day" like "Mar 19"
    final parts = day.split(' ');
    if (parts.length == 2) {
      final month = getLocalizedMonth(parts[0], l10n);
      final isAr = l10n.localeName == 'ar';
      return isAr ? '${parts[1]} $month' : '$month ${parts[1]}';
    }

    return day;
  }
}
