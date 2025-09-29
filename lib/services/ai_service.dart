import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'ai_service_exception.dart';
import 'package:my_ai_pal/models/user.dart';

class AIService {
  final http.Client _httpClient;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  final String? _apiKey;

  AIService({
    http.Client? httpClient,
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
    required String? apiKey,
  })  : _httpClient = httpClient ?? http.Client(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? Connectivity(),
        _apiKey = apiKey;
  static const _endpoint = 'https://api.mistral.ai/v1/chat/completions';
  static const _modelSlug = 'mistral-tiny'; // Or "qwen3-72b"

  Future<Map<String, dynamic>> _makeApiRequest(
    List<Map<String, String>> messages,
    String? apiKey,
  ) async {
    final body = jsonEncode({'model': _modelSlug, 'messages': messages});

    final response = await _httpClient
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

  Future<String> getAIReply({
    required String userMessage,
    required User user,
    required List<Map<String, String>> history,
  }) async {
    final conn = await _connectivity.checkConnectivity();
    if (conn.contains(ConnectivityResult.none)) {
      throw AIServiceException("You're offline. Please connect to the internet to chat.");
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw AIServiceException("API key is missing or not set.");
    }

    final recentHistory = history.length > 10 ? history.sublist(history.length - 10) : history;

    // Load structured memories from Firestore
    final memoriesSnapshot = await _firestore.collection('memories').doc(user.id).collection('facts').get();
    final memories = memoriesSnapshot.docs.map((doc) => doc.data()['fact'] as String).toList();

    // Fetch latest mood
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

      final updatedConversation = [...history, {'sender': user.userName, 'text': userMessage}, {'sender': user.aiPalName, 'text': aiReply}];
      // Extract and store new memories
      await extractAndStoreMemories(user: user, conversation: updatedConversation.map((e) => Map<String, String>.from(e)).toList());
      // Infer and store mood
      await inferAndStoreMood(user: user, conversation: updatedConversation.map((e) => Map<String, String>.from(e)).toList());

      return aiReply;
    } catch (e, s) {
      throw AIServiceException("Failed to contact AI: $e");
    }
  }

  Future<void> extractAndStoreMemories({
    required User user,
    required List<Map<String, String>> conversation,
  }) async {
    final conn = await _connectivity.checkConnectivity();
    if (conn.contains(ConnectivityResult.none)) {
      return;
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      return;
    }

    String summarizationPrompt = '''Extract key facts about ${user.userName} from the following conversation.
Focus on preferences, interests, and important personal details.
Present each fact as a concise statement. If no new facts are found, respond with "No new facts".

Example format:
- User's favorite color is blue.
- User has a dog named Max.
- User is studying to be a doctor.''';

    String conversationText = conversation.map((msg) => '${msg['sender']}: ${msg['text']}').join('\n');

    final messages = [
      {'role': 'system', 'content': summarizationPrompt},
      {'role': 'user', 'content': 'Extract facts from this conversation:\n\n${conversationText}'},
    ];

    try {
      final data = await _makeApiRequest(messages, _apiKey);
      String newFacts = data['choices'][0]['message']['content'] ?? '';

      if (newFacts.trim().toLowerCase() == 'no new facts') {
        return;
      }

      final factList = newFacts.split('\n').where((fact) => fact.trim().startsWith('-')).map((fact) => fact.trim().substring(1).trim());

      for (final fact in factList) {
        await _firestore.collection('memories').doc(user.id).collection('facts').add({
          'fact': fact,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e, s) {
      debugPrint("Failed to extract and store memories: $e");
    }
  }

  Future<void> inferAndStoreMood({
    required User user,
    required List<Map<String, String>> conversation,
  }) async {
    final conn = await _connectivity.checkConnectivity();
    if (conn.contains(ConnectivityResult.none)) {
      return;
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      return;
    }

    String moodPrompt = '''Analyze the user's messages in this conversation and infer their current mood.
Choose one of the following moods: happy, sad, anxious, neutral, excited, tired.
Respond with only the chosen mood word.

Conversation:
${conversation.where((msg) => msg['sender'] == user.userName).map((msg) => msg['text']).join('\n')}
''';

    final messages = [
      {'role': 'system', 'content': 'You are a mood analyzer. Your task is to infer the user\'s mood from the conversation.'},
      {'role': 'user', 'content': moodPrompt},
    ];

    try {
      final data = await _makeApiRequest(messages, _apiKey);
      String inferredMood = data['choices'][0]['message']['content']?.trim().toLowerCase() ?? 'neutral';

      final validMoods = ['happy', 'sad', 'anxious', 'neutral', 'excited', 'tired'];
      if (!validMoods.contains(inferredMood)) {
        inferredMood = 'neutral';
      }

      await _firestore.collection('moods').doc(user.id).collection('entries').add({
        'mood': inferredMood,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      debugPrint("Failed to infer and store mood: $e\n$s");
    }
  }
}
