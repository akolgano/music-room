// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'core/app_builder.dart';
import 'core/consolidated_core.dart';
import 'core/service_locator.dart';
import 'providers/dynamic_theme_provider.dart';
import 'widgets/network_connectivity_widget.dart';
import 'widgets/app_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Warning: Could not load .env file: $e');
  }
  
  await setupServiceLocator();
  await SocialLoginUtils.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: AppBuilder.buildProviders() + AppBuilder.buildAdditionalProviders(),
          child: Consumer<DynamicThemeProvider>(
            builder: (context, themeProvider, _) {
              return MaterialApp(
                title: AppConstants.appName,
                theme: AppTheme.getResponsiveDarkTheme(), 
                navigatorKey: _navigatorKey,
                onGenerateRoute: AppBuilder.generateRoute,
                initialRoute: '/',
                debugShowCheckedModeBanner: false,
                builder: (context, widget) {
                  return NetworkConnectivityWidget(
                    child: Stack(
                      children: [
                        widget!,
                        const Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: MiniPlayerWidget(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
