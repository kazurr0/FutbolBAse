class Player {
  Player({
    required this.id,
    required this.number,
    required this.name,
    required this.onField,
    this.playedSeconds = 0,
    this.goals = 0,
  });

  final String id;
  final int number;
  final String name;
  bool onField;
  int playedSeconds;
  int goals;
}
