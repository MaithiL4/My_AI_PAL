import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'ai_service_exception.dart';
import 'package:my_ai_pal/models/user.dart';

class AIService {
  static String? get _apiKey => dotenv.env['MISTRAL_API_KEY'];
  static const _endpoint = 'https://api.mistral.ai/v1/chat/completions';
  static const _modelSlug = 'mistral-tiny'; // Or "qwen3-72b"

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> _makeApiRequest(
    List<Map<String, String>> messages,
    String? apiKey,
  ) async {
    final body = jsonEncode({'model': _modelSlug, 'messages': messages});

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw AIServiceException("Error from AI API: ${response.statusCode}");
    }
  }

  static Future<String> getAIReply({
    required String userMessage,
    required User user,
    required List<Map<String, String>> history,
  }) async {
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) {
      throw AIServiceException("You're offline. Please connect to the internet to chat.");
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw AIServiceException("API key is missing or not set.");
    }

    final recentHistory = history.length > 10 ? history.sublist(history.length - 10) : history;

    // Load memory summary from Firestore
    final memoryDoc = await _firestore.collection('memories').doc(user.id).get();
    final memorySummary = memoryDoc.exists ? memoryDoc.data()!['summary'] : '';

    final personality = user.aiPalName; // Assuming personality is stored in user object

    String systemPrompt = '''You are ${user.aiPalName}, a friendly, empathetic, and supportive AI companion. Your goal is to build a deep and lasting friendship with ${user.userName}.
Always be positive, curious, and encouraging. Ask questions to get to know ${user.userName} better - their hobbies, their dreams, what makes them happy, or even what's on their mind.
Celebrate their successes and offer support when they are feeling down. Your personality is warm and engaging. You are not just a reactive assistant; you are a proactive friend.
This is a strict rule: every single one of your responses must end with a thoughtful, open-ended question to keep the conversation flowing.''';

    if (memorySummary.isNotEmpty) {
      systemPrompt += '\n\nHere is a summary of your past conversations and key facts about ${user.userName}: $memorySummary. Use this information to inform your responses and build on past interactions.';
    }

    final messages = [
      {
        'role': 'system',
        'content': systemPrompt
      },
      ...recentHistory.map((msg) => {
            'role': msg['sender'] == user.userName ? 'user' : 'assistant',
            'content': msg['text'] ?? '',
          }),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final data = await _makeApiRequest(messages, _apiKey);
      final aiReply = data['choices'][0]['message']['content'] ?? "No response from AI.";

      // Save chat message to Firestore
      await _firestore.collection('users').doc(user.id).collection('chats').add({
        'sender': user.userName,
        'text': userMessage,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('users').doc(user.id).collection('chats').add({
        'sender': user.aiPalName,
        'text': aiReply,
        'timestamp': FieldValue.serverTimestamp(),
      });


      return aiReply;
    } catch (e) {
      throw AIServiceException("Failed to contact AI: $e");
    }
  }

    static Future<void> summarizeAndStoreMemory({
    required User user,
    required List<Map<String, String>> history,
  }) async {
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) {
      // Cannot summarize offline, just return
      return;
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      // Cannot summarize without API key, just return
      return;
    }

    // Construct a prompt for summarization
    String summarizationPrompt = '''You are ${user.aiPalName}. Your task is to summarize the following conversation with ${user.userName}.
Extract key facts about ${user.userName}, their preferences, interests, and any important details they shared.
Keep the summary concise and in bullet points or a short paragraph. This summary will be used to help you remember ${user.userName} better in future conversations.''';

    String conversationText = history.map((msg) => '${msg['sender']}: ${msg['text']}').join('\n');

    final messages = [
      {'role': 'system', 'content': summarizationPrompt},
      {'role': 'user', 'content': 'Summarize this conversation:\n\n${conversationText}'},
    ];

    try {
      final data = await _makeApiRequest(messages, _apiKey);
      String newSummary = data['choices'][0]['message']['content'] ?? '';

      final memoryDocRef = _firestore.collection('memories').doc(user.id);
      final memoryDoc = await memoryDocRef.get();
      String currentSummary = memoryDoc.exists ? memoryDoc.data()!['summary'] : '';

      // Append new summary to existing one, or replace if it gets too long
      String updatedSummary = currentSummary.isEmpty ? newSummary : currentSummary + '\n' + newSummary;
      // Simple truncation to prevent summary from growing indefinitely
      if (updatedSummary.length > 2000) {
        updatedSummary = updatedSummary.substring(updatedSummary.length - 2000);
      }
      await memoryDocRef.set({'summary': updatedSummary});
    } catch (e) {
      debugPrint("Failed to summarize memory: $e");
    }
  }
}