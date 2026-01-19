// Copyright (c) 2026
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

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
