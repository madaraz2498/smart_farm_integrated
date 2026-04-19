import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Loading state widget for when waiting for GPS location
class LocationLoadingState extends StatelessWidget {
  const LocationLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GPS Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.gps_fixed_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Getting Your Location',
              style: AppTextStyles.pageTitle.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Please wait while we get your GPS coordinates for accurate weather data...',
              style: AppTextStyles.pageSubtitle.copyWith(
                color: AppColors.textSubtle,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            
            Text(
              'This will only take a few seconds',
              style: AppTextStyles.pageSubtitle.copyWith(
                color: AppColors.textSubtle,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
