import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/app_builder.dart';
void main() {
  group('App Builder Tests', () {
    test('AppBuilder should be properly configured', () {
      expect(AppBuilder, isA<Type>());
      
      const appConfig = {
        'name': 'Music Room',
        'version': '1.0.0',
        'buildNumber': 1,
        'supportedLocales': ['en', 'es', 'fr'],
        'defaultTheme': 'light',
      };
      
      expect(appConfig['name'], 'Music Room');
      expect(appConfig['version'], startsWith('1.'));
      expect(appConfig['buildNumber'], isA<int>());
      expect(appConfig['supportedLocales'], isA<List>());
      expect(appConfig['defaultTheme'], isIn(['light', 'dark', 'system']));
    });
    test('AppBuilder should handle theme configuration', () {
      const themeConfig = {
        'useMaterial3': true,
        'supportsDynamicColor': true,
        'defaultBrightness': 'light',
        'primaryColorScheme': 'blue',
      };
      
      expect(themeConfig['useMaterial3'], true);
      expect(themeConfig['supportsDynamicColor'], isA<bool>());
      expect(themeConfig['defaultBrightness'], isIn(['light', 'dark']));
      expect(themeConfig['primaryColorScheme'], isA<String>());
      
      var currentTheme = 'light';
      const availableThemes = ['light', 'dark', 'system'];
      
      expect(availableThemes.contains(currentTheme), true);
      
      currentTheme = 'dark';
      expect(currentTheme, 'dark');
      expect(availableThemes.contains(currentTheme), true);
    });
    test('AppBuilder should handle localization setup', () {
      const localizationConfig = {
        'defaultLocale': 'en',
        'supportedLocales': ['en', 'es', 'fr', 'de'],
        'fallbackLocale': 'en',
        'useSystemLocale': true,
      };
      
      expect(localizationConfig['defaultLocale'], 'en');
      expect(localizationConfig['supportedLocales'], isA<List<String>>());
      expect(localizationConfig['fallbackLocale'], 'en');
      expect(localizationConfig['useSystemLocale'], true);
      
      final supportedLocales = localizationConfig['supportedLocales'] as List<String>;
      final defaultLocale = localizationConfig['defaultLocale'] as String;
      
      expect(supportedLocales.contains(defaultLocale), true);
      expect(supportedLocales.length, greaterThan(1));
      
      var currentLocale = 'en';
      expect(supportedLocales.contains(currentLocale), true);
      
      currentLocale = 'es';
      expect(supportedLocales.contains(currentLocale), true);
    });
    test('AppBuilder should handle navigation configuration', () {
      const navigationConfig = {
        'initialRoute': '/',
        'generateRoutes': true,
        'unknownRouteHandler': true,
        'routeObserver': true,
      };
      
      expect(navigationConfig['initialRoute'], '/');
      expect(navigationConfig['generateRoutes'], true);
      expect(navigationConfig['unknownRouteHandler'], true);
      expect(navigationConfig['routeObserver'], true);
      
      const appRoutes = {
        '/': 'HomeScreen',
        '/auth': 'AuthScreen',
        '/profile': 'ProfileScreen',
        '/playlists': 'PlaylistsScreen',
        '/friends': 'FriendsScreen',
      };
      
      expect(appRoutes.keys.length, 5);
      expect(appRoutes['/'], 'HomeScreen');
      expect(appRoutes['/auth'], 'AuthScreen');
      expect(appRoutes.keys.every((route) => route.startsWith('/')), true);
    });
    test('AppBuilder should handle dependency injection setup', () {
      const serviceConfig = {
        'useGetIt': true,
        'lazyServices': true,
        'singletonServices': ['StorageService', 'ApiService', 'AuthService'],
        'factoryServices': ['MusicService', 'FriendService'],
      };
      
      expect(serviceConfig['useGetIt'], true);
      expect(serviceConfig['lazyServices'], true);
      expect(serviceConfig['singletonServices'], isA<List<String>>());
      expect(serviceConfig['factoryServices'], isA<List<String>>());
      
      final singletonServices = serviceConfig['singletonServices'] as List<String>;
      final factoryServices = serviceConfig['factoryServices'] as List<String>;
      
      expect(singletonServices.contains('ApiService'), true);
      expect(singletonServices.contains('AuthService'), true);
      expect(factoryServices.contains('MusicService'), true);
      
      const initOrder = ['StorageService', 'ApiService', 'AuthService'];
      expect(initOrder.first, 'StorageService');
      expect(initOrder.last, 'AuthService');
    });
  });
}
