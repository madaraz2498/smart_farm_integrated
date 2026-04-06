import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Smart Farm AI'**
  String get app_name;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @create_account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account;

  /// No description provided for @sign_in_to_account.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get sign_in_to_account;

  /// No description provided for @enter_email.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enter_email;

  /// No description provided for @enter_password.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enter_password;

  /// No description provided for @dont_have_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dont_have_account;

  /// No description provided for @email_required.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get email_required;

  /// No description provided for @invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get invalid_email;

  /// No description provided for @password_required.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get password_required;

  /// No description provided for @manage_account_preferences.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and preferences'**
  String get manage_account_preferences;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @full_name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get full_name;

  /// No description provided for @save_profile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get save_profile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @push_notifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get push_notifications;

  /// No description provided for @email_alerts.
  ///
  /// In en, this message translates to:
  /// **'Email Alerts'**
  String get email_alerts;

  /// No description provided for @confirm_logout_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirm_logout_message;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @profile_saved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profile_saved;

  /// No description provided for @admin_panel.
  ///
  /// In en, this message translates to:
  /// **'ADMIN PANEL'**
  String get admin_panel;

  /// No description provided for @main_menu.
  ///
  /// In en, this message translates to:
  /// **'MAIN MENU'**
  String get main_menu;

  /// No description provided for @profile_settings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profile_settings;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number;

  /// No description provided for @theme_preference.
  ///
  /// In en, this message translates to:
  /// **'Theme Preference'**
  String get theme_preference;

  /// No description provided for @light_mode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get light_mode;

  /// No description provided for @dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// No description provided for @join_today.
  ///
  /// In en, this message translates to:
  /// **'Join Smart Farm AI today'**
  String get join_today;

  /// No description provided for @enter_full_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enter_full_name;

  /// No description provided for @min_6_chars.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get min_6_chars;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password;

  /// No description provided for @re_enter_password.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get re_enter_password;

  /// No description provided for @already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get already_have_account;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign_in;

  /// No description provided for @name_too_short.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters.'**
  String get name_too_short;

  /// No description provided for @password_too_short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get password_too_short;

  /// No description provided for @passwords_dont_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwords_dont_match;

  /// No description provided for @welcome_user.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome_user;

  /// No description provided for @nav_plant_disease.
  ///
  /// In en, this message translates to:
  /// **'Plant Disease Detection'**
  String get nav_plant_disease;

  /// No description provided for @nav_animal_weight.
  ///
  /// In en, this message translates to:
  /// **'Animal Weight Estimation'**
  String get nav_animal_weight;

  /// No description provided for @nav_crop_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Crop Recommendation'**
  String get nav_crop_recommendation;

  /// No description provided for @nav_soil_analysis.
  ///
  /// In en, this message translates to:
  /// **'Soil Type Analysis'**
  String get nav_soil_analysis;

  /// No description provided for @nav_fruit_quality.
  ///
  /// In en, this message translates to:
  /// **'Fruit Quality Analysis'**
  String get nav_fruit_quality;

  /// No description provided for @nav_chatbot.
  ///
  /// In en, this message translates to:
  /// **'Smart Farm Chatbot'**
  String get nav_chatbot;

  /// No description provided for @nav_reports.
  ///
  /// In en, this message translates to:
  /// **'System Reports'**
  String get nav_reports;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @environmental_parameters.
  ///
  /// In en, this message translates to:
  /// **'Environmental Parameters'**
  String get environmental_parameters;

  /// No description provided for @temperature_c.
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C)'**
  String get temperature_c;

  /// No description provided for @humidity_p.
  ///
  /// In en, this message translates to:
  /// **'Humidity (%)'**
  String get humidity_p;

  /// No description provided for @rainfall_mm.
  ///
  /// In en, this message translates to:
  /// **'Rainfall (mm)'**
  String get rainfall_mm;

  /// No description provided for @soil_type.
  ///
  /// In en, this message translates to:
  /// **'Soil Type'**
  String get soil_type;

  /// No description provided for @soil_sandy.
  ///
  /// In en, this message translates to:
  /// **'Sandy'**
  String get soil_sandy;

  /// No description provided for @soil_loamy.
  ///
  /// In en, this message translates to:
  /// **'Loamy'**
  String get soil_loamy;

  /// No description provided for @soil_clay.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get soil_clay;

  /// No description provided for @soil_silty.
  ///
  /// In en, this message translates to:
  /// **'Silty'**
  String get soil_silty;

  /// No description provided for @soil_ph.
  ///
  /// In en, this message translates to:
  /// **'Soil pH'**
  String get soil_ph;

  /// No description provided for @soil_moisture.
  ///
  /// In en, this message translates to:
  /// **'Moisture Level'**
  String get soil_moisture;

  /// No description provided for @soil_nitrogen.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen (N)'**
  String get soil_nitrogen;

  /// No description provided for @soil_phosphorus.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus (P)'**
  String get soil_phosphorus;

  /// No description provided for @soil_potassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium (K)'**
  String get soil_potassium;

  /// No description provided for @soil_analyze_button.
  ///
  /// In en, this message translates to:
  /// **'Analyze Soil Properties'**
  String get soil_analyze_button;

  /// No description provided for @soil_get_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Get Recommendation'**
  String get soil_get_recommendation;

  /// No description provided for @soil_fertility.
  ///
  /// In en, this message translates to:
  /// **'Fertility Level'**
  String get soil_fertility;

  /// No description provided for @soil_npk_levels.
  ///
  /// In en, this message translates to:
  /// **'NPK Levels (Nitrogen, Phosphorus, Potassium)'**
  String get soil_npk_levels;

  /// No description provided for @animal_weight_desc.
  ///
  /// In en, this message translates to:
  /// **'Upload an animal image to estimate weight using computer vision.'**
  String get animal_weight_desc;

  /// No description provided for @animal_image.
  ///
  /// In en, this message translates to:
  /// **'Animal Image'**
  String get animal_image;

  /// No description provided for @estimate_weight.
  ///
  /// In en, this message translates to:
  /// **'Estimate Weight'**
  String get estimate_weight;

  /// No description provided for @estimation_result.
  ///
  /// In en, this message translates to:
  /// **'Estimation Result'**
  String get estimation_result;

  /// No description provided for @estimated_weight.
  ///
  /// In en, this message translates to:
  /// **'Estimated Weight'**
  String get estimated_weight;

  /// No description provided for @animal_type.
  ///
  /// In en, this message translates to:
  /// **'Animal Type'**
  String get animal_type;

  /// No description provided for @plant_disease_desc.
  ///
  /// In en, this message translates to:
  /// **'Upload a leaf image for AI-powered disease diagnosis.'**
  String get plant_disease_desc;

  /// No description provided for @plant_image.
  ///
  /// In en, this message translates to:
  /// **'Plant Image'**
  String get plant_image;

  /// No description provided for @analyze_plant.
  ///
  /// In en, this message translates to:
  /// **'Analyze Plant'**
  String get analyze_plant;

  /// No description provided for @analysis_result.
  ///
  /// In en, this message translates to:
  /// **'Analysis Result'**
  String get analysis_result;

  /// No description provided for @prediction.
  ///
  /// In en, this message translates to:
  /// **'Prediction'**
  String get prediction;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @treatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatment;

  /// No description provided for @fruit_quality_desc.
  ///
  /// In en, this message translates to:
  /// **'Upload a fruit image for AI-powered quality grading.'**
  String get fruit_quality_desc;

  /// No description provided for @fruit_image.
  ///
  /// In en, this message translates to:
  /// **'Fruit Image'**
  String get fruit_image;

  /// No description provided for @analyze_fruit.
  ///
  /// In en, this message translates to:
  /// **'Analyze Fruit'**
  String get analyze_fruit;

  /// No description provided for @quality_grade.
  ///
  /// In en, this message translates to:
  /// **'Quality Grade'**
  String get quality_grade;

  /// No description provided for @grade_label.
  ///
  /// In en, this message translates to:
  /// **'Grade Label'**
  String get grade_label;

  /// No description provided for @ripeness.
  ///
  /// In en, this message translates to:
  /// **'Ripeness'**
  String get ripeness;

  /// No description provided for @defects.
  ///
  /// In en, this message translates to:
  /// **'Defects'**
  String get defects;

  /// No description provided for @chatbot_language.
  ///
  /// In en, this message translates to:
  /// **'Chat Language:'**
  String get chatbot_language;

  /// No description provided for @type_message.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get type_message;

  /// No description provided for @chat_empty_state.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything about farming!'**
  String get chat_empty_state;

  /// No description provided for @chat_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Crops, diseases, irrigation, soil care...'**
  String get chat_empty_subtitle;

  /// No description provided for @chat_suggestions_title.
  ///
  /// In en, this message translates to:
  /// **'Quick questions:'**
  String get chat_suggestions_title;

  /// No description provided for @chat_suggest_1.
  ///
  /// In en, this message translates to:
  /// **'How to treat leaf blight?'**
  String get chat_suggest_1;

  /// No description provided for @chat_suggest_2.
  ///
  /// In en, this message translates to:
  /// **'Best irrigation for wheat'**
  String get chat_suggest_2;

  /// No description provided for @chat_suggest_3.
  ///
  /// In en, this message translates to:
  /// **'Soil fertilizer recommendations'**
  String get chat_suggest_3;

  /// No description provided for @chat_suggest_4.
  ///
  /// In en, this message translates to:
  /// **'Common tomato pests'**
  String get chat_suggest_4;

  /// No description provided for @disease_detection.
  ///
  /// In en, this message translates to:
  /// **'Disease Detection'**
  String get disease_detection;

  /// No description provided for @disease_diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis Results'**
  String get disease_diagnosis;

  /// No description provided for @success_msg.
  ///
  /// In en, this message translates to:
  /// **'Operation completed successfully'**
  String get success_msg;

  /// No description provided for @error_msg.
  ///
  /// In en, this message translates to:
  /// **'An error occurred, please try again'**
  String get error_msg;

  /// No description provided for @field_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get field_required;

  /// No description provided for @choose_image.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get choose_image;

  /// No description provided for @plant_disease_card_desc.
  ///
  /// In en, this message translates to:
  /// **'Detect plant diseases early using AI image analysis.'**
  String get plant_disease_card_desc;

  /// No description provided for @animal_weight_card_desc.
  ///
  /// In en, this message translates to:
  /// **'Accurately estimate animal weight without physical scales.'**
  String get animal_weight_card_desc;

  /// No description provided for @crop_recommendation_card_desc.
  ///
  /// In en, this message translates to:
  /// **'Get the best crop suggestions based on soil and climate.'**
  String get crop_recommendation_card_desc;

  /// No description provided for @soil_analysis_card_desc.
  ///
  /// In en, this message translates to:
  /// **'Analyze soil fertility and type using your data.'**
  String get soil_analysis_card_desc;

  /// No description provided for @fruit_quality_card_desc.
  ///
  /// In en, this message translates to:
  /// **'Classify fruit quality and detect defects automatically.'**
  String get fruit_quality_card_desc;

  /// No description provided for @chatbot_card_desc.
  ///
  /// In en, this message translates to:
  /// **'Ask your questions and get instant farming advice.'**
  String get chatbot_card_desc;

  /// No description provided for @reports_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Access and download all AI-generated reports'**
  String get reports_subtitle;

  /// No description provided for @export_all.
  ///
  /// In en, this message translates to:
  /// **'Export All'**
  String get export_all;

  /// No description provided for @generate_report.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generate_report;

  /// No description provided for @total_reports.
  ///
  /// In en, this message translates to:
  /// **'Total Reports'**
  String get total_reports;

  /// No description provided for @this_month.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get this_month;

  /// No description provided for @vs_last_month.
  ///
  /// In en, this message translates to:
  /// **'vs Last Month'**
  String get vs_last_month;

  /// No description provided for @no_reports_yet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet. Generate your first report now.'**
  String get no_reports_yet;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @use_ai_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Use AI to improve your farming decisions'**
  String get use_ai_subtitle;

  /// No description provided for @system_reports_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive analytics and reporting for the Smart Farm AI platform'**
  String get system_reports_subtitle;

  /// No description provided for @report_filters.
  ///
  /// In en, this message translates to:
  /// **'Report Filters'**
  String get report_filters;

  /// No description provided for @download_reports_desc.
  ///
  /// In en, this message translates to:
  /// **'Download your farm analysis reports'**
  String get download_reports_desc;

  /// No description provided for @date_range.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get date_range;

  /// No description provided for @last_30_days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last_30_days;

  /// No description provided for @last_7_days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last_7_days;

  /// No description provided for @last_90_days.
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get last_90_days;

  /// No description provided for @last_year.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get last_year;

  /// No description provided for @custom_range.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get custom_range;

  /// No description provided for @total_analyses.
  ///
  /// In en, this message translates to:
  /// **'Total Analyses'**
  String get total_analyses;

  /// No description provided for @active_users.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get active_users;

  /// No description provided for @ai_services.
  ///
  /// In en, this message translates to:
  /// **'AI Services'**
  String get ai_services;

  /// No description provided for @avg_response.
  ///
  /// In en, this message translates to:
  /// **'Avg Response'**
  String get avg_response;

  /// No description provided for @usage_by_service.
  ///
  /// In en, this message translates to:
  /// **'Usage by Service'**
  String get usage_by_service;

  /// No description provided for @total_analyses_per_service.
  ///
  /// In en, this message translates to:
  /// **'Total analyses per service'**
  String get total_analyses_per_service;

  /// No description provided for @user_growth.
  ///
  /// In en, this message translates to:
  /// **'User Growth'**
  String get user_growth;

  /// No description provided for @new_user_registrations.
  ///
  /// In en, this message translates to:
  /// **'New user registrations'**
  String get new_user_registrations;

  /// No description provided for @daily_activity.
  ///
  /// In en, this message translates to:
  /// **'Daily Activity'**
  String get daily_activity;

  /// No description provided for @platform_activity_past_week.
  ///
  /// In en, this message translates to:
  /// **'Platform activity over the past week'**
  String get platform_activity_past_week;

  /// No description provided for @generated_reports.
  ///
  /// In en, this message translates to:
  /// **'Generated Reports'**
  String get generated_reports;

  /// No description provided for @download_historical_reports.
  ///
  /// In en, this message translates to:
  /// **'Download historical reports'**
  String get download_historical_reports;

  /// No description provided for @generate_new_report.
  ///
  /// In en, this message translates to:
  /// **'Generate New Report'**
  String get generate_new_report;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @uptime.
  ///
  /// In en, this message translates to:
  /// **'uptime'**
  String get uptime;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @admin_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get admin_dashboard;

  /// No description provided for @admin_dashboard_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time monitoring and platform statistics'**
  String get admin_dashboard_subtitle;

  /// No description provided for @recent_activity.
  ///
  /// In en, this message translates to:
  /// **'Recent System Activity'**
  String get recent_activity;

  /// No description provided for @total_users.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get total_users;

  /// No description provided for @most_used.
  ///
  /// In en, this message translates to:
  /// **'Most Used'**
  String get most_used;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'registered'**
  String get registered;

  /// No description provided for @top.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get top;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @plant_disease.
  ///
  /// In en, this message translates to:
  /// **'Plant Disease'**
  String get plant_disease;

  /// No description provided for @animal_weight.
  ///
  /// In en, this message translates to:
  /// **'Animal Weight'**
  String get animal_weight;

  /// No description provided for @crop_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Crop Recommendation'**
  String get crop_recommendation;

  /// No description provided for @soil_analysis.
  ///
  /// In en, this message translates to:
  /// **'Soil Analysis'**
  String get soil_analysis;

  /// No description provided for @fruit_quality.
  ///
  /// In en, this message translates to:
  /// **'Fruit Quality'**
  String get fruit_quality;

  /// No description provided for @chatbot.
  ///
  /// In en, this message translates to:
  /// **'Chatbot'**
  String get chatbot;

  /// No description provided for @generating_report.
  ///
  /// In en, this message translates to:
  /// **'Generating report...'**
  String get generating_report;

  /// No description provided for @report_generated_success.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully'**
  String get report_generated_success;

  /// No description provided for @mark_all_as_read.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get mark_all_as_read;

  /// No description provided for @view_all_notifications.
  ///
  /// In en, this message translates to:
  /// **'View all notifications'**
  String get view_all_notifications;

  /// No description provided for @user_management.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get user_management;

  /// No description provided for @system_management.
  ///
  /// In en, this message translates to:
  /// **'System Management'**
  String get system_management;

  /// No description provided for @manage_users_roles_permissions.
  ///
  /// In en, this message translates to:
  /// **'Manage users, roles, and permissions'**
  String get manage_users_roles_permissions;

  /// No description provided for @system_status_settings_modules.
  ///
  /// In en, this message translates to:
  /// **'System status, settings, and modules'**
  String get system_status_settings_modules;

  /// No description provided for @no_notifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications found'**
  String get no_notifications;

  /// No description provided for @notification_report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get notification_report;

  /// No description provided for @notification_chatbot.
  ///
  /// In en, this message translates to:
  /// **'Chatbot'**
  String get notification_chatbot;

  /// No description provided for @notification_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get notification_user;

  /// No description provided for @notification_system.
  ///
  /// In en, this message translates to:
  /// **'System Update'**
  String get notification_system;

  /// No description provided for @ai_response_ready.
  ///
  /// In en, this message translates to:
  /// **'AI Response Ready'**
  String get ai_response_ready;

  /// No description provided for @report_ready.
  ///
  /// In en, this message translates to:
  /// **'Report Ready'**
  String get report_ready;

  /// No description provided for @welcome_to_smart_farm.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Smart Farm AI'**
  String get welcome_to_smart_farm;

  /// No description provided for @system_update.
  ///
  /// In en, this message translates to:
  /// **'System Update'**
  String get system_update;

  /// No description provided for @language_selection.
  ///
  /// In en, this message translates to:
  /// **'Language Selection'**
  String get language_selection;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @notification_preferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notification_preferences;

  /// No description provided for @email_notifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get email_notifications;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @usage_over_time.
  ///
  /// In en, this message translates to:
  /// **'Usage Over Time'**
  String get usage_over_time;

  /// No description provided for @monthly_registrations.
  ///
  /// In en, this message translates to:
  /// **'Monthly user registrations'**
  String get monthly_registrations;

  /// No description provided for @service_distribution.
  ///
  /// In en, this message translates to:
  /// **'Service Distribution'**
  String get service_distribution;

  /// No description provided for @usage_by_ai_service.
  ///
  /// In en, this message translates to:
  /// **'Usage by AI service'**
  String get usage_by_ai_service;

  /// No description provided for @add_new_admin.
  ///
  /// In en, this message translates to:
  /// **'Add New Admin'**
  String get add_new_admin;

  /// No description provided for @email_address.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email_address;

  /// No description provided for @add_admin.
  ///
  /// In en, this message translates to:
  /// **'Add Admin'**
  String get add_admin;

  /// No description provided for @user_promoted_success.
  ///
  /// In en, this message translates to:
  /// **'{email} is now an Admin'**
  String user_promoted_success(String email);

  /// No description provided for @user_not_found_email.
  ///
  /// In en, this message translates to:
  /// **'Could not find user with this email.'**
  String get user_not_found_email;

  /// No description provided for @search_users_hint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get search_users_hint;

  /// No description provided for @active_users_label.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get active_users_label;

  /// No description provided for @total_users_label.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get total_users_label;

  /// No description provided for @admins_label.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get admins_label;

  /// No description provided for @inactive_users_label.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive_users_label;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @user_name_email.
  ///
  /// In en, this message translates to:
  /// **'Name & Email'**
  String get user_name_email;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @user_details.
  ///
  /// In en, this message translates to:
  /// **'User Details'**
  String get user_details;

  /// No description provided for @promote_to_admin.
  ///
  /// In en, this message translates to:
  /// **'Promote to Admin'**
  String get promote_to_admin;

  /// No description provided for @deactivate_user.
  ///
  /// In en, this message translates to:
  /// **'Deactivate User'**
  String get deactivate_user;

  /// No description provided for @activate_user.
  ///
  /// In en, this message translates to:
  /// **'Activate User'**
  String get activate_user;

  /// No description provided for @delete_user.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get delete_user;

  /// No description provided for @confirm_delete_user.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this user?'**
  String get confirm_delete_user;

  /// No description provided for @confirm_action_title.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get confirm_action_title;

  /// No description provided for @confirm_promote_desc.
  ///
  /// In en, this message translates to:
  /// **'This user will be granted full admin permissions. Do you want to continue?'**
  String get confirm_promote_desc;

  /// No description provided for @confirm_deactivate_desc.
  ///
  /// In en, this message translates to:
  /// **'The user account will be disabled and they will be prevented from logging in. Do you want to continue?'**
  String get confirm_deactivate_desc;

  /// No description provided for @confirm_activate_desc.
  ///
  /// In en, this message translates to:
  /// **'The user account will be reactivated and they will be allowed to log in. Do you want to continue?'**
  String get confirm_activate_desc;

  /// No description provided for @confirm_delete_desc.
  ///
  /// In en, this message translates to:
  /// **'All user data will be permanently deleted from the system. This action cannot be undone!'**
  String get confirm_delete_desc;

  /// No description provided for @confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm_button;

  /// No description provided for @personal_information.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personal_information;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @current_password.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get current_password;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get new_password;

  /// No description provided for @update_password.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get update_password;

  /// No description provided for @save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save_changes;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @profile_picture_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated!'**
  String get profile_picture_updated;

  /// No description provided for @failed_to_update_profile_picture.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile picture.'**
  String get failed_to_update_profile_picture;

  /// No description provided for @failed_to_save_changes.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes'**
  String get failed_to_save_changes;

  /// No description provided for @password_changed_success.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get password_changed_success;

  /// No description provided for @system_management_title.
  ///
  /// In en, this message translates to:
  /// **'System Management'**
  String get system_management_title;

  /// No description provided for @system_management_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure AI services and platform settings'**
  String get system_management_subtitle;

  /// No description provided for @ai_models.
  ///
  /// In en, this message translates to:
  /// **'AI Models'**
  String get ai_models;

  /// No description provided for @general_settings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get general_settings;

  /// No description provided for @platform_settings.
  ///
  /// In en, this message translates to:
  /// **'Platform Settings'**
  String get platform_settings;

  /// No description provided for @maintenance_mode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Mode'**
  String get maintenance_mode;

  /// No description provided for @maintenance_mode_desc.
  ///
  /// In en, this message translates to:
  /// **'Disable user access temporarily'**
  String get maintenance_mode_desc;

  /// No description provided for @auto_backup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get auto_backup;

  /// No description provided for @auto_backup_desc.
  ///
  /// In en, this message translates to:
  /// **'Daily database snapshots'**
  String get auto_backup_desc;

  /// No description provided for @save_ai_config.
  ///
  /// In en, this message translates to:
  /// **'Save AI Configuration'**
  String get save_ai_config;

  /// No description provided for @save_general_settings.
  ///
  /// In en, this message translates to:
  /// **'Save General Settings'**
  String get save_general_settings;

  /// No description provided for @ai_config_saved.
  ///
  /// In en, this message translates to:
  /// **'AI configuration saved!'**
  String get ai_config_saved;

  /// No description provided for @general_settings_saved.
  ///
  /// In en, this message translates to:
  /// **'General settings saved!'**
  String get general_settings_saved;

  /// No description provided for @error_user_not_found.
  ///
  /// In en, this message translates to:
  /// **'Error: User not found'**
  String get error_user_not_found;

  /// No description provided for @unknown_user.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknown_user;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @send_message.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get send_message;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @message_content.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message_content;

  /// No description provided for @message_sent_success.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully'**
  String get message_sent_success;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @admin_reply.
  ///
  /// In en, this message translates to:
  /// **'Admin Reply'**
  String get admin_reply;

  /// No description provided for @replied.
  ///
  /// In en, this message translates to:
  /// **'Replied'**
  String get replied;

  /// No description provided for @not_replied.
  ///
  /// In en, this message translates to:
  /// **'Not Replied'**
  String get not_replied;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @delete_message.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get delete_message;

  /// No description provided for @confirm_delete_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get confirm_delete_message;

  /// No description provided for @no_messages_found.
  ///
  /// In en, this message translates to:
  /// **'No messages found'**
  String get no_messages_found;

  /// No description provided for @type_your_reply.
  ///
  /// In en, this message translates to:
  /// **'Type your reply...'**
  String get type_your_reply;

  /// No description provided for @farmer_messages.
  ///
  /// In en, this message translates to:
  /// **'Farmer Messages'**
  String get farmer_messages;

  /// No description provided for @your_messages.
  ///
  /// In en, this message translates to:
  /// **'Your Messages'**
  String get your_messages;

  /// No description provided for @communicate_with_admin.
  ///
  /// In en, this message translates to:
  /// **'Communicate with admin'**
  String get communicate_with_admin;

  /// No description provided for @new_message.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get new_message;

  /// No description provided for @message_type.
  ///
  /// In en, this message translates to:
  /// **'Message Type'**
  String get message_type;

  /// No description provided for @select_message_type.
  ///
  /// In en, this message translates to:
  /// **'Select message type...'**
  String get select_message_type;

  /// No description provided for @complaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get complaint;

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestion;

  /// No description provided for @inquiry.
  ///
  /// In en, this message translates to:
  /// **'Inquiry'**
  String get inquiry;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
