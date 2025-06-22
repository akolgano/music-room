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
    
    try {
      await dotenv.load(fileName: ".env");
      print('Environment variables loaded successfully');
      
      print('Environment check:');
      final apiBaseUrl = dotenv.env['API_BASE_URL'];
      if (apiBaseUrl != null && apiBaseUrl.isNotEmpty) {
        print('   API_BASE_URL found: $apiBaseUrl');
      } else {
        print('   API_BASE_URL not found in .env file, will use defaults');
      }
    } catch (e) {
      print('Warning: Failed to load .env file: $e');
      print('   Will use default configuration');
    }
    
    print('Setting up service locator...');
    await setupServiceLocator();
    print('Service locator setup complete');
    
    try {
      print('Initializing social login services...');
      await SocialLoginUtils.initialize();
      print('Social login services initialized successfully');
    } catch (e) {
      print('Warning: Social login initialization failed: $e');
      print('   Social login features may not work properly');
    }
    
    print('Starting MyApp...');
    runApp(const MyApp());
    
  } catch (e, stackTrace) {
    print('Critical error during app initialization: $e');
    print('Stack trace: $stackTrace');
    
    try {
      runApp(ErrorApp(error: e.toString()));
    } catch (errorAppError) {
      print('Failed to show error app: $errorAppError');
      runApp(MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ));
    }
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
          providers: [
            ...AppBuilder.buildProviders(), 
            ...AppBuilder.buildAdditionalProviders()
          ],
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
  final String? error;
  
  const ErrorApp({Key? key, this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Room - Error',
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline, 
                    size: 80, 
                    color: AppTheme.error
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Failed to Initialize App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Please check your configuration and restart the application',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => main(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
