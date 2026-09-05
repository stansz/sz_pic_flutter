import 'package:flutter_test/flutter_test.dart';
import 'package:sz_pic_flutter/core/models/photo_filter.dart';

void main() {
  group('PhotoFilter.fromType', () {
    test('maps every filter type to itself', () {
      for (final type in PhotoFilterType.values) {
        expect(PhotoFilter.fromType(type).type, type);
      }
    });

    test('all non-original filters have a color matrix; Original has none', () {
      for (final type in PhotoFilterType.values) {
        final filter = PhotoFilter.fromType(type);
        if (type == PhotoFilterType.none) {
          expect(filter.colorFilter, isNull,
              reason: 'Original must render unfiltered');
        } else {
          expect(filter.colorFilter, isNotNull,
              reason: '${type.name} must apply a ColorFilter');
        }
      }
    });
  });

  group('PhotoFilterType metadata', () {
    test('display names are unique and non-empty', () {
      final names = PhotoFilterType.values.map((t) => t.displayName).toList();
      expect(names.every((n) => n.isNotEmpty), isTrue);
      expect(names.toSet().length, names.length);
    });

    test('descriptions are non-empty', () {
      for (final type in PhotoFilterType.values) {
        expect(type.description, isNotEmpty);
      }
    });
  });
}
