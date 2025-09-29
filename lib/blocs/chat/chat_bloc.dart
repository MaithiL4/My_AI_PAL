import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/services/ai_service.dart';
import 'package:my_ai_pal/services/auth_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final AuthService _authService;
  final AIService _aiService;
  final FirebaseFirestore _firestore;

  StreamSubscription<User?>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  User? _currentUser;

  ChatBloc(this._authService, this._aiService, this._firestore) : super(ChatInitial()) {
    on<FetchMessages>(_onFetchMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<_MessagesUpdated>(_onMessagesUpdated);

    _userSubscription = _authService.currentUser.listen((user) {
      if (user != null) {
        _currentUser = user;
        add(FetchMessages());
      }
    });
  }

  void _onFetchMessages(FetchMessages event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final messages = await _fetchMessages();
      emit(ChatLoaded(messages: messages));
      _subscribeToNewMessages();
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  void _onLoadMoreMessages(LoadMoreMessages event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(ChatLoaded(messages: currentState.messages, isLoadingMore: true));
      try {
        final newMessages = await _fetchMessages(lastDocument: currentState.messages.last);
        emit(ChatLoaded(messages: currentState.messages + newMessages));
      } catch (e) {
        emit(ChatError(message: e.toString()));
      }
    }
  }

  void _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (_currentUser != null) {
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(AITyping(messages: currentState.messages));

        try {
          await _aiService.getAIReply(
            userMessage: event.message,
            user: _currentUser!,
            history: currentState.messages.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'sender': data['sender']?.toString() ?? '',
                'text': data['text']?.toString() ?? '',
              };
            }).toList().cast<Map<String, String>>().reversed.toList(),
          );
        } catch (e) {
          emit(ChatError(message: e.toString()));
        }
      }
    }
  }

  void _onMessagesUpdated(_MessagesUpdated event, Emitter<ChatState> emit) {
    if (state is AITyping) {
      emit(AITyping(messages: event.messages));
    } else {
      emit(ChatLoaded(messages: event.messages));
    }
  }

  Future<List<QueryDocumentSnapshot>> _fetchMessages({DocumentSnapshot? lastDocument}) async {
    if (_currentUser == null) return [];

    Query query = _firestore
        .collection('users')
        .doc(_currentUser!.id)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(20);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  void _subscribeToNewMessages() {
    if (_currentUser == null) return;

    _messagesSubscription?.cancel();
    _messagesSubscription = _firestore
        .collection('users')
        .doc(_currentUser!.id)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      add(_MessagesUpdated(messages: snapshot.docs));
    });
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}
