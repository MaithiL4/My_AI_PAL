import 'dart:typed_data';

part of 'chat_bloc.dart';

@immutable
abstract class ChatEvent {}

class FetchMessages extends ChatEvent {}

class LoadMoreMessages extends ChatEvent {}

class SendMessage extends ChatEvent {
  final String? message;
  final String? imageUrl;
  final Uint8List? imageBytes;

  SendMessage({this.message, this.imageUrl, this.imageBytes});
}

class _MessagesUpdated extends ChatEvent {
  final List<QueryDocumentSnapshot> messages;

  _MessagesUpdated({required this.messages});
}