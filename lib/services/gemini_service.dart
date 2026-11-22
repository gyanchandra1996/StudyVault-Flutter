import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class GeminiService {
  static Future<bool> testApiKey(String apiKey, {String model = 'gemini-1.5-flash'}) async {
    if (apiKey.trim().isEmpty) return false;
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${apiKey.trim()}',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping test. Reply with OK.'}
              ]
            }
          ]
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<QuizQuestion>> generateQuestions({
    required String apiKey,
    required String prompt,
    int count = 5,
    String model = 'gemini-1.5-flash',
    int? examId,
    int? categoryId,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('Gemini API key is not configured in Settings.');
    }

    final systemInstruction = '''
You are an expert exam preparation quiz master.
Create $count multiple choice questions based on the topic or text below.
Format your response ONLY as a JSON array of objects with these exact keys:
[
  {
    "question": "Question text here (can be in Hindi, English, or bilingual)",
    "optionA": "Option A text",
    "optionB": "Option B text",
    "optionC": "Option C text",
    "optionD": "Option D text",
    "correctIndex": 0, // 0 for A, 1 for B, 2 for C, 3 for D
    "explanation": "Brief explanation of why this answer is correct",
    "subject": "Topic name"
  }
]
Do not wrap with markdown backticks or commentary. Only return raw JSON.
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${apiKey.trim()}',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': '$systemInstruction\n\nTopic / Notes content:\n$prompt'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': 2048,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?[0]?['text'] ??
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
        '';

    final cleanedJson = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final List<dynamic> parsedList = jsonDecode(cleanedJson);

    return parsedList.map((item) {
      return QuizQuestion(
        questionText: item['question'] ?? 'Question',
        optionA: item['optionA'] ?? 'Option A',
        optionB: item['optionB'] ?? 'Option B',
        optionC: item['optionC'] ?? 'Option C',
        optionD: item['optionD'] ?? 'Option D',
        correctOptionIndex: (item['correctIndex'] as int?) ?? 0,
        explanation: item['explanation'] ?? '',
        subject: item['subject'] ?? 'AI Generated',
        examId: examId,
        categoryId: categoryId,
      );
    }).toList();
  }
}
