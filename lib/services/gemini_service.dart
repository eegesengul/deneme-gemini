import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyCJq08OqlxpNuGVHuunJ4NmSxBxUoEnzuM';
  static const String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

  static Future<String> getGiftSuggestions(String prompt) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
      if (text != null) {
        return text;
      } else {
        throw Exception('Gemini API yanıtı beklenen formatta değil.');
      }
    } else {
      throw Exception(
        'Gemini API hatası: ${response.statusCode}\n${response.body}',
      );
    }
  }
}
