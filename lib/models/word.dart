class Word {
  final int? id;
  final String word;
  final String translation;
  final String partOfSpeech;
  final String? example;
  final String? notes;
  final bool isFavorite;
  final bool? isMastered; // null=not studied, true=mastered, false=not mastered
  final DateTime importTime;
  final DateTime createdAt;

  Word({
    this.id,
    required this.word,
    required this.translation,
    required this.partOfSpeech,
    this.example,
    this.notes,
    this.isFavorite = false,
    this.isMastered,
    DateTime? importTime,
    DateTime? createdAt,
  })  : importTime = importTime ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Word copyWith({
    int? id,
    String? word,
    String? translation,
    String? partOfSpeech,
    String? example,
    String? notes,
    bool? isFavorite,
    bool? isMastered,
    DateTime? importTime,
    DateTime? createdAt,
  }) {
    return Word(
      id: id ?? this.id,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      example: example ?? this.example,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      isMastered: isMastered ?? this.isMastered,
      importTime: importTime ?? this.importTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'word': word,
      'translation': translation,
      'part_of_speech': partOfSpeech,
      'example': example,
      'notes': notes,
      'is_favorite': isFavorite ? 1 : 0,
      if (isMastered != null) 'is_mastered': isMastered! ? 1 : 0,
      'import_time': importTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    final masteredVal = map['is_mastered'] as int?;
    return Word(
      id: map['id'] as int?,
      word: map['word'] as String,
      translation: map['translation'] as String,
      partOfSpeech: map['part_of_speech'] as String,
      example: map['example'] as String?,
      notes: map['notes'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      isMastered: masteredVal == null ? null : masteredVal == 1,
      importTime: DateTime.parse(map['import_time'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      'part_of_speech': partOfSpeech,
      'example': example,
      'notes': notes,
    };
  }

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      word: json['word'] as String,
      translation: json['translation'] as String,
      partOfSpeech: json['part_of_speech'] as String? ?? '',
      example: json['example'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Word &&
        other.word.toLowerCase() == word.toLowerCase() &&
        other.translation == translation &&
        other.partOfSpeech == partOfSpeech;
  }

  @override
  int get hashCode => Object.hash(word.toLowerCase(), translation, partOfSpeech);

  @override
  String toString() => 'Word(id: $id, word: $word, translation: $translation)';
}
