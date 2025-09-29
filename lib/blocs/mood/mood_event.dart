part of 'mood_bloc.dart';

@immutable
abstract class MoodEvent {}

class FetchMoods extends MoodEvent {
  final DateTime date;

  FetchMoods({required this.date});
}
