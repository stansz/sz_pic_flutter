import '../models/ai_models.dart';

/// Abstract interface for AI providers
abstract class AIProvider {
  /// Generate layout suggestions based on request
  Future<LayoutSuggestionResponse> getLayoutSuggestions(
    LayoutSuggestionRequest request,
  );

  /// Get color scheme recommendations for a set of images
  Future<List<AIRecommendation>> getColorSchemeRecommendations(
    List<String> imagePaths,
  );

  /// Get general recommendations based on a prompt
  Future<String> generateRecommendation(String prompt);

  /// Check if the provider is available/accessible
  Future<bool> isAvailable();

  /// Get provider configuration
  AIProviderConfig get config;
}
