part of 'mood_bloc.dart';

@immutable
abstract class MoodState {}

class MoodInitial extends MoodState {}

class MoodLoading extends MoodState {}

class MoodLoaded extends MoodState {
  final Map<DateTime, List<String>> moods;

  MoodLoaded({required this.moods});
}

class MoodError extends MoodState {
  final String message;

  MoodError({required this.message});
}
