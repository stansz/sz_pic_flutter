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

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_models.dart';
import 'ai_provider.dart';

/// Ollama AI provider implementation
class OllamaProvider implements AIProvider {
  final Dio _dio;
  
  @override
  final AIProviderConfig config;

  OllamaProvider({
    required this.config,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: config.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
            ));

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get('/api/tags');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<LayoutSuggestionResponse> getLayoutSuggestions(
    LayoutSuggestionRequest request,
  ) async {
    try {
      final prompt = _buildLayoutPrompt(request);
      final response = await _generateCompletion(prompt);
      
      return _parseLayoutResponse(response);
    } catch (e) {
      throw Exception('Failed to get layout suggestions: $e');
    }
  }

  @override
  Future<List<AIRecommendation>> getColorSchemeRecommendations(
    List<String> imagePaths,
  ) async {
    try {
      final prompt = _buildColorSchemePrompt(imagePaths.length);
      final response = await _generateCompletion(prompt);
      
      return _parseColorSchemeResponse(response);
    } catch (e) {
      throw Exception('Failed to get color scheme recommendations: $e');
    }
  }

  @override
  Future<String> generateRecommendation(String prompt) async {
    try {
      return await _generateCompletion(prompt);
    } catch (e) {
      throw Exception('Failed to generate recommendation: $e');
    }
  }

  Future<String> _generateCompletion(String prompt) async {
    try {
      final response = await _dio.post(
        '/api/generate',
        data: {
          'model': config.model,
          'prompt': prompt,
          'stream': false,
          ...?config.additionalParams,
        },
      );

      if (response.statusCode == 200) {
        return response.data['response'] as String? ?? '';
      } else {
        throw Exception('Ollama API returned status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate completion: $e');
    }
  }

  String _buildLayoutPrompt(LayoutSuggestionRequest request) {
    final buffer = StringBuffer();
    buffer.writeln('You are a professional designer specializing in photo collages.');
    buffer.writeln('Task: Suggest ${request.imageCount} image collage layouts.');
    
    if (request.theme != null) {
      buffer.writeln('Theme: ${request.theme}');
    }
    
    if (request.style != null) {
      buffer.writeln('Style: ${request.style}');
    }
    
    buffer.writeln('\nProvide 3 different layout suggestions in JSON format:');
    buffer.writeln('[{');
    buffer.writeln('  "title": "Layout name",');
    buffer.writeln('  "description": "Brief description",');
    buffer.writeln('  "layoutType": "grid|masonry|template|freestyle",');
    buffer.writeln('  "aspectRatio": 1.0,');
    buffer.writeln('  "cells": [{"x": 0, "y": 0, "width": 0.5, "height": 0.5}]');
    buffer.writeln('}]');
    
    return buffer.toString();
  }

  String _buildColorSchemePrompt(int imageCount) {
    return '''
You are a color theory expert. Suggest 3 complementary color schemes for a collage with $imageCount images.

Provide your suggestions in JSON format:
[{
  "title": "Color scheme name",
  "description": "Brief description",
  "colors": ["#RRGGBB", "#RRGGBB", "#RRGGBB"]
}]
''';
  }

  LayoutSuggestionResponse _parseLayoutResponse(String response) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('No JSON found in response');
      }

      final jsonStr = jsonMatch.group(0)!;
      final List<dynamic> layouts = json.decode(jsonStr);

      final suggestions = layouts.map((layout) {
        return AIRecommendation(
          id: const Uuid().v4(),
          type: RecommendationType.collageLayout,
          title: layout['title'] as String? ?? 'Untitled Layout',
          description: layout['description'] as String? ?? '',
          data: {
            'layoutType': layout['layoutType'] as String? ?? 'grid',
            'aspectRatio': layout['aspectRatio'] as double? ?? 1.0,
            'cells': layout['cells'] ?? [],
          },
          confidence: 0.8,
          generatedAt: DateTime.now(),
        );
      }).toList();

      return LayoutSuggestionResponse(
        suggestions: suggestions,
        reasoning: response,
      );
    } catch (e) {
      // Fallback: Return a default grid layout
      return LayoutSuggestionResponse(
        suggestions: [
          AIRecommendation(
            id: const Uuid().v4(),
            type: RecommendationType.collageLayout,
            title: 'Simple Grid',
            description: 'A clean grid layout',
            data: {
              'layoutType': 'grid',
              'aspectRatio': 1.0,
              'cells': [],
            },
            confidence: 0.5,
            generatedAt: DateTime.now(),
          ),
        ],
        reasoning: 'Failed to parse AI response, using fallback',
      );
    }
  }

  List<AIRecommendation> _parseColorSchemeResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('No JSON found in response');
      }

      final jsonStr = jsonMatch.group(0)!;
      final List<dynamic> schemes = json.decode(jsonStr);

      return schemes.map((scheme) {
        return AIRecommendation(
          id: const Uuid().v4(),
          type: RecommendationType.colorScheme,
          title: scheme['title'] as String? ?? 'Color Scheme',
          description: scheme['description'] as String? ?? '',
          data: {
            'colors': scheme['colors'] ?? [],
          },
          confidence: 0.8,
          generatedAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
