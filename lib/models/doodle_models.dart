import 'package:flutter/material.dart';

class DoodleStroke {
  DoodleStroke(List<Offset> points) : points = List.unmodifiable(points);

  final List<Offset> points;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'points': points
          .map((point) => <double>[point.dx, point.dy])
          .toList(growable: false),
    };
  }

  factory DoodleStroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? const <dynamic>[];
    return DoodleStroke.fromLegacyPoints(rawPoints);
  }

  factory DoodleStroke.fromLegacyPoints(List<dynamic> rawPoints) {
    return DoodleStroke(
      rawPoints.map((raw) {
        final pair = raw as List<dynamic>;
        return Offset(
          (pair[0] as num).toDouble(),
          (pair[1] as num).toDouble(),
        );
      }).toList(growable: false),
    );
  }

  factory DoodleStroke.fromDynamic(dynamic raw) {
    if (raw is Map) {
      return DoodleStroke.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }

    if (raw is List) {
      return DoodleStroke.fromLegacyPoints(raw);
    }

    throw const FormatException('Unsupported stroke format');
  }
}

class DoodleEntry {
  const DoodleEntry({
    required this.dateKey,
    required this.strokes,
    required this.note,
    required this.prompt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String dateKey;
  final List<DoodleStroke> strokes;
  final String note;
  final String prompt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dateKey': dateKey,
      'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
      'note': note,
      'prompt': prompt,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DoodleEntry.fromJson(Map<String, dynamic> json) {
    final rawStrokes =
        json['strokes'] as List<dynamic>? ?? const <dynamic>[];

    return DoodleEntry(
      dateKey: json['dateKey'] as String,
      strokes: rawStrokes
          .map(DoodleStroke.fromDynamic)
          .toList(growable: false),
      note: json['note'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class DoodleDraft {
  const DoodleDraft({
    required this.dateKey,
    required this.strokes,
    required this.note,
    required this.prompt,
    required this.updatedAt,
  });

  final String dateKey;
  final List<DoodleStroke> strokes;
  final String note;
  final String prompt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dateKey': dateKey,
      'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
      'note': note,
      'prompt': prompt,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DoodleDraft.fromJson(Map<String, dynamic> json) {
    final rawStrokes =
        json['strokes'] as List<dynamic>? ?? const <dynamic>[];

    return DoodleDraft(
      dateKey: json['dateKey'] as String,
      strokes: rawStrokes
          .map(DoodleStroke.fromDynamic)
          .toList(growable: false),
      note: json['note'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
