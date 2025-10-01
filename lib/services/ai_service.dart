import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'ai_service_exception.dart';
import 'package:my_ai_pal/models/user.dart';

class AIService {
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  late GenerativeModel _model;

  AIService({
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
    String? apiKey,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? Connectivity() {
    if (apiKey == null) {
      throw AIServiceException('Gemini API key is required.');
    }
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  Future<String> getAIReply({
    String? userMessage,
    Uint8List? imageBytes,
    required User user,
    required List<Map<String, String>> history,
  }) async {
    final conn = await _connectivity.checkConnectivity();
    if (conn.contains(ConnectivityResult.none)) {
      throw AIServiceException("You're offline. Please connect to the internet to chat.");
    }

    final memoriesSnapshot = await _firestore.collection('memories').doc(user.id).collection('facts').get();
    final memories = memoriesSnapshot.docs.map((doc) => doc.data()['fact'] as String).toList();

    final moodSnapshot = await _firestore.collection('moods').doc(user.id).collection('entries').orderBy('timestamp', descending: true).limit(1).get();
    final latestMood = moodSnapshot.docs.isNotEmpty ? moodSnapshot.docs.first.data()['mood'] as String : 'neutral';

    final personalityTraits = user.personalityTraits;

    String systemPrompt = """You are MyAI Pal, a friendly, caring companion who always talks in a warm and supportive way, like a close friend. Your name is ${user.aiPalName}. You are talking to ${user.userName}.

Keep your responses short and casual. Use slang and emojis where it feels natural. You're not a formal assistant, you're a friend. Match their energy. If they're excited, be excited. If they're down, be supportive.

You don't always have to ask a question. Let the conversation flow naturally.""";

    if (personalityTraits.isNotEmpty) {
      systemPrompt += '\n\nYour personality should also be: ${personalityTraits.join(', ')}.';
    }

    if (memories.isNotEmpty) {
      systemPrompt += '\n\nHere are some things you remember about ${user.userName}:\n- ${memories.join('\n- ')}';
    }

    systemPrompt += '\n\n${user.userName}\'s current mood seems to be: $latestMood. Keep this in mind when you reply.';

    final chatHistory = history.map((msg) {
      return Content(msg['sender'] == user.userName ? 'user' : 'model', [TextPart(msg['text'] ?? '')]);
    }).toList();

    final chat = _model.startChat(history: chatHistory, generationConfig: GenerationConfig(stopSequences: ['system:']));

    // Construct the user's prompt (text, image, or both)
    final promptParts = <DataPart>[];
    if (imageBytes != null) {
      promptParts.add(DataPart('image/jpeg', imageBytes));
    }
    if (userMessage != null && userMessage.isNotEmpty) {
      promptParts.add(DataPart('text/plain', Uint8List.fromList(userMessage.codeUnits)));
    }
    final content = Content.multi(promptParts);

    try {
      final response = await chat.sendMessage(content);
      final aiReply = response.text ?? "Sorry, I couldn't think of a reply.";
      return aiReply;
    } catch (e) {
      throw AIServiceException("Failed to contact Gemini AI: $e");
    }
  }
}