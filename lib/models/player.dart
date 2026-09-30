class Player {
  Player({
    required this.id,
    required this.number,
    required this.name,
    required this.onField,
    bool? started,
    this.playedSeconds = 0,
    this.goals = 0,
  }) : started = started ?? onField;

  final String id;
  final int number;
  final String name;
  bool onField;
  final bool started;
  int playedSeconds;
  int goals;

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'name': name,
        'onField': onField,
        'started': started,
        'playedSeconds': playedSeconds,
        'goals': goals,
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    final onField = json['onField'] as bool? ?? false;
    return Player(
      id: json['id'] as String,
      number: json['number'] as int,
      name: json['name'] as String,
      onField: onField,
      started: json['started'] as bool? ?? onField,
      playedSeconds: json['playedSeconds'] as int? ?? 0,
      goals: json['goals'] as int? ?? 0,
    );
  }
}
