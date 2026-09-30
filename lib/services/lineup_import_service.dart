import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';

import '../models/player.dart';

class LineupImportResult {
  const LineupImportResult({
    required this.round,
    required this.ourTeam,
    required this.opponent,
    required this.players,
    this.dateText,
    this.field,
  });

  final String round;
  final String ourTeam;
  final String opponent;
  final List<Player> players;
  final String? dateText;
  final String? field;
}

class LineupImportService {
  Future<LineupImportResult?> pickAndImportPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      dialogTitle: 'Selecciona la alineación',
    );
    if (file == null) return null;

    final path = file.path;
    if (path == null || path.isEmpty) {
      throw const FormatException(
        'No se pudo acceder al archivo seleccionado.',
      );
    }

    final doc = await PDFDoc.fromFile(File(path));
    final text = await doc.text;
    return parseFederationLineup(text);
  }

  LineupImportResult parseFederationLineup(String rawText) {
    final text = rawText.replaceAll('\r', '');
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final roundMatch = RegExp(
      r'JORNADA\s+(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    final round = roundMatch?.group(1) ?? '';

    final lineupTeamMatch = RegExp(
      r'ALINEACI[ÓO]N DEL EQUIPO\s+([^\n]+)(?:\n([^\n]+))?',
      caseSensitive: false,
    ).firstMatch(text);

    String ourTeam = '';
    if (lineupTeamMatch != null) {
      final first = lineupTeamMatch.group(1)?.trim() ?? '';
      final second = lineupTeamMatch.group(2)?.trim() ?? '';
      ourTeam = _cleanTeamName('$first $second');
    }

    final matchupLine = lines.firstWhere(
      (line) =>
          line.contains(' - ') &&
          !line.toUpperCase().startsWith('FECHA:') &&
          !line.toUpperCase().contains('FECHA DE'),
      orElse: () => '',
    );

    String opponent = '';
    if (matchupLine.isNotEmpty) {
      final parts = matchupLine.split(' - ');
      if (parts.length >= 2) {
        final left = _cleanTeamName(parts.first);
        final right = _cleanTeamName(parts.sublist(1).join(' - '));

        if (ourTeam.isEmpty) {
          ourTeam = right;
          opponent = left;
        } else {
          opponent = _sameTeam(left, ourTeam) ? right : left;
        }
      }
    }

    final dateMatch = RegExp(
      r'FECHA:\s*([^\n-]+(?:-[^\n-]+){0,2}\s+\d{1,2}:\d{2})',
      caseSensitive: false,
    ).firstMatch(text);

    final fieldMatch = RegExp(
      r'CAMPO:\s*([^\n]+)',
      caseSensitive: false,
    ).firstMatch(text);

    final players = <Player>[
      ..._parseSection(
        lines,
        startLabel: 'JUGADORES TITULARES',
        endLabel: 'JUGADORES SUPLENTES',
        onField: true,
      ),
      ..._parseSection(
        lines,
        startLabel: 'JUGADORES SUPLENTES',
        endLabel: 'REAL FEDERACIÓN',
        onField: false,
      ),
    ];

    if (players.isEmpty) {
      throw const FormatException(
        'No se encontraron jugadores en el PDF.',
      );
    }

    return LineupImportResult(
      round: round,
      ourTeam: ourTeam.isEmpty ? 'Mi equipo' : ourTeam,
      opponent: opponent.isEmpty ? 'Rival' : opponent,
      players: players,
      dateText: dateMatch?.group(1)?.trim(),
      field: fieldMatch?.group(1)?.trim(),
    );
  }

  List<Player> _parseSection(
    List<String> lines, {
    required String startLabel,
    required String endLabel,
    required bool onField,
  }) {
    final start = lines.indexWhere(
      (line) => line.toUpperCase().startsWith(startLabel),
    );
    if (start < 0) return [];

    var end = lines.indexWhere(
      (line) => line.toUpperCase().startsWith(endLabel),
      start + 1,
    );
    if (end < 0) end = lines.length;

    final section = lines.sublist(start + 1, end);
    final players = <Player>[];

    for (var i = 0; i < section.length; i++) {
      final number = int.tryParse(section[i]);
      if (number == null || number < 1 || number > 99) continue;

      String? name;
      for (var j = i + 1; j < section.length && j <= i + 3; j++) {
        final candidate = section[j];
        if (_looksLikePlayerName(candidate)) {
          name = _normalizePlayerName(candidate);
          break;
        }
      }

      if (name == null) continue;

      players.add(
        Player(
          id: number.toString(),
          number: number,
          name: name,
          onField: onField,
        ),
      );
    }

    final unique = <int, Player>{};
    for (final player in players) {
      unique[player.number] = player;
    }
    return unique.values.toList();
  }

  bool _looksLikePlayerName(String value) {
    final upper = value.toUpperCase();
    if (!value.contains(',')) return false;
    if (upper.contains('ENTRENADOR') ||
        upper.contains('DELEGADO') ||
        upper.contains('CAPITÁN') ||
        upper.contains('PORTERO') ||
        upper.contains('BENJAMÍN')) {
      return false;
    }
    return RegExp(r'[A-ZÁÉÍÓÚÜÑ]{2,}').hasMatch(upper);
  }

  String _normalizePlayerName(String raw) {
    final parts = raw.split(',');
    if (parts.length < 2) return _titleCase(raw);

    final surnames = parts.first.trim();
    final givenNames = parts.sublist(1).join(',').trim();
    return _titleCase('$givenNames $surnames');
  }

  String _titleCase(String value) {
    return value
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _cleanTeamName(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s+Nombre del encargado.*', caseSensitive: false), '')
        .trim();
  }

  bool _sameTeam(String a, String b) {
    String normalize(String value) => value
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9ÁÉÍÓÚÜÑ]'), '');
    final na = normalize(a);
    final nb = normalize(b);
    return na == nb || na.contains(nb) || nb.contains(na);
  }
}
