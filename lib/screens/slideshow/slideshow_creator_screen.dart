import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/image_item.dart';
import '../../core/models/slideshow_models.dart';
import '../../core/services/image_picker_service.dart';
import '../../core/services/slideshow_engine.dart';
import '../../core/widgets/loading_dialog.dart';
import 'slideshow_editor_screen.dart';

class SlideshowCreatorScreen extends StatefulWidget {
  final List<ImageItem>? initialImages;

  const SlideshowCreatorScreen({
    super.key,
    this.initialImages,
  });

  @override
  State<SlideshowCreatorScreen> createState() => _SlideshowCreatorScreenState();
}

class _SlideshowCreatorScreenState extends State<SlideshowCreatorScreen> {
  List<ImageItem> _images = [];
  Duration _slideDuration = const Duration(seconds: 3);
  TransitionType _transitionType = TransitionType.fade;

  final List<TransitionType> _transitionOptions = [
    TransitionType.fade,
    TransitionType.slide,
    TransitionType.zoom,
    TransitionType.dissolve,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialImages != null) {
      _images = widget.initialImages!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Slideshow'),
        actions: [
          if (_images.isNotEmpty)
            TextButton(
              onPressed: _createSlideshow,
              child: const Text('Next'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Image Selection Area
          Expanded(
            child: _images.isEmpty
                ? _buildEmptyState(context)
                : _buildImageGrid(context),
          ),

          // Controls Section
          if (_images.isNotEmpty) _buildControls(context),
        ],
      ),
      floatingActionButton: _images.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _addMoreImages,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Add Photos'),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_rounded,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Photos for Your Slideshow',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Choose photos from your gallery to create a beautiful animated presentation',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Select Photos'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final image = _images[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(image.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => _removeImage(index),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              childCount: _images.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slide Duration
          Row(
            children: [
              const Icon(Icons.timer_rounded),
              const SizedBox(width: 12),
              const Text('Slide Duration'),
              const Spacer(),
              Text(
                '${_slideDuration.inSeconds}s',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _slideDuration.inSeconds.toDouble(),
            min: 1,
            max: 15,
            divisions: 14,
            onChanged: (value) {
              setState(() {
                _slideDuration = Duration(seconds: value.toInt());
              });
            },
          ),

          const SizedBox(height: 16),

          // Transition Type
          Row(
            children: [
              const Icon(Icons.animation_rounded),
              const SizedBox(width: 12),
              const Text('Transition Effect'),
              const Spacer(),
              DropdownButton<TransitionType>(
                value: _transitionType,
                underline: const SizedBox(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _transitionType = value;
                    });
                  }
                },
                items: _transitionOptions.map((type) {
                  final name = type.name;
                  final displayName = name.isEmpty
                      ? name
                      : name[0].toUpperCase() + name.substring(1);
                  return DropdownMenuItem(
                    value: type,
                    child: Text(displayName),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info Row
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                '${_images.length} photos • ${SlideshowEngine.formatDurationLong(_slideDuration * _images.length)} total',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    LoadingDialog.show(
      context,
      message: 'Loading photos...',
      showProgress: false,
    );

    try {
      final imagePickerService = context.read<ImagePickerService>();
      final newImages = await imagePickerService.pickMultipleImages();

      if (mounted) {
        LoadingDialog.hide(context);
      }

      if (newImages.isNotEmpty && mounted) {
        setState(() {
          _images = [..._images, ...newImages];
        });
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading images: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _addMoreImages() {
    _pickImages();
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _createSlideshow() {
    if (_images.isEmpty) return;

    final engine = context.read<SlideshowEngine>();
    final project = engine.createSlideshow(
      images: _images,
      slideDuration: _slideDuration,
      transitionType: _transitionType,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SlideshowEditorScreen(project: project),
      ),
    );
  }
}
