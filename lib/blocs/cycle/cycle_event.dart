abstract class CycleEvent {
  const CycleEvent();
}

class CycleStartRequested extends CycleEvent {
  const CycleStartRequested();
}

class CycleEndRequested extends CycleEvent {
  const CycleEndRequested();
}

class CycleLogSymptomRequested extends CycleEvent {
  final String mood;
  final List<String> symptoms;
  final String flow;
  final String? notes;

  const CycleLogSymptomRequested({
    required this.mood,
    required this.symptoms,
    required this.flow,
    this.notes,
  });
}

class CycleFetchRequested extends CycleEvent {
  final String userId;

  const CycleFetchRequested(this.userId);
}

class CycleLengthUpdated extends CycleEvent {
  final int length;

  const CycleLengthUpdated(this.length);
}






