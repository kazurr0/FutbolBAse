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

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'name': name,
        'onField': onField,
        'playedSeconds': playedSeconds,
        'goals': goals,
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      number: json['number'] as int,
      name: json['name'] as String,
      onField: json['onField'] as bool? ?? false,
      playedSeconds: json['playedSeconds'] as int? ?? 0,
      goals: json['goals'] as int? ?? 0,
    );
  }
}
