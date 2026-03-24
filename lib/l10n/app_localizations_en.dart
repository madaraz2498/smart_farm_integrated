// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'Smart Farm AI';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get create_account => 'Create Account';

  @override
  String get sign_in_to_account => 'Sign in to your account';

  @override
  String get enter_email => 'Enter your email';

  @override
  String get enter_password => 'Enter your password';

  @override
  String get dont_have_account => 'Don\'t have an account?';

  @override
  String get email_required => 'Email is required.';

  @override
  String get invalid_email => 'Enter a valid email.';

  @override
  String get password_required => 'Password is required.';

  @override
  String get manage_account_preferences =>
      'Manage your account and preferences';

  @override
  String get profile => 'Profile';

  @override
  String get full_name => 'Full Name';

  @override
  String get save_profile => 'Save Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get push_notifications => 'Push Notifications';

  @override
  String get email_alerts => 'Email Alerts';

  @override
  String get confirm_logout_message => 'Are you sure you want to sign out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get profile_saved => 'Profile saved.';

  @override
  String get join_today => 'Join Smart Farm AI today';

  @override
  String get enter_full_name => 'Enter your full name';

  @override
  String get min_6_chars => 'Min 6 characters';

  @override
  String get confirm_password => 'Confirm Password';

  @override
  String get re_enter_password => 'Re-enter password';

  @override
  String get already_have_account => 'Already have an account?';

  @override
  String get sign_in => 'Sign in';

  @override
  String get name_too_short => 'Name must be at least 2 characters.';

  @override
  String get password_too_short => 'Password must be at least 6 characters.';

  @override
  String get passwords_dont_match => 'Passwords do not match.';

  @override
  String get welcome_user => 'Welcome';

  @override
  String get nav_plant_disease => 'Plant Disease Detection';

  @override
  String get nav_animal_weight => 'Animal Weight Estimation';

  @override
  String get nav_crop_recommendation => 'Crop Recommendation';

  @override
  String get nav_soil_analysis => 'Soil Type Analysis';

  @override
  String get nav_fruit_quality => 'Fruit Quality Analysis';

  @override
  String get nav_chatbot => 'Smart Farm Chatbot';

  @override
  String get nav_reports => 'Statistical Reports';

  @override
  String get admin => 'Admin';

  @override
  String get environmental_parameters => 'Environmental Parameters';

  @override
  String get temperature_c => 'Temperature (°C)';

  @override
  String get humidity_p => 'Humidity (%)';

  @override
  String get rainfall_mm => 'Rainfall (mm)';

  @override
  String get soil_type => 'Soil Type';

  @override
  String get soil_sandy => 'Sandy';

  @override
  String get soil_loamy => 'Loamy';

  @override
  String get soil_clay => 'Clay';

  @override
  String get soil_silty => 'Silty';

  @override
  String get soil_ph => 'Soil pH';

  @override
  String get soil_moisture => 'Moisture Level';

  @override
  String get soil_nitrogen => 'Nitrogen (N)';

  @override
  String get soil_phosphorus => 'Phosphorus (P)';

  @override
  String get soil_potassium => 'Potassium (K)';

  @override
  String get soil_analyze_button => 'Analyze Soil Properties';

  @override
  String get soil_get_recommendation => 'Get Recommendation';

  @override
  String get soil_fertility => 'Fertility Level';

  @override
  String get soil_npk_levels => 'NPK Levels (Nitrogen, Phosphorus, Potassium)';

  @override
  String get animal_weight_desc =>
      'Upload an animal image to estimate weight using computer vision.';

  @override
  String get animal_image => 'Animal Image';

  @override
  String get estimate_weight => 'Estimate Weight';

  @override
  String get estimation_result => 'Estimation Result';

  @override
  String get estimated_weight => 'Estimated Weight';

  @override
  String get animal_type => 'Animal Type';

  @override
  String get plant_disease_desc =>
      'Upload a leaf image for AI-powered disease diagnosis.';

  @override
  String get plant_image => 'Plant Image';

  @override
  String get analyze_plant => 'Analyze Plant';

  @override
  String get analysis_result => 'Analysis Result';

  @override
  String get prediction => 'Prediction';

  @override
  String get description => 'Description';

  @override
  String get treatment => 'Treatment';

  @override
  String get fruit_quality_desc =>
      'Upload a fruit image for AI-powered quality grading.';

  @override
  String get fruit_image => 'Fruit Image';

  @override
  String get analyze_fruit => 'Analyze Fruit';

  @override
  String get quality_grade => 'Quality Grade';

  @override
  String get grade_label => 'Grade Label';

  @override
  String get ripeness => 'Ripeness';

  @override
  String get defects => 'Defects';

  @override
  String get chatbot_language => 'Chat Language:';

  @override
  String get type_message => 'Type a message...';

  @override
  String get chat_empty_state => 'Ask me anything about farming!';

  @override
  String get disease_detection => 'Disease Detection';

  @override
  String get disease_diagnosis => 'Diagnosis Results';

  @override
  String get success_msg => 'Operation completed successfully';

  @override
  String get error_msg => 'An error occurred, please try again';

  @override
  String get field_required => 'This field is required';

  @override
  String get choose_image => 'Choose Image';

  @override
  String get plant_disease_card_desc =>
      'Detect plant diseases early using AI image analysis.';

  @override
  String get animal_weight_card_desc =>
      'Accurately estimate animal weight without physical scales.';

  @override
  String get crop_recommendation_card_desc =>
      'Get the best crop suggestions based on soil and climate.';

  @override
  String get soil_analysis_card_desc =>
      'Analyze soil fertility and type using your data.';

  @override
  String get fruit_quality_card_desc =>
      'Classify fruit quality and detect defects automatically.';

  @override
  String get chatbot_card_desc =>
      'Ask your questions and get instant farming advice.';

  @override
  String get reports_subtitle => 'Access and download all AI-generated reports';

  @override
  String get generate_report => 'Generate Report';

  @override
  String get total_reports => 'Total Reports';

  @override
  String get this_month => 'This Month';

  @override
  String get vs_last_month => 'vs Last Month';

  @override
  String get no_reports_yet =>
      'No reports yet. Generate your first report now.';
}
