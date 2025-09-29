part of 'chat_bloc.dart';

@immutable
abstract class ChatEvent {}

class FetchMessages extends ChatEvent {}

class LoadMoreMessages extends ChatEvent {}

class SendMessage extends ChatEvent {
  final String message;

  SendMessage({required this.message});
}

class _MessagesUpdated extends ChatEvent {
  final List<QueryDocumentSnapshot> messages;

  _MessagesUpdated({required this.messages});
}
