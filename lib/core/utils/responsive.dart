import 'package:flutter/widgets.dart';

class Responsive {
  const Responsive._();

  static double getWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double getHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isMobile(BuildContext context) => getWidth(context) < 600;

  static bool isTablet(BuildContext context) {
    final w = getWidth(context);
    return w >= 600 && w < 1024;
  }

  static bool isDesktop(BuildContext context) => getWidth(context) >= 1024;

  static double screenWidth(BuildContext context) => getWidth(context);

  static double screenHeight(BuildContext context) => getHeight(context);

  static double responsivePadding(BuildContext context) => screenWidth(context) * 0.04;

  static double responsiveSpacing(BuildContext context) => screenWidth(context) * 0.03;

  static double responsiveValue(BuildContext context, double mobileValue, double tabletValue, double desktopValue) {
    if (isDesktop(context)) return desktopValue;
    if (isTablet(context)) return tabletValue;
    return mobileValue;
  }
}

