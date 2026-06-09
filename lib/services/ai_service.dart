import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/llm_config.dart';
import '../models/word.dart';

class AIService {
  final LLMConfig config;

  AIService(this.config);

  String _detectProvider() {
    final url = (config.baseUrl ?? '').toLowerCase();
    if (url.contains('anthropic')) return 'anthropic';
    if (url.contains('googleapis') || url.contains('generativelanguage')) return 'google';
    return 'openai'; // default
  }

  Future<List<Word>> parseWordsFromText(String text) async {
    final prompt = '''You are a vocabulary extraction assistant. Analyze the following text and extract all vocabulary words. For each word, provide:
1. The word itself
2. Chinese translation (中文翻译)
3. Part of speech (词性, e.g. noun/verb/adjective)
4. An example sentence (例句) — MUST be bilingual: first the English sentence, then the Chinese translation separated by " | ". Format: "English sentence. | 中文翻译。"

Return ONLY a JSON array. No other text. Format:
[
  {
    "word": "example",
    "translation": "例子",
    "part_of_speech": "noun",
    "example": "This is an example sentence. | 这是一个例句。"
  }
]

Text to analyze:
$text''';

    final response = await _callAPI(prompt);
    return _parseResponse(response);
  }

  Future<List<Word>> parseWordsFromFileContent(String content, String fileType) async {
    if (fileType == 'json') {
      try {
        final parsed = jsonDecode(content);
        if (parsed is List) return parsed.map((item) => Word.fromJson(item as Map<String, dynamic>)).toList();
        if (parsed is Map && parsed.containsKey('words')) {
          return (parsed['words'] as List).map((item) => Word.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }
    return await parseWordsFromText(content);
  }

  Future<String> _callAPI(String prompt) async {
    final provider = _detectProvider();
    final uri = Uri.parse(config.baseUrl ?? 'https://api.openai.com/v1/chat/completions');
    final headers = _getHeaders(provider);
    final body = _buildRequestBody(prompt, provider);

    try {
      final response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _extractContent(data, provider);
      } else {
        throw Exception('API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Map<String, String> _getHeaders(String provider) {
    switch (provider) {
      case 'anthropic':
        return {'Content-Type': 'application/json', 'x-api-key': config.apiKey, 'anthropic-version': '2023-06-01'};
      case 'google':
        return {'Content-Type': 'application/json', 'x-goog-api-key': config.apiKey};
      default:
        return {'Content-Type': 'application/json', 'Authorization': 'Bearer ${config.apiKey}'};
    }
  }

  Map<String, dynamic> _buildRequestBody(String prompt, String provider) {
    switch (provider) {
      case 'anthropic':
        return {'model': config.model, 'max_tokens': 4096, 'messages': [{'role': 'user', 'content': prompt}]};
      case 'google':
        return {'contents': [{'parts': [{'text': prompt}]}]};
      default:
        return {'model': config.model, 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.3};
    }
  }

  String _extractContent(Map<String, dynamic> data, String provider) {
    switch (provider) {
      case 'anthropic':
        return data['content']?[0]?['text'] ?? '';
      case 'google':
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      default:
        return data['choices']?[0]?['message']?['content'] ?? '';
    }
  }

  List<Word> _parseResponse(String response) {
    try {
      String jsonStr = response.trim();
      final startIndex = jsonStr.indexOf('[');
      final endIndex = jsonStr.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        jsonStr = jsonStr.substring(startIndex, endIndex + 1);
      }
      final List<dynamic> parsed = jsonDecode(jsonStr);
      return parsed.map((item) => Word.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to parse AI response: $e\nResponse: $response');
    }
  }
}
