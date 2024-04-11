import 'package:flutter/material.dart';
import 'package:flutter_investment_control/services/asset_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'core/app_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AssetProvider(),
      child: const AppWidget(),
    ),
  );
}