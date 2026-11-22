import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class AiService {
  // Provider IDs
  static const String providerGemini = 'gemini';
  static const String providerOpenAi = 'openai';
  static const String providerClaude = 'claude';
  static const String providerDeepSeek = 'deepseek';

  static const List<Map<String, String>> providers = [
    {'id': providerGemini, 'name': 'Google Gemini', 'icon': 'sparkles'},
    {'id': providerOpenAi, 'name': 'OpenAI ChatGPT', 'icon': 'robot'},
    {'id': providerClaude, 'name': 'Anthropic Claude', 'icon': 'brain'},
    {'id': providerDeepSeek, 'name': 'DeepSeek AI', 'icon': 'code'},
  ];

  static List<Map<String, String>> getModelsForProvider(String provider) {
    switch (provider) {
      case providerOpenAi:
        return [
          {'id': 'gpt-4o-mini', 'name': 'ChatGPT GPT-4o Mini (Fast & Smart)'},
          {'id': 'gpt-4o', 'name': 'ChatGPT GPT-4o (High Intelligence)'},
          {'id': 'gpt-3.5-turbo', 'name': 'ChatGPT 3.5 Turbo (Legacy)'},
        ];
      case providerClaude:
        return [
          {'id': 'claude-3-5-sonnet-20241022', 'name': 'Claude 3.5 Sonnet (State-of-the-Art)'},
          {'id': 'claude-3-5-haiku-20241022', 'name': 'Claude 3.5 Haiku (Ultra Fast)'},
        ];
      case providerDeepSeek:
        return [
          {'id': 'deepseek-chat', 'name': 'DeepSeek V3 (Chat & MCQ)'},
          {'id': 'deepseek-reasoner', 'name': 'DeepSeek R1 (Deep Reasoning)'},
        ];
      case providerGemini:
      default:
        return [
          {'id': 'gemini-1.5-flash', 'name': 'Gemini 1.5 Flash (Super Fast)'},
          {'id': 'gemini-1.5-pro', 'name': 'Gemini 1.5 Pro (Deep Analysis)'},
          {'id': 'gemini-2.0-flash', 'name': 'Gemini 2.0 Flash (Next-Gen)'},
        ];
    }
  }

  static String getDefaultModel(String provider) {
    switch (provider) {
      case providerOpenAi:
        return 'gpt-4o-mini';
      case providerClaude:
        return 'claude-3-5-haiku-20241022';
      case providerDeepSeek:
        return 'deepseek-chat';
      case providerGemini:
      default:
        return 'gemini-1.5-flash';
    }
  }

  static Future<bool> testApiKey({
    required String provider,
    required String apiKey,
    required String model,
  }) async {
    if (apiKey.trim().isEmpty) return false;
    try {
      switch (provider) {
        case providerOpenAi:
          final response = await http.post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiKey.trim()}',
            },
            body: jsonEncode({
              'model': model.isNotEmpty ? model : 'gpt-4o-mini',
              'messages': [
                {'role': 'user', 'content': 'Ping test. Reply with OK.'}
              ],
              'max_tokens': 10,
            }),
          );
          return response.statusCode == 200;

        case providerClaude:
          final response = await http.post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey.trim(),
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': model.isNotEmpty ? model : 'claude-3-5-haiku-20241022',
              'max_tokens': 10,
              'messages': [
                {'role': 'user', 'content': 'Ping test. Reply with OK.'}
              ],
            }),
          );
          return response.statusCode == 200;

        case providerDeepSeek:
          final response = await http.post(
            Uri.parse('https://api.deepseek.com/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiKey.trim()}',
            },
            body: jsonEncode({
              'model': model.isNotEmpty ? model : 'deepseek-chat',
              'messages': [
                {'role': 'user', 'content': 'Ping test. Reply with OK.'}
              ],
              'max_tokens': 10,
            }),
          );
          return response.statusCode == 200;

        case providerGemini:
        default:
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
    } catch (_) {
      return false;
    }
  }

  static Future<List<QuizQuestion>> generateQuestions({
    required String provider,
    required String apiKey,
    required String model,
    required String prompt,
    int count = 5,
    int? examId,
    int? categoryId,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('API Key is not configured for $provider. Please add it in Settings.');
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

    String responseText = '';

    switch (provider) {
      case providerOpenAi:
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${apiKey.trim()}',
          },
          body: jsonEncode({
            'model': model.isNotEmpty ? model : 'gpt-4o-mini',
            'messages': [
              {'role': 'system', 'content': systemInstruction},
              {'role': 'user', 'content': 'Generate quiz for topic / text:\n$prompt'}
            ],
            'temperature': 0.4,
          }),
        );
        if (response.statusCode != 200) {
          throw Exception('OpenAI API error (${response.statusCode}): ${response.body}');
        }
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic>? choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final firstChoice = choices[0] as Map<String, dynamic>?;
          final message = firstChoice?['message'] as Map<String, dynamic>?;
          responseText = message?['content']?.toString() ?? '';
        }
        break;

      case providerClaude:
        final response = await http.post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey.trim(),
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': model.isNotEmpty ? model : 'claude-3-5-haiku-20241022',
            'max_tokens': 2048,
            'system': systemInstruction,
            'messages': [
              {'role': 'user', 'content': 'Generate quiz for topic / text:\n$prompt'}
            ],
          }),
        );
        if (response.statusCode != 200) {
          throw Exception('Claude API error (${response.statusCode}): ${response.body}');
        }
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic>? contentList = data['content'] as List<dynamic>?;
        if (contentList != null && contentList.isNotEmpty) {
          final firstBlock = contentList[0] as Map<String, dynamic>?;
          responseText = firstBlock?['text']?.toString() ?? '';
        }
        break;

      case providerDeepSeek:
        final response = await http.post(
          Uri.parse('https://api.deepseek.com/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${apiKey.trim()}',
          },
          body: jsonEncode({
            'model': model.isNotEmpty ? model : 'deepseek-chat',
            'messages': [
              {'role': 'system', 'content': systemInstruction},
              {'role': 'user', 'content': 'Generate quiz for topic / text:\n$prompt'}
            ],
            'temperature': 0.4,
          }),
        );
        if (response.statusCode != 200) {
          throw Exception('DeepSeek API error (${response.statusCode}): ${response.body}');
        }
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic>? choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final firstChoice = choices[0] as Map<String, dynamic>?;
          final message = firstChoice?['message'] as Map<String, dynamic>?;
          responseText = message?['content']?.toString() ?? '';
        }
        break;

      case providerGemini:
      default:
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
        break;
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
