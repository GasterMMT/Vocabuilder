class WordBook {
  final int? id;
  final String name;
  final String? description;
  final bool isDefault;
  final DateTime createdAt;

  WordBook({
    this.id,
    required this.name,
    this.description,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  WordBook copyWith({
    int? id,
    String? name,
    String? description,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return WordBook(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WordBook.fromMap(Map<String, dynamic> map) {
    return WordBook(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      isDefault: (map['is_default'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WordBook.fromJson(Map<String, dynamic> json) {
    return WordBook(
      name: json['name'] as String,
      description: json['description'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordBook && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'WordBook(id: $id, name: $name)';
}
