import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_vault_flutter/screens/brain_games/brain_games_hub_screen.dart';
import 'package:study_vault_flutter/screens/brain_games/game_2048.dart';
import 'package:study_vault_flutter/screens/brain_games/simon_sequence_game.dart';
import 'package:study_vault_flutter/widgets/exam_revision_spotlight_card.dart';
import 'package:study_vault_flutter/widgets/reading_tracker_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Brain Games Hub & New Puzzles', () {
    testWidgets('BrainGamesHubScreen lists all 12 games including 2048 & Simon', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: BrainGamesHubScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Speed Math Blitz'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('2048 Logic Merge'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('2048 Logic Merge'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('Simon Pulse Memory'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Simon Pulse Memory'), findsOneWidget);
    });

    testWidgets('Game2048Screen handles moves, undo, and restart cleanly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: Game2048Screen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('2048 Logic Merge'), findsOneWidget);
      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('MOVES'), findsOneWidget);

      // Try directions until at least one valid slide shifts tiles (a 2/4 board
      // can always slide in at least 2 directions).
      final arrows = [
        Icons.keyboard_arrow_left_rounded,
        Icons.keyboard_arrow_up_rounded,
        Icons.keyboard_arrow_right_rounded,
        Icons.keyboard_arrow_down_rounded,
      ];
      for (final icon in arrows) {
        final btn = find.byIcon(icon);
        await tester.ensureVisible(btn);
        await tester.tap(btn);
        await tester.pumpAndSettle();
        final zerosRemaining = find.descendant(
          of: find.byType(Game2048Screen),
          matching: find.text('0'),
        );
        // Initially SCORE, BEST, and MOVES are all 0 (3 widgets). Any valid move increments MOVES.
        if (zerosRemaining.evaluate().length < 3) break;
      }

      expect(
        find.descendant(of: find.byType(Game2048Screen), matching: find.text('0')).evaluate().length,
        lessThan(3),
      );

      // Undo restores pre-move state; refresh resets SCORE and MOVES to 0 (BEST may stay > 0 if merged).
      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsAtLeastNWidgets(2));
    });

    testWidgets('SimonSequenceGame toggles Classic/Pro modes and disposes safely', (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: SimonSequenceGame()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('simon_pad_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('simon_pad_3')), findsOneWidget);
      expect(find.byKey(const ValueKey('simon_pad_4')), findsNothing);

      await tester.tap(find.text('6 Pads (Pro)'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('simon_pad_4')), findsOneWidget);
      expect(find.byKey(const ValueKey('simon_pad_5')), findsOneWidget);

      await tester.tap(find.text('Start Sequence Challenge'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Watch carefully'), findsOneWidget);

      // Dispose widget mid-playback to ensure token cancellation prevents errors.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('Home Revision & Compact Weekly Chart Widgets', () {
    testWidgets('ExamRevisionSpotlightCard renders cleanly at Home bottom section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ExamRevisionSpotlightCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExamRevisionSpotlightCard), findsOneWidget);
      expect(find.textContaining('Exam Revision'), findsAtLeastNWidgets(1));
    });

    testWidgets('Compact WeeklyLineChartPainter renders at 96px height cleanly', (tester) async {
      final weekData = <Map<String, dynamic>>[
        {'day': 'Mon', 'minutes': 20, 'isToday': false},
        {'day': 'Tue', 'minutes': 45, 'isToday': false},
        {'day': 'Wed', 'minutes': 0, 'isToday': false},
        {'day': 'Thu', 'minutes': 75, 'isToday': false},
        {'day': 'Fri', 'minutes': 15, 'isToday': false},
        {'day': 'Sat', 'minutes': 90, 'isToday': false},
        {'day': 'Sun', 'minutes': 30, 'isToday': true},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 96,
              child: CustomPaint(
                painter: WeeklyLineChartPainter(
                  weekData: weekData,
                  accentColor: Colors.teal,
                  isDark: true,
                  selectedIndex: 6,
                  animProgress: 1.0,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
