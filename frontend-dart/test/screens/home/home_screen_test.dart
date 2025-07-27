import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/screens/home/home_screen.dart';
void main() {
  group('Home Screen Tests', () {
    test('HomeScreen should be instantiable', () {
      const screen = HomeScreen();
      expect(screen, isA<HomeScreen>());
    });
    test('HomeScreen should be a StatefulWidget', () {
      const screen = HomeScreen();
      expect(screen, isA<StatefulWidget>());
    });
    test('HomeScreen should have proper widget key handling', () {
      const key = Key('home_screen_key');
      const screen = HomeScreen(key: key);
      expect(screen.key, key);
    });
    test('HomeScreen should create state correctly', () {
      const screen = HomeScreen();
      final state = screen.createState();
      expect(state, isA<State<HomeScreen>>());
    });
  });
}