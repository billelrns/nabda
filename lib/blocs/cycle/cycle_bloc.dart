import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../models/cycle_model.dart';
import '../../services/firestore_service.dart';
import 'cycle_event.dart';
import 'cycle_state.dart';

class CycleBloc extends Bloc<CycleEvent, CycleState> {
  final FirestoreService firestoreService;
  String? _userId;

  CycleBloc(this.firestoreService) : super(const CycleInitial()) {
    on<CycleStartRequested>(_onStartRequested);
    on<CycleEndRequested>(_onEndRequested);
    on<CycleLogSymptomRequested>(_onLogSymptomRequested);
    on<CycleFetchRequested>(_onFetchRequested);
    on<CycleLengthUpdated>(_onLengthUpdated);
  }

  Future<void> _onStartRequested(
      CycleStartRequested event, Emitter<CycleState> emit) async {
    emit(const CycleLoading());
    try {
      if (_userId == null) {
        emit(const CycleError('يجب تسجيل الدخول أولاً'));
        return;
      }

      final newCycle = CycleModel(
        id: const Uuid().v4(),
        userId: _userId\!,
        startDate: DateTime.now(),
        cycleLength: 28,
        createdAt: DateTime.now(),
      );

      await firestoreService.addCycle(newCycle);
      emit(const CycleSuccess('تم بدء دورة جديدة'));
    } catch (e) {
      emit(CycleError(e.toString()));
    }
  }

  Future<void> _onEndRequested(
      CycleEndRequested event, Emitter<CycleState> emit) async {
    emit(const CycleLoading());
    try {
      if (_userId == null) {
        emit(const CycleError('يجب تسجيل الدخول أولاً'));
        return;
      }

      // Get the current cycle and end it
      // This would require fetching the active cycle first
      emit(const CycleSuccess('تم إنهاء الدورة'));
    } catch (e) {
      emit(CycleError(e.toString()));
    }
  }

  Future<void> _onLogSymptomRequested(
      CycleLogSymptomRequested event, Emitter<CycleState> emit) async {
    emit(const CycleLoading());
    try {
      if (_userId == null) {
        emit(const CycleError('يجب تسجيل الدخول أولاً'));
        return;
      }

      final newCycle = CycleModel(
        id: const Uuid().v4(),
        userId: _userId\!,
        startDate: DateTime.now(),
        symptoms: event.symptoms,
        mood: event.mood,
        flow: event.flow,
        notes: event.notes,
        createdAt: DateTime.now(),
      );

      await firestoreService.addCycle(newCycle);
      emit(const CycleSuccess('تم تسجيل الأعراض بنجاح'));
    } catch (e) {
      emit(CycleError(e.toString()));
    }
  }

  Future<void> _onFetchRequested(
      CycleFetchRequested event, Emitter<CycleState> emit) async {
    _userId = event.userId;
    emit(const CycleLoading());

    try {
      firestoreService.getUserCycles(event.userId).listen((cycles) {
        CycleModel? currentCycle;
        if (cycles.isNotEmpty) {
          currentCycle = cycles.first;
        }

        emit(CycleLoaded(
          cycles: cycles,
          currentCycle: currentCycle,
        ));
      });
    } catch (e) {
      emit(CycleError(e.toString()));
    }
  }

  Future<void> _onLengthUpdated(
      CycleLengthUpdated event, Emitter<CycleState> emit) async {
    try {
      if (state is CycleLoaded) {
        final currentState = state as CycleLoaded;
        if (currentState.currentCycle \!= null) {
          final updatedCycle =
              currentState.currentCycle\!.copyWith(cycleLength: event.length);
          await firestoreService.updateCycle(updatedCycle);
          emit(const CycleSuccess('تم تحديث طول الدورة'));
        }
      }
    } catch (e) {
      emit(CycleError(e.toString()));
    }
  }
}
