import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiHabitSuggestion extends StatefulWidget {
  const GeminiHabitSuggestion({super.key});

  @override
  State<GeminiHabitSuggestion> createState() => _GeminiHabitSuggestionState();
}

class _GeminiHabitSuggestionState extends State<GeminiHabitSuggestion> {
  String result = "";
  bool loading = false;

  Future<void> getHabitSuggestions(String phongCach, {int soLuong = 5}) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => result = "❌ Không tìm thấy GEMINI_API_KEY trong .env");
      return;
    }

    setState(() {
      loading = true;
      result = "";
    });

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey",
    );

    final prompt = """
Hãy gợi ý $soLuong thói quen buổi sáng theo phong cách "$phongCach".
Mỗi thói quen nên có:
- Tên thói quen
- Mô tả ngắn (1-2 câu)
- Lợi ích hoặc lý do nên thực hiện

Trả kết quả bằng tiếng Việt, rõ ràng, dễ đọc.
""";

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          "Không có phản hồi từ Gemini.";
      setState(() {
        result = text;
        loading = false;
      });
    } else {
      setState(() {
        result = "❌ Lỗi: ${response.statusCode}\n${response.body}";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gợi ý thói quen buổi sáng")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => getHabitSuggestions("năng lượng"),
              child: const Text("💪 Gợi ý phong cách năng lượng"),
            ),
            ElevatedButton(
              onPressed: () => getHabitSuggestions("nhẹ nhàng"),
              child: const Text("🌿 Gợi ý phong cách nhẹ nhàng"),
            ),
            ElevatedButton(
              onPressed: () => getHabitSuggestions("tích cực"),
              child: const Text("☀️ Gợi ý phong cách tích cực"),
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(result, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
