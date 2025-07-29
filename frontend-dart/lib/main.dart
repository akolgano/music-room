import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/theme_utils.dart';
import 'core/social_login.dart';
import 'core/constants.dart';
import 'core/service_locator.dart';
import 'core/app_builder.dart';
import 'core/app_logger.dart';
import 'providers/dynamic_theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AppLogger.initialize();
  
  try {
    try {
      await dotenv.load(fileName: ".env");
      final apiBaseUrl = dotenv.env['API_BASE_URL'];
      if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
        AppLogger.warning('API_BASE_URL not found in .env, using default', 'Main');
      }
    } catch (e) {
      AppLogger.error('Failed to load .env file' + ": " + e.toString(), null, null, 'Main');
    }
    await setupServiceLocator();
    try {
      await SocialLoginUtils.initialize();
    } catch (e) {
      AppLogger.error('Failed to initialize social login' + ": " + e.toString(), null, null, 'Main');
    }
    runApp(const MyApp());
  } catch (e, _) {
    runApp(MaterialApp(
      title: 'Music Room - Error',
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: AppTheme.error),
                  const SizedBox(height: 24),
                  const Text(
                    'App Initialization Failed',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(e.toString(), style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Please restart the application',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(320, 480),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [...AppBuilder.buildProviders(), ...AppBuilder.buildAdditionalProviders()],
          child: ResponsiveBreakpoints(
            breakpoints: [
              const Breakpoint(start: 0, end: 256, name: 'TINY'),
              const Breakpoint(start: 257, end: 426, name: 'SMALL'),
              const Breakpoint(start: 427, end: 640, name: MOBILE),
              const Breakpoint(start: 641, end: 854, name: 'LARGE'),
              const Breakpoint(start: 855, end: 1280, name: TABLET),
              const Breakpoint(start: 1281, end: double.infinity, name: DESKTOP),
            ],
            child: Consumer<DynamicThemeProvider>(
              builder: (context, themeProvider, _) {
                return MaterialApp(
                  title: AppConstants.appName,
                  theme: themeProvider.dynamicTheme, 
                  onGenerateRoute: AppBuilder.generateRoute,
                  initialRoute: '/', 
                  debugShowCheckedModeBanner: false,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
