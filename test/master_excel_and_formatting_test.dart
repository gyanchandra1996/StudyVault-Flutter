import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_vault_flutter/services/master_excel_service.dart';
import 'package:study_vault_flutter/widgets/formatted_ai_text.dart';
import 'package:study_vault_flutter/widgets/reading_tracker_card.dart';

void main() {
  group('MasterExcelService .xlsx roundtrip', () {
    test('builds valid multi-sheet template and parses all data types', () {
      final Uint8List xlsxBytes = MasterExcelService.buildMasterTemplateBytes();
      expect(xlsxBytes.length, greaterThan(500));

      final parsed = MasterExcelService.parseXlsxBytes(xlsxBytes);
      expect(parsed.detectedSheetNames, containsAll(['Handbook', 'Quiz', 'Flashcards', 'Categories', 'Notes']));
      expect(parsed.handbookItems.length, 3);
      expect(parsed.quizItems.length, 2);
      expect(parsed.flashcardItems.length, 2);
      expect(parsed.categoryItems.length, 2);
      expect(parsed.noteItems.length, 1);

      expect(parsed.handbookItems.first.tabName, 'Math Formulas');
      expect(parsed.quizItems.first.correctOptionIndex, 1); // B
      expect(parsed.quizItems.first.category, 'Computer Science');
      expect(parsed.quizItems.first.subcategory, 'Data Structures');
    });

    test('classifies unified single-sheet CSV with Type column', () {
      const csv = 'Type,Category,Subcategory,Title,Formula,Option B,Option C,Option D,Correct Option,Explanation\n'
          'Handbook,Physics,,Ohm Law,V = I × R,,,,,\n'
          'Quiz,Math,Algebra,2 + 2 = ?,3,4,5,6,B,Simple addition\n'
          'Flashcard,Polity,,Art 14,Equality before law,,,,,\n'
          'Note,,,Daily Tip,Revise formulas daily,,,,,\n'
          'Category,Science,Biology,Cell biology notes,,,,,';

      final parsed = MasterExcelService.parseCsvContent(csv);
      expect(parsed.handbookItems.length, 1);
      expect(parsed.quizItems.length, 1);
      expect(parsed.flashcardItems.length, 1);
      expect(parsed.noteItems.length, 1);
      expect(parsed.categoryItems.length, 1);
      expect(parsed.quizItems.first.optionA, '3');
      expect(parsed.quizItems.first.optionB, '4');
      expect(parsed.quizItems.first.correctOptionIndex, 1);
    });
  });

  group('FormattedAiText markdown helpers', () {
    test('strips raw markdown syntax into readable plain text', () {
      const raw = '### Key Formula\n**Area** = `π × r²`\n- First *point*';
      final clean = FormattedAiText.toPlainText(raw);
      expect(clean, contains('Key Formula'));
      expect(clean, contains('Area = π × r²'));
      expect(clean, contains('• First point'));
      expect(clean.contains('###'), isFalse);
      expect(clean.contains('**'), isFalse);
    });

    testWidgets('renders FormattedAiText without crashing on tables, code, and lists', (tester) async {
      const sample = '''
### Study Summary
> **Tip:** Focus on basics.

- Bullet **one** and `inline_code`
1. Step *first*

| Topic | Marks |
|---|---|
| Polity | 20 |

```dart
final x = 10;
```
''';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormattedAiText(
                data: sample,
                textColor: Colors.black87,
                accentColor: Colors.indigo,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Study Summary'), findsOneWidget);
      expect(find.textContaining('Polity'), findsOneWidget);
      expect(find.textContaining('final x = 10;'), findsOneWidget);
    });
  });

  group('WeeklyLineChartPainter on Home', () {
    testWidgets('paints 0m, normal, single-day, and large 1200m datasets cleanly', (tester) async {
      final datasets = <List<Map<String, dynamic>>>[
        [
          {'day': 'Mon', 'minutes': 0, 'isToday': false},
          {'day': 'Tue', 'minutes': 0, 'isToday': false},
          {'day': 'Wed', 'minutes': 0, 'isToday': false},
          {'day': 'Thu', 'minutes': 0, 'isToday': false},
          {'day': 'Fri', 'minutes': 0, 'isToday': false},
          {'day': 'Sat', 'minutes': 0, 'isToday': false},
          {'day': 'Sun', 'minutes': 0, 'isToday': true},
        ],
        [
          {'day': 'Mon', 'minutes': 15, 'isToday': false},
          {'day': 'Tue', 'minutes': 45, 'isToday': false},
          {'day': 'Wed', 'minutes': 0, 'isToday': false},
          {'day': 'Thu', 'minutes': 120, 'isToday': false},
          {'day': 'Fri', 'minutes': 1200, 'isToday': false},
          {'day': 'Sat', 'minutes': 35, 'isToday': false},
          {'day': 'Sun', 'minutes': 60, 'isToday': true},
        ],
        [
          {'day': 'Sun', 'minutes': 25, 'isToday': true},
        ],
      ];

      for (final data in datasets) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 340,
                height: 148,
                child: CustomPaint(
                  painter: WeeklyLineChartPainter(
                    weekData: data,
                    accentColor: Colors.indigo,
                    isDark: false,
                    selectedIndex: 0,
                    animProgress: 1.0,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
