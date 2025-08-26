import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/widgets/action_widgets.dart';

void main() {
  group('TrackActionsWidget Tests', () {
    testWidgets('should render with play button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackActionsWidget(
              showAddButton: false,
              showPlayButton: true,
              trackIsPlaying: false,
              isInPlaylist: false,
              onPlay: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should render with add button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackActionsWidget(
              showAddButton: true,
              showPlayButton: false,
              trackIsPlaying: false,
              isInPlaylist: false,
              onAdd: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should show pause icon when track is playing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackActionsWidget(
              showAddButton: false,
              showPlayButton: true,
              trackIsPlaying: true,
              isInPlaylist: false,
              onPlay: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('should handle AnimatedActionButton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedActionButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedActionButton), findsOneWidget);
    });
  });

  group('FloatingPlayButton Tests', () {
    testWidgets('should render play icon by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingPlayButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should show pause icon when playing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingPlayButton(
              isPlaying: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('should handle onPressed callback', (WidgetTester tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingPlayButton(
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      expect(pressed, isTrue);
    });

    testWidgets('should show custom icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingPlayButton(
              icon: Icons.stop,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('should apply custom background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingPlayButton(
              backgroundColor: Colors.green,
              onPressed: () {},
            ),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.backgroundColor, Colors.green);
    });

    testWidgets('should show loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingPlayButton(
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('should handle mini size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingPlayButton(
              mini: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.mini, isTrue);
    });
  });

  group('SwipeActionWidget Tests', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionWidget(
              child: const Text('Swipe me'),
              onSwipeLeft: () {},
              onSwipeRight: () {},
            ),
          ),
        ),
      );

      expect(find.text('Swipe me'), findsOneWidget);
    });

    testWidgets('should handle swipe left gesture', (WidgetTester tester) async {
      bool swipedLeft = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionWidget(
              child: Container(
                width: 200,
                height: 100,
                color: Colors.blue,
              ),
              onSwipeLeft: () => swipedLeft = true,
              onSwipeRight: () {},
            ),
          ),
        ),
      );

      await tester.drag(find.byType(Container), const Offset(-200, 0));
      await tester.pumpAndSettle();
      
      expect(swipedLeft, isTrue);
    });

    testWidgets('should handle swipe right gesture', (WidgetTester tester) async {
      bool swipedRight = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionWidget(
              child: Container(
                width: 200,
                height: 100,
                color: Colors.blue,
              ),
              onSwipeLeft: () {},
              onSwipeRight: () => swipedRight = true,
            ),
          ),
        ),
      );

      await tester.drag(find.byType(Container), const Offset(200, 0));
      await tester.pumpAndSettle();
      
      expect(swipedRight, isTrue);
    });

    testWidgets('should show left action when swiping right', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionWidget(
              child: Container(
                width: 200,
                height: 100,
                color: Colors.blue,
              ),
              leftAction: const Icon(Icons.favorite, color: Colors.red),
              onSwipeLeft: () {},
              onSwipeRight: () {},
            ),
          ),
        ),
      );

      await tester.drag(find.byType(Container), const Offset(100, 0));
      await tester.pump();
      
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('should show right action when swiping left', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionWidget(
              child: Container(
                width: 200,
                height: 100,
                color: Colors.blue,
              ),
              rightAction: const Icon(Icons.delete, color: Colors.red),
              onSwipeLeft: () {},
              onSwipeRight: () {},
            ),
          ),
        ),
      );

      await tester.drag(find.byType(Container), const Offset(-100, 0));
      await tester.pump();
      
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('should respect swipe threshold', (WidgetTester tester) async {
      bool swipedLeft = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionWidget(
              child: Container(
                width: 200,
                height: 100,
                color: Colors.blue,
              ),
              swipeThreshold: 150,
              onSwipeLeft: () => swipedLeft = true,
              onSwipeRight: () {},
            ),
          ),
        ),
      );

      await tester.drag(find.byType(Container), const Offset(-100, 0));
      await tester.pumpAndSettle();
      
      expect(swipedLeft, isFalse);
      
      await tester.drag(find.byType(Container), const Offset(-160, 0));
      await tester.pumpAndSettle();
      
      expect(swipedLeft, isTrue);
    });
  });

  group('ActionButtonGroup Tests', () {
    testWidgets('should render multiple action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButtonGroup(
              buttons: [
                ActionButtonData(
                  text: 'Play',
                  icon: Icons.play_arrow,
                  onPressed: () {},
                ),
                ActionButtonData(
                  text: 'Pause',
                  icon: Icons.pause,
                  onPressed: () {},
                ),
                ActionButtonData(
                  text: 'Stop',
                  icon: Icons.stop,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(3));
    });

    testWidgets('should arrange buttons horizontally by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButtonGroup(
              buttons: [
                ActionButtonData(
                  text: 'First',
                  icon: Icons.first_page,
                  onPressed: () {},
                ),
                ActionButtonData(
                  text: 'Second',
                  icon: Icons.navigate_next,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Column), findsNothing);
    });

    testWidgets('should arrange buttons vertically when specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButtonGroup(
              direction: Axis.vertical,
              buttons: [
                ActionButtonData(
                  text: 'First',
                  icon: Icons.first_page,
                  onPressed: () {},
                ),
                ActionButtonData(
                  text: 'Second',
                  icon: Icons.navigate_next,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('should apply consistent spacing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButtonGroup(
              spacing: 16.0,
              buttons: [
                ActionButtonData(
                  text: 'First',
                  icon: Icons.first_page,
                  onPressed: () {},
                ),
                ActionButtonData(
                  text: 'Second',
                  icon: Icons.navigate_next,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('should handle empty button list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionButtonGroup(
              buttons: [],
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('should handle button callbacks independently', (WidgetTester tester) async {
      bool firstPressed = false;
      bool secondPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButtonGroup(
              buttons: [
                ActionButtonData(
                  text: 'First',
                  icon: Icons.first_page,
                  onPressed: () => firstPressed = true,
                ),
                ActionButtonData(
                  text: 'Second',
                  icon: Icons.navigate_next,
                  onPressed: () => secondPressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('First'));
      expect(firstPressed, isTrue);
      expect(secondPressed, isFalse);
      
      await tester.tap(find.text('Second'));
      expect(secondPressed, isTrue);
    });
  });
}

class ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final ActionButtonSize size;

  const ActionButton({
    Key? key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.size = ActionButtonSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ) : Icon(icon),
      label: isLoading ? Container() : Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),
    );
  }
}

class FloatingPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final bool isLoading;
  final bool mini;

  const FloatingPlayButton({
    Key? key,
    this.isPlaying = false,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.isLoading = false,
    this.mini = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      mini: mini,
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Icon(icon ?? (isPlaying ? Icons.pause : Icons.play_arrow)),
    );
  }
}

class SwipeActionWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Widget? leftAction;
  final Widget? rightAction;
  final double swipeThreshold;

  const SwipeActionWidget({
    Key? key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftAction,
    this.rightAction,
    this.swipeThreshold = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx.abs() > swipeThreshold) {
          if (details.velocity.pixelsPerSecond.dx > 0) {
            onSwipeRight?.call();
          } else {
            onSwipeLeft?.call();
          }
        }
      },
      child: Stack(
        children: [
          if (leftAction != null)
            Positioned(left: 0, top: 0, bottom: 0, child: leftAction!),
          if (rightAction != null)
            Positioned(right: 0, top: 0, bottom: 0, child: rightAction!),
          child,
        ],
      ),
    );
  }
}

class ActionButtonGroup extends StatelessWidget {
  final List<ActionButtonData> buttons;
  final Axis direction;
  final double spacing;

  const ActionButtonGroup({
    Key? key,
    required this.buttons,
    this.direction = Axis.horizontal,
    this.spacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) return Container();
    
    final children = <Widget>[];
    for (int i = 0; i < buttons.length; i++) {
      children.add(ActionButton(
        text: buttons[i].text,
        icon: buttons[i].icon,
        onPressed: buttons[i].onPressed,
      ));
      
      if (i < buttons.length - 1) {
        children.add(SizedBox(
          width: direction == Axis.horizontal ? spacing : 0,
          height: direction == Axis.vertical ? spacing : 0,
        ));
      }
    }
    
    return direction == Axis.horizontal
        ? Row(children: children)
        : Column(children: children);
  }
}

class ActionButtonData {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  const ActionButtonData({
    required this.text,
    required this.icon,
    this.onPressed,
  });
}

enum ActionButtonSize { small, medium, large }
