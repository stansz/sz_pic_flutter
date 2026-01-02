import 'package:equatable/equatable.dart';

/// Type of AI provider
enum AIProviderType {
  ollama,
  openRouter,
}

/// Configuration for AI provider
class AIProviderConfig extends Equatable {
  final AIProviderType type;
  final String baseUrl;
  final String? apiKey;
  final String model;
  final Map<String, dynamic>? additionalParams;

  const AIProviderConfig({
    required this.type,
    required this.baseUrl,
    this.apiKey,
    required this.model,
    this.additionalParams,
  });

  AIProviderConfig copyWith({
    AIProviderType? type,
    String? baseUrl,
    String? apiKey,
    String? model,
    Map<String, dynamic>? additionalParams,
  }) {
    return AIProviderConfig(
      type: type ?? this.type,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      additionalParams: additionalParams ?? this.additionalParams,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'additionalParams': additionalParams,
    };
  }

  factory AIProviderConfig.fromJson(Map<String, dynamic> json) {
    return AIProviderConfig(
      type: AIProviderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AIProviderType.ollama,
      ),
      baseUrl: json['baseUrl'] as String,
      apiKey: json['apiKey'] as String?,
      model: json['model'] as String,
      additionalParams: json['additionalParams'] as Map<String, dynamic>?,
    );
  }

  /// Default Ollama configuration
  factory AIProviderConfig.defaultOllama() {
    return const AIProviderConfig(
      type: AIProviderType.ollama,
      baseUrl: 'http://localhost:11434',
      model: 'llama3.2-vision',
    );
  }

  /// Default OpenRouter configuration
  factory AIProviderConfig.defaultOpenRouter({required String apiKey}) {
    return AIProviderConfig(
      type: AIProviderType.openRouter,
      baseUrl: 'https://openrouter.ai/api/v1',
      apiKey: apiKey,
      model: 'anthropic/claude-3.5-sonnet',
    );
  }

  @override
  List<Object?> get props => [type, baseUrl, apiKey, model, additionalParams];
}

/// Type of AI recommendation
enum RecommendationType {
  collageLayout,
  colorScheme,
  imageEnhancement,
  slideshowTransition,
  musicSuggestion,
}

/// Represents an AI-generated recommendation
class AIRecommendation extends Equatable {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final double confidence;
  final DateTime generatedAt;

  const AIRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.data,
    this.confidence = 0.0,
    required this.generatedAt,
  });

  AIRecommendation copyWith({
    String? id,
    RecommendationType? type,
    String? title,
    String? description,
    Map<String, dynamic>? data,
    double? confidence,
    DateTime? generatedAt,
  }) {
    return AIRecommendation(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      data: data ?? this.data,
      confidence: confidence ?? this.confidence,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'data': data,
      'confidence': confidence,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      id: json['id'] as String,
      type: RecommendationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecommendationType.collageLayout,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      data: json['data'] as Map<String, dynamic>,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, type, title, description, data, confidence, generatedAt];
}

/// Request for AI layout suggestions
class LayoutSuggestionRequest extends Equatable {
  final int imageCount;
  final List<double>? aspectRatios;
  final String? theme;
  final String? style;
  final Map<String, dynamic>? preferences;

  const LayoutSuggestionRequest({
    required this.imageCount,
    this.aspectRatios,
    this.theme,
    this.style,
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'imageCount': imageCount,
      'aspectRatios': aspectRatios,
      'theme': theme,
      'style': style,
      'preferences': preferences,
    };
  }

  @override
  List<Object?> get props => [imageCount, aspectRatios, theme, style, preferences];
}

/// Response from AI with layout suggestions
class LayoutSuggestionResponse extends Equatable {
  final List<AIRecommendation> suggestions;
  final String? reasoning;

  const LayoutSuggestionResponse({
    required this.suggestions,
    this.reasoning,
  });

  @override
  List<Object?> get props => [suggestions, reasoning];
}
