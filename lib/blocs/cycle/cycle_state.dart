import 'package:equatable/equatable.dart';
import '../../models/cycle_model.dart';

abstract class CycleState extends Equatable {
  const CycleState();

  @override
  List<Object?> get props => [];
}

class CycleInitial extends CycleState {
  const CycleInitial();
}

class CycleLoading extends CycleState {
  const CycleLoading();
}

class CycleLoaded extends CycleState {
  final List<CycleModel> cycles;
  final CycleModel? currentCycle;

  const CycleLoaded({
    required this.cycles,
    this.currentCycle,
  });

  @override
  List<Object?> get props => [cycles, currentCycle];
}

class CycleError extends CycleState {
  final String message;

  const CycleError(this.message);

  @override
  List<Object?> get props => [message];
}

class CycleSuccess extends CycleState {
  final String message;

  const CycleSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
