import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/services/auth_service.dart';

part 'mood_event.dart';
part 'mood_state.dart';

class MoodBloc extends Bloc<MoodEvent, MoodState> {
  final AuthService _authService;
  final FirebaseFirestore _firestore;
  StreamSubscription<User?>? _userSubscription;
  User? _currentUser;

  MoodBloc(this._authService, this._firestore) : super(MoodInitial()) {
    on<FetchMoods>(_onFetchMoods);

    _userSubscription = _authService.currentUser.listen((user) {
      if (user != null) {
        _currentUser = user;
        add(FetchMoods(date: DateTime.now()));
      }
    });
  }

  void _onFetchMoods(FetchMoods event, Emitter<MoodState> emit) async {
    if (_currentUser == null) return;
    emit(MoodLoading());
    try {
      final firstDayOfMonth = DateTime(event.date.year, event.date.month, 1);
      final lastDayOfMonth = DateTime(event.date.year, event.date.month + 1, 0);

      final snapshot = await _firestore
          .collection('moods')
          .doc(_currentUser!.id)
          .collection('entries')
          .where('timestamp', isGreaterThanOrEqualTo: firstDayOfMonth)
          .where('timestamp', isLessThanOrEqualTo: lastDayOfMonth)
          .orderBy('timestamp', descending: true)
          .get();

      final Map<DateTime, List<String>> moods = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
        final mood = data['mood'] as String;

        if (moods.containsKey(day)) {
          moods[day]!.add(mood);
        } else {
          moods[day] = [mood];
        }
      }
      emit(MoodLoaded(moods: moods));
    } catch (e) {
      emit(MoodError(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
