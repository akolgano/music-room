// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'core/service_locator.dart';
import 'core/app_builder.dart';
import 'widgets/network_connectivity_widget.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await _initializeApp();
  
  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ...AppBuilder.buildProviders(),
          ...AppBuilder.buildAdditionalProviders(),
        ],
        child: MyApp(),
      ),
    ),
  );
}

Future<void> _initializeApp() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Could not load .env file: $e');
  }
  
  await setupServiceLocator();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => NetworkConnectivityWidget(
        child: const MusicRoomApp(),
      ),
    );
  }
}
