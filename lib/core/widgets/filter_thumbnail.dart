import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/image_item.dart';
import '../models/photo_filter.dart';
import 'filtered_image_preview.dart';

/// Instagram-style filter thumbnail showing preview of the filter applied
class FilterThumbnail extends StatelessWidget {
  final ImageItem image;
  final PhotoFilterType filterType;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterThumbnail({
    super.key,
    required this.image,
    required this.filterType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final filter = PhotoFilter.fromType(filterType);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            // Thumbnail preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(
                          color: theme.colorScheme.primary,
                          width: 3,
                        )
                      : Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                          width: 1,
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FilteredImagePreview(
                    image: kIsWeb && image.bytes != null
                        ? MemoryImage(image.bytes!)
                        : FileImage(File(image.path)) as ImageProvider,
                    filter: filter,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Filter name
            Text(
              filterType.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
