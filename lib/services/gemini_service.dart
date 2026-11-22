import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class GeminiService {
  static Future<bool> testApiKey(String apiKey, {String model = 'gemini-1.5-flash'}) async {
    if (apiKey.trim().isEmpty) return false;
    final targetModel = model.isNotEmpty ? model : 'gemini-1.5-flash';
    final endpoints = [
      'https://generativelanguage.googleapis.com/v1/models/$targetModel:generateContent?key=${apiKey.trim()}',
      'https://generativelanguage.googleapis.com/v1beta/models/$targetModel:generateContent?key=${apiKey.trim()}',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${apiKey.trim()}',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey.trim()}',
    ];
    for (final ep in endpoints) {
      try {
        final response = await http.post(
          Uri.parse(ep),
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
        if (response.statusCode == 200) return true;
        if (response.statusCode != 404) return false;
      } catch (_) {}
    }
    return false;
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
    "correctIndex": 0,
    "explanation": "Brief explanation of why this answer is correct",
    "subject": "Topic name"
  }
]
Do not wrap with markdown backticks or commentary. Only return raw JSON.
''';

    final targetModel = model.isNotEmpty ? model : 'gemini-1.5-flash';
    final endpoints = [
      'https://generativelanguage.googleapis.com/v1/models/$targetModel:generateContent?key=${apiKey.trim()}',
      'https://generativelanguage.googleapis.com/v1beta/models/$targetModel:generateContent?key=${apiKey.trim()}',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${apiKey.trim()}',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey.trim()}',
    ];

    http.Response? lastResponse;
    for (final ep in endpoints) {
      final response = await http.post(
        Uri.parse(ep),
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
      lastResponse = response;
      if (response.statusCode == 200) {
        break;
      }
      if (response.statusCode != 404) {
        break;
      }
    }

    if (lastResponse == null || lastResponse.statusCode != 200) {
      throw Exception('Gemini API error (${lastResponse?.statusCode ?? "Unknown"}): ${lastResponse?.body ?? "No response"}');
    }

    final Map<String, dynamic> data = jsonDecode(lastResponse.body);
    String responseText = '';
    final List<dynamic>? candidates = data['candidates'] as List<dynamic>?;
    if (candidates != null && candidates.isNotEmpty) {
      final firstCand = candidates[0] as Map<String, dynamic>?;
      final content = firstCand?['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        final firstPart = parts[0] as Map<String, dynamic>?;
        responseText = firstPart?['text']?.toString() ?? '';
      }
    }

    final cleanedJson = responseText.replaceAll(RegExp(r'```json|```'), '').trim();
    final firstBracket = cleanedJson.indexOf('[');
    final lastBracket = cleanedJson.lastIndexOf(']');
    if (firstBracket == -1 || lastBracket == -1 || lastBracket < firstBracket) {
      throw Exception('Could not parse valid question array from AI response:\n$responseText');
    }

    final jsonSubstring = cleanedJson.substring(firstBracket, lastBracket + 1);
    final List<dynamic> parsedList = jsonDecode(jsonSubstring);

    return parsedList.map((item) {
      final map = item as Map<String, dynamic>;
      return QuizQuestion(
        questionText: map['question']?.toString() ?? 'Question',
        optionA: map['optionA']?.toString() ?? 'Option A',
        optionB: map['optionB']?.toString() ?? 'Option B',
        optionC: map['optionC']?.toString() ?? 'Option C',
        optionD: map['optionD']?.toString() ?? 'Option D',
        correctOptionIndex: map['correctIndex'] is int ? map['correctIndex'] as int : 0,
        explanation: map['explanation']?.toString() ?? '',
        subject: map['subject']?.toString() ?? 'AI Quiz',
        examId: examId,
        categoryId: categoryId,
      );
    }).toList();
  }
}
