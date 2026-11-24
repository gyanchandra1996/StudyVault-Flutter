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
    {'id': providerGemini, 'name': 'Google Gemini (100% Free)', 'badge': 'FREE'},
    {'id': providerOpenAi, 'name': 'OpenAI ChatGPT (Paid API)', 'badge': 'PAID'},
    {'id': providerClaude, 'name': 'Anthropic Claude (Paid API)', 'badge': 'PAID'},
    {'id': providerDeepSeek, 'name': 'DeepSeek AI (Paid API)', 'badge': 'PAID'},
  ];

  static List<Map<String, String>> getModelsForProvider(String provider) {
    switch (provider) {
      case providerOpenAi:
        return [
          {'id': 'gpt-4o-mini', 'name': 'ChatGPT GPT-4o Mini (Requires Credits)'},
          {'id': 'gpt-4o', 'name': 'ChatGPT GPT-4o (Paid)'},
        ];
      case providerClaude:
        return [
          {'id': 'claude-3-5-haiku-20241022', 'name': 'Claude 3.5 Haiku'},
          {'id': 'claude-3-5-sonnet-20241022', 'name': 'Claude 3.5 Sonnet'},
        ];
      case providerDeepSeek:
        return [
          {'id': 'deepseek-chat', 'name': 'DeepSeek V3 (Chat)'},
          {'id': 'deepseek-reasoner', 'name': 'DeepSeek R1 (Reasoning)'},
        ];
      case providerGemini:
      default:
        return [
          {'id': 'gemini-3.5-flash-lite', 'name': 'Gemini 3.5 Flash Lite (Verified Active • 100% Free)'},
          {'id': 'gemini-flash-lite-latest', 'name': 'Gemini Flash Lite Latest (Fast • 100% Free)'},
          {'id': 'gemini-3.8-flash', 'name': 'Gemini 3.8 Flash (Next-Gen Preview)'},
          {'id': 'gemini-2.0-flash', 'name': 'Gemini 2.0 Flash'},
          {'id': 'gemini-1.5-flash', 'name': 'Gemini 1.5 Flash'},
          {'id': 'gemini-1.5-pro', 'name': 'Gemini 1.5 Pro'},
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
        return 'gemini-3.5-flash-lite';
    }
  }

  static List<String> _getGeminiEndpoints(String model, String apiKey) {
    final key = apiKey.trim();
    final candidateModels = <String>[];
    if (model.trim().isNotEmpty) candidateModels.add(model.trim());
    candidateModels.addAll([
      'gemini-3.5-flash-lite',
      'gemini-flash-lite-latest',
      'gemini-3.8-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ]);
    final seen = <String>{};
    return candidateModels.where((m) => seen.add(m)).map((m) =>
      'https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent?key=$key'
    ).toList();
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
          final endpoints = _getGeminiEndpoints(model, apiKey);
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
              if (response.statusCode != 404 && response.statusCode != 503) return false;
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
Create exactly $count multiple choice questions based on the topic or text below.
If the prompt/topic is in Hindi (हिंदी) or requests Hindi grammar/literature/GK, generate questions, options, and explanations in proper Devanagari Hindi.
Keep explanations concise (under 30 words each) to ensure smooth generation of all $count questions.
Format your response ONLY as a JSON array of objects with these exact keys:
[
  {
    "question": "Question text here (in English or Hindi)",
    "optionA": "Option A text",
    "optionB": "Option B text",
    "optionC": "Option C text",
    "optionD": "Option D text",
    "correctIndex": 0,
    "explanation": "Concise explanation of why this answer is correct",
    "subject": "Topic name"
  }
]
Do not wrap with commentary. Return raw valid JSON.
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
        final endpoints = _getGeminiEndpoints(model, apiKey);

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
                'maxOutputTokens': 8192,
              }
            }),
          );
          lastResponse = response;
          if (response.statusCode == 200) {
            break;
          }
          if (response.statusCode != 404 && response.statusCode != 503) {
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
    if (firstBracket == -1) {
      throw Exception('Could not parse valid question array from AI response:\n$responseText');
    }

    String candidateJson = cleanedJson.substring(firstBracket);
    final lastBracket = candidateJson.lastIndexOf(']');
    if (lastBracket != -1) {
      candidateJson = candidateJson.substring(0, lastBracket + 1);
    } else {
      final lastBrace = candidateJson.lastIndexOf('}');
      if (lastBrace != -1) {
        candidateJson = '${candidateJson.substring(0, lastBrace + 1)}]';
      }
    }

    List<dynamic> parsedList = [];
    try {
      parsedList = jsonDecode(candidateJson) as List<dynamic>;
    } catch (_) {
      final objectMatches = RegExp(r'\{[^{}]*"question"[^{}]*\}', dotAll: true).allMatches(candidateJson);
      for (final m in objectMatches) {
        try {
          final obj = jsonDecode(m.group(0)!) as Map<String, dynamic>;
          if (obj.containsKey('question')) parsedList.add(obj);
        } catch (_) {}
      }
    }

    if (parsedList.isEmpty) {
      throw Exception('Could not parse valid question array from AI response:\n$responseText');
    }

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

  static Future<String> _callAiRaw({
    required String provider,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    List<Map<String, String>> history = const [],
    int maxTokens = 4096,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('API key is not configured for $provider in Settings.');
    }

    switch (provider) {
      case providerOpenAi:
        final messages = <Map<String, String>>[
          {'role': 'system', 'content': systemPrompt},
        ];
        for (final h in history) {
          messages.add({
            'role': h['role'] == 'user' ? 'user' : 'assistant',
            'content': h['content'] ?? '',
          });
        }
        messages.add({'role': 'user', 'content': userPrompt});

        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${apiKey.trim()}',
          },
          body: jsonEncode({
            'model': model.isNotEmpty ? model : 'gpt-4o-mini',
            'messages': messages,
            'temperature': 0.5,
            'max_tokens': maxTokens,
          }),
        );
        if (response.statusCode != 200) {
          throw Exception('OpenAI error (${response.statusCode}): ${response.body}');
        }
        final Map<String, dynamic> data = jsonDecode(response.body);
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final first = choices[0] as Map<String, dynamic>?;
          return first?['message']?['content']?.toString() ?? '';
        }
        return '';

      case providerClaude:
        final messages = <Map<String, String>>[];
        for (final h in history) {
          messages.add({
            'role': h['role'] == 'user' ? 'user' : 'assistant',
            'content': h['content'] ?? '',
          });
        }
        messages.add({'role': 'user', 'content': userPrompt});

        final response = await http.post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey.trim(),
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': model.isNotEmpty ? model : 'claude-3-5-haiku-20241022',
            'max_tokens': maxTokens,
            'system': systemPrompt,
            'messages': messages,
          }),
        );
        if (response.statusCode != 200) {
          throw Exception('Claude error (${response.statusCode}): ${response.body}');
        }
        final Map<String, dynamic> data = jsonDecode(response.body);
        final contentList = data['content'] as List<dynamic>?;
        if (contentList != null && contentList.isNotEmpty) {
          return contentList[0]?['text']?.toString() ?? '';
        }
        return '';

      case providerDeepSeek:
        final messages = <Map<String, String>>[
          {'role': 'system', 'content': systemPrompt},
        ];
        for (final h in history) {
          messages.add({
            'role': h['role'] == 'user' ? 'user' : 'assistant',
            'content': h['content'] ?? '',
          });
        }
        messages.add({'role': 'user', 'content': userPrompt});

        final response = await http.post(
          Uri.parse('https://api.deepseek.com/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${apiKey.trim()}',
          },
          body: jsonEncode({
            'model': model.isNotEmpty ? model : 'deepseek-chat',
            'messages': messages,
            'temperature': 0.5,
            'max_tokens': maxTokens,
          }),
        );
        if (response.statusCode != 200) {
          throw Exception('DeepSeek error (${response.statusCode}): ${response.body}');
        }
        final Map<String, dynamic> data = jsonDecode(response.body);
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final first = choices[0] as Map<String, dynamic>?;
          return first?['message']?['content']?.toString() ?? '';
        }
        return '';

      case providerGemini:
      default:
        final endpoints = _getGeminiEndpoints(model, apiKey);

        final contents = <Map<String, dynamic>>[];
        for (final h in history) {
          contents.add({
            'role': h['role'] == 'user' ? 'user' : 'model',
            'parts': [{'text': h['content'] ?? ''}],
          });
        }
        contents.add({
          'role': 'user',
          'parts': [{'text': '$systemPrompt\n\n$userPrompt'}],
        });

        http.Response? lastResponse;
        for (final ep in endpoints) {
          final res = await http.post(
            Uri.parse(ep),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': contents,
              'generationConfig': {
                'temperature': 0.5,
                'maxOutputTokens': maxTokens,
              }
            }),
          );
          lastResponse = res;
          if (res.statusCode == 200) break;
          if (res.statusCode != 404 && res.statusCode != 503) break;
        }

        if (lastResponse == null || lastResponse.statusCode != 200) {
          throw Exception('Gemini error (${lastResponse?.statusCode ?? "Unknown"}): ${lastResponse?.body ?? "No response"}');
        }

        final Map<String, dynamic> data = jsonDecode(lastResponse.body);
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final firstCand = candidates[0] as Map<String, dynamic>?;
          final content = firstCand?['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]?['text']?.toString() ?? '';
          }
        }
        return '';
    }
  }

  static Future<String> askGeneralAi({
    required String provider,
    required String apiKey,
    required String model,
    required String prompt,
    List<Map<String, String>> history = const [],
    String? contextNotes,
  }) async {
    const systemPrompt = '''
You are StudyVault AI, an expert academic tutor and exam preparation assistant.
Help the student by explaining concepts clearly, answering their questions, solving problems step-by-step, or summarizing study material.
Use clear headings, markdown bullets, bold key terms, and concise examples.
Support both English and Hindi (Devanagari) naturally according to what the student asks.
Keep responses focused, encouraging, and academically accurate.
''';

    final userPrompt = contextNotes != null && contextNotes.trim().isNotEmpty
        ? 'Context notes from document:\n$contextNotes\n\nStudent question:\n$prompt'
        : prompt;

    return _callAiRaw(
      provider: provider,
      apiKey: apiKey,
      model: model,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      history: history,
      maxTokens: 4096,
    );
  }

  static Future<List<Map<String, String>>> generateFlashcards({
    required String provider,
    required String apiKey,
    required String model,
    required String topic,
    int count = 5,
    String? contextNotes,
  }) async {
    final systemPrompt = '''
You are an expert educator and memory retention specialist using spaced repetition.
Create exactly $count high-yield flashcards for the student on the requested topic.
Format your response ONLY as a JSON array of objects with "question" and "answer":
[
  {
    "question": "Clear concept, term, or question",
    "answer": "Concise, memorable answer, formula, or definition"
  }
]
Do not wrap with markdown backticks or extra text. Output valid raw JSON only.
''';

    final userPrompt = contextNotes != null && contextNotes.trim().isNotEmpty
        ? 'Reference Notes:\n$contextNotes\n\nTopic:\n$topic\n\nPlease create $count flashcards.'
        : 'Topic:\n$topic\n\nPlease create $count flashcards.';

    final raw = await _callAiRaw(
      provider: provider,
      apiKey: apiKey,
      model: model,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      maxTokens: 4096,
    );

    final cleaned = raw.replaceAll(RegExp(r'```json|```'), '').trim();
    final firstBracket = cleaned.indexOf('[');
    final lastBracket = cleaned.lastIndexOf(']');
    if (firstBracket == -1 || lastBracket == -1) {
      throw Exception('Could not parse flashcards JSON from AI response:\n$raw');
    }

    final jsonStr = cleaned.substring(firstBracket, lastBracket + 1);
    final List<dynamic> decoded = jsonDecode(jsonStr);

    return decoded.map((item) {
      final map = item as Map<String, dynamic>;
      return {
        'question': map['question']?.toString() ?? '',
        'answer': map['answer']?.toString() ?? '',
      };
    }).where((c) => c['question']!.isNotEmpty && c['answer']!.isNotEmpty).toList();
  }

  static Future<Map<String, dynamic>> generateStudyNotes({
    required String provider,
    required String apiKey,
    required String model,
    required String topic,
    String? contextNotes,
  }) async {
    const systemPrompt = '''
You are an expert academic curriculum designer and textbook author.
Generate a structured, high-yield study notes summary on the requested topic.
Format your response ONLY as a JSON object with these exact keys:
{
  "title": "Document Title",
  "overview": "Comprehensive 2-3 paragraph overview of the subject",
  "keyConcepts": [
    "Key concept 1 with brief explanation",
    "Key concept 2 with brief explanation",
    "Key concept 3 with brief explanation",
    "Key concept 4 with brief explanation"
  ],
  "deepDive": "Detailed in-depth breakdown of the primary principles, mechanisms, formulas, or history",
  "examTakeaways": "High-priority revision checklist and quick exam tips"
}
Do not wrap with markdown backticks. Return valid raw JSON only.
''';

    final userPrompt = contextNotes != null && contextNotes.trim().isNotEmpty
        ? 'Context Notes:\n$contextNotes\n\nTopic:\n$topic'
        : 'Topic:\n$topic';

    final raw = await _callAiRaw(
      provider: provider,
      apiKey: apiKey,
      model: model,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      maxTokens: 8192,
    );

    final cleaned = raw.replaceAll(RegExp(r'```json|```'), '').trim();
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace == -1 || lastBrace == -1) {
      throw Exception('Could not parse study notes JSON from AI response:\n$raw');
    }

    final jsonStr = cleaned.substring(firstBrace, lastBrace + 1);
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded;
  }
}
