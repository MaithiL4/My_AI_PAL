import 'package:my_ai_pal/services/ai_service.dart';
import 'package:my_ai_pal/models/user.dart';

class FakeAIService extends AIService {
  String? mockReply;
  bool shouldThrowException = false;

  @override
  Future<String> getAIReply({
    String? userMessage,
    required User user,
    required List<Map<String, String>> history,
  }) async {
    if (shouldThrowException) {
      throw Exception('AI Service Error');
    }
    return mockReply ?? 'Hello from Fake AI';
  }
}
