part of 'chat_bloc.dart';

@immutable
abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<QueryDocumentSnapshot> messages;
  final bool isLoadingMore;

  ChatLoaded({required this.messages, this.isLoadingMore = false});
}

class AITyping extends ChatState {
  final List<QueryDocumentSnapshot> messages;

  AITyping({required this.messages});
}

class ChatError extends ChatState {
  final String message;

  ChatError({required this.message});
}
