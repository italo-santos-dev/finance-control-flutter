import 'package:flutter/material.dart';
import 'package:flutter_investment_control/services/asset_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/app_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Portuguese date formatting symbols globally
  try {
    await initializeDateFormatting('pt_BR', null);
  } catch (e) {
    debugPrint('Error initializing DateFormatting: $e');
  }

  try {
    MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('Error initializing MobileAds: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AssetProvider(),
      child: const AppWidget(),
    ),
  );
}