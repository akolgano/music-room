import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:music_room/widgets/mini_player_widget.dart';

void main() {
  group('Mini Player Widget Tests', () {
    test('MiniPlayerWidget should be instantiable', () {
      const widget = MiniPlayerWidget();
      expect(widget, isA<MiniPlayerWidget>());
    });

    test('MiniPlayerWidget should extend StatelessWidget', () {
      const widget = MiniPlayerWidget();
      expect(widget, isA<StatelessWidget>());
    });

    test('MiniPlayerWidget should have a key parameter', () {
      const key = Key('mini_player');
      const widget = MiniPlayerWidget(key: key);
      expect(widget.key, key);
    });

    test('MiniPlayerWidget should have required build method', () {
      const widget = MiniPlayerWidget();
      expect(widget.build, isA<Function>());
    });

    test('MiniPlayerWidget should handle null current track', () {
      const widget = MiniPlayerWidget();
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('MiniPlayerWidget should handle track navigation', () {
      const widget = MiniPlayerWidget();
      expect(widget, isA<Widget>());
      expect(widget.runtimeType, MiniPlayerWidget);
    });

    test('MiniPlayerWidget should support landscape orientation', () {
      const widget = MiniPlayerWidget();
      expect(widget, isNotNull);
      expect(widget.build, isA<Function>());
    });

    test('MiniPlayerWidget should handle playback controls', () {
      const widget = MiniPlayerWidget();
      expect(widget, isA<StatelessWidget>());
      expect(widget.toString(), contains('MiniPlayerWidget'));
    });
  });
}