import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late final GenerativeModel _model;

  void init() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }
    // Use gemini-1.5-flash for the highest free-tier rate limits
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  Future<Map<String, dynamic>> reviewHostApplication({
    required String title,
    required String location,
    required double price,
    required String bio,
    required String category,
  }) async {
    final prompt =
        '''
    You are an automated AI reviewer for PawStay, a premium pet-sitting marketplace in India. 
    Your task is to review a new host application and decide if they should be accepted.

    Review Criteria:
    1. Title: Must be professional, catchy, and relevant to pet sitting.
    2. Location: Must be a plausible city/area name in India.
    3. Price: Must be between ₹500 and ₹15000 per night.
    4. Category: $category (Ensure the title/bio aligns with this category).
    5. Bio: Must be helpful, professional, warm, and show clear love or experience with pets.

    Application Details:
    - Title: $title
    - Location: $location
    - Price: ₹$price
    - Bio: $bio

    Respond in JSON format ONLY with the following structure:
    {
      "accepted": boolean,
      "reason": "short explanation for the decision",
      "rating": number (between 4.0 and 5.0 for accepted, 0 for rejected)
    }
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final text = response.text;
      if (text == null) {
        // This often happens due to safety filters
        return {
          "accepted": false,
          "reason":
              "Content flagged by safety filters. Please use professional language.",
          "rating": 0,
        };
      }

      // More robust JSON extraction
      final jsonMatch = RegExp(r'\{[\s\S]*\}').stringMatch(text);
      if (jsonMatch == null) {
        debugPrint('Raw AI Output: $text');
        return {
          "accepted": false,
          "reason": "AI response was not in the correct format.",
          "rating": 0,
        };
      }

      return jsonDecode(jsonMatch);
    } catch (e) {
      String errorMessage = "Something went wrong.";
      final errorStr = e.toString();

      if (errorStr.contains('429')) {
        errorMessage =
            "You've hit the Google Gemini Free Limit. Please wait 1 minute before clicking submit again.";
      } else if (errorStr.contains('quota')) {
        errorMessage =
            "Daily AI quota exceeded. Try again tomorrow or use a new Gemini API Key.";
      }

      debugPrint('AI Review Error: $e');
      return {"accepted": false, "reason": errorMessage, "rating": 0};
    }
  }
}
