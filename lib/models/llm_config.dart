class LLMConfig {
  final int? id;
  final String name;
  final String provider; // openai, anthropic, custom
  final String apiKey;
  final String model;
  final String? baseUrl;
  final bool isActive;

  LLMConfig({
    this.id,
    required this.name,
    required this.provider,
    required this.apiKey,
    required this.model,
    this.baseUrl,
    this.isActive = false,
  });

  LLMConfig copyWith({
    int? id,
    String? name,
    String? provider,
    String? apiKey,
    String? model,
    String? baseUrl,
    bool? isActive,
  }) {
    return LLMConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  LLMConfig copyWithObscuredKey() {
    return LLMConfig(
      id: id,
      name: name,
      provider: provider,
      apiKey: _obscureKey(apiKey),
      model: model,
      baseUrl: baseUrl,
      isActive: isActive,
    );
  }

  String _obscureKey(String key) {
    if (key.length <= 8) return '*' * key.length;
    return '${key.substring(0, 4)}${'*' * (key.length - 8)}${key.substring(key.length - 4)}';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'provider': provider,
      'api_key': apiKey,
      'model': model,
      'base_url': baseUrl,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory LLMConfig.fromMap(Map<String, dynamic> map) {
    return LLMConfig(
      id: map['id'] as int?,
      name: map['name'] as String,
      provider: map['provider'] as String,
      apiKey: map['api_key'] as String,
      model: map['model'] as String,
      baseUrl: map['base_url'] as String?,
      isActive: (map['is_active'] as int?) == 1,
    );
  }

  @override
  String toString() => 'LLMConfig(name: $name, provider: $provider, model: $model)';
}
