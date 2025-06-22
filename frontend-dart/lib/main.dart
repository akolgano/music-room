// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'core/core.dart';
import 'core/service_locator.dart';
import 'core/app_builder.dart';
import 'widgets/network_connectivity_widget.dart';
import 'widgets/app_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Starting app initialization...');
    await dotenv.load();
    print('Environment variables loaded');
    await setupServiceLocator();
    print('Service locator setup complete');
    try {
      await SocialLoginUtils.initialize();
      print('Social login services initialized successfully');
    } catch (e) {
      print('Warning: Social login initialization failed: $e');
    }
    print('Starting MyApp...');
    runApp(const MyApp());
  } catch (e) {
    print('Critical error during app initialization: $e');
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [...AppBuilder.buildProviders(), ...AppBuilder.buildAdditionalProviders()],
          child: MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.getResponsiveDarkTheme(),
            onGenerateRoute: AppBuilder.generateRoute,
            initialRoute: '/',
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Room - Error',
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: AppTheme.error),
              SizedBox(height: 16),
              Text('Failed to initialize app', style: TextStyle(color: Colors.white, fontSize: 18)),
              SizedBox(height: 8),
              Text('Please restart the application', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
