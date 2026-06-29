import 'dart:convert';

import 'package:http/http.dart' as http;

class OllamaMessageService {
  OllamaMessageService({
    http.Client? client,
    this.baseUrl = 'http://127.0.0.1:11434',
    this.model = 'qwen3:4b',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String model;

  void dispose() {
    _client.close();
  }

  Future<String> generateRecruitmentMessage({
    required String title,
    required String categoryLabel,
  }) async {
    final assistantPrefix = '大学生のみなさん、';
    final prompt =
        '<|im_start|>system\n'
        'あなたは面白おかしく大学生向けイベントの短い募集文を書くAIです。'
        '日本語で、説明や思考過程は出さず、面白い1文だけを書いてください。'
        '<|im_end|>\n'
        '<|im_start|>user\n'
        'タイトル: $title\n'
        'カテゴリ: $categoryLabel\n'
        '募集文を面白おかしく1文で作成してください。'
        '<|im_end|>\n'
        '<|im_start|>assistant\n'
        '$assistantPrefix';

    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/generate'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': model,
            'stream': false,
            'raw': true,
            'think': false,
            'prompt': prompt,
            'options': {
              'num_predict': 80,
              'temperature': 0.2,
              'stop': ['。', '!', '？', '<|im_end|>', '<|im_start|>'],
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Ollama returned ${response.statusCode}');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    final generatedText = json is Map<String, dynamic>
        ? json['response'] as String? ?? ''
        : '';
    final cleanedText = _cleanGeneratedText(generatedText);

    if (cleanedText.isEmpty) {
      throw Exception('Ollama returned an empty message');
    }

    return _completeSentence(assistantPrefix, cleanedText);
  }

  String _cleanGeneratedText(String text) {
    var cleaned = text;

    if (cleaned.contains('</think>')) {
      cleaned = cleaned.split('</think>').last;
    }

    cleaned = cleaned.replaceAll(RegExp(r'<think>[\s\S]*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');
    cleaned = cleaned.replaceAll('\n', ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.trim();

    if (cleaned.startsWith('「') && cleaned.endsWith('」')) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }

    return cleaned;
  }

  String _completeSentence(String prefix, String generatedText) {
    final message = generatedText.startsWith(prefix)
        ? generatedText
        : '$prefix$generatedText';

    if (_hasSentenceEnd(message)) {
      return message;
    }

    return '$message。';
  }

  bool _hasSentenceEnd(String text) {
    return text.endsWith('。') || text.endsWith('!') || text.endsWith('？');
  }
}
