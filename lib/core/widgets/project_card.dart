import 'package:flutter/material.dart';
import 'dart:io';
import '../models/project.dart';

/// Widget displaying a single project card
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _getTypeLabel() {
    switch (project.type) {
      case ProjectType.collage:
        return 'Collage';
      case ProjectType.slideshow:
        return 'Slideshow';
      case ProjectType.photo:
        return 'Photo';
    }
  }

  IconData _getTypeIcon() {
    switch (project.type) {
      case ProjectType.collage:
        return Icons.grid_view;
      case ProjectType.slideshow:
        return Icons.slideshow;
      case ProjectType.photo:
        return Icons.photo;
    }
  }

  Color _getTypeColor() {
    switch (project.type) {
      case ProjectType.collage:
        return Colors.blue;
      case ProjectType.slideshow:
        return Colors.purple;
      case ProjectType.photo:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailWidget = project.thumbnailPath != null
        ? Image.file(
            File(project.thumbnailPath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(
                  _getTypeIcon(),
                  size: 40,
                  color: Colors.grey[600],
                ),
              );
            },
          )
        : Container(
            color: Colors.grey[300],
            child: Icon(
              _getTypeIcon(),
              size: 40,
              color: Colors.grey[600],
            ),
          );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  thumbnailWidget,
                  // Type badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(),
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTypeLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Draft indicator
                  if (project.isDraft)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DRAFT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Time ago
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 11,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatTimeAgo(project.updatedAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
