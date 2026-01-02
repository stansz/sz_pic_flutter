import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/image_item.dart';
import '../../core/models/collage_models.dart';
import '../../core/models/ai_models.dart';
import '../../core/services/collage_engine.dart';
import '../../core/services/ai_provider.dart';
import 'collage_editor_screen.dart';

class CollageCreatorScreen extends StatefulWidget {
  final List<ImageItem> images;

  const CollageCreatorScreen({
    super.key,
    required this.images,
  });

  @override
  State<CollageCreatorScreen> createState() => _CollageCreatorScreenState();
}

class _CollageCreatorScreenState extends State<CollageCreatorScreen> {
  List<CollageLayout>? _layouts;
  bool _isLoadingAI = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateLayouts();
  }

  void _generateLayouts() {
    final collageEngine = context.read<CollageEngine>();
    
    // Generate default layouts
    setState(() {
      _layouts = [
        collageEngine.createGridLayout(
          imageCount: widget.images.length,
        ),
        collageEngine.createMasonryLayout(
          imageCount: widget.images.length,
        ),
        collageEngine.createTemplateLayout(
          imageCount: widget.images.length,
        ),
        collageEngine.createFreestyleLayout(
          imageCount: widget.images.length,
        ),
      ];
    });
  }

  Future<void> _getAISuggestions() async {
    setState(() {
      _isLoadingAI = true;
      _errorMessage = null;
    });

    try {
      final aiProvider = context.read<AIProvider>();
      
      // Check if AI is available
      final isAvailable = await aiProvider.isAvailable();
      if (!isAvailable) {
        setState(() {
          _errorMessage = 'AI provider is not available. Please check your configuration.';
          _isLoadingAI = false;
        });
        return;
      }

      final request = LayoutSuggestionRequest(
        imageCount: widget.images.length,
      );

      final response = await aiProvider.getLayoutSuggestions(request);
      
      if (mounted) {
        _showAISuggestionsDialog(response.suggestions);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get AI suggestions: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingAI = false;
      });
    }
  }

  void _showAISuggestionsDialog(List<AIRecommendation> suggestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 8),
            Text('AI Layout Suggestions'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.withOpacity(0.2),
                    child: Text('${index + 1}'),
                  ),
                  title: Text(suggestion.title),
                  subtitle: Text(suggestion.description),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Apply AI layout
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Applied: ${suggestion.title}'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _selectLayout(CollageLayout layout) {
    final collageEngine = context.read<CollageEngine>();
    final imageIds = widget.images.map((img) => img.id).toList();
    final layoutWithImages = collageEngine.assignImagesToLayout(layout, imageIds);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CollageEditorScreen(
          layout: layoutWithImages,
          images: widget.images,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Layout'),
        actions: [
          IconButton(
            icon: _isLoadingAI
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            tooltip: 'AI Suggestions',
            onPressed: _isLoadingAI ? null : _getAISuggestions,
          ),
        ],
      ),
      body: _layouts == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Image count info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.photo_library,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${widget.images.length} photos selected',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Layout options
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _layouts!.length,
                    itemBuilder: (context, index) {
                      final layout = _layouts![index];
                      return _LayoutPreviewCard(
                        layout: layout,
                        onTap: () => _selectLayout(layout),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _LayoutPreviewCard extends StatelessWidget {
  final CollageLayout layout;
  final VoidCallback onTap;

  const _LayoutPreviewCard({
    required this.layout,
    required this.onTap,
  });

  String _getLayoutName(LayoutType type) {
    switch (type) {
      case LayoutType.grid:
        return 'Grid Layout';
      case LayoutType.masonry:
        return 'Masonry Layout';
      case LayoutType.template:
        return 'Template Layout';
      case LayoutType.freestyle:
        return 'Freestyle Layout';
      case LayoutType.smart:
        return 'AI Smart Layout';
    }
  }

  IconData _getLayoutIcon(LayoutType type) {
    switch (type) {
      case LayoutType.grid:
        return Icons.grid_4x4;
      case LayoutType.masonry:
        return Icons.dashboard_customize;
      case LayoutType.template:
        return Icons.view_quilt;
      case LayoutType.freestyle:
        return Icons.scatter_plot;
      case LayoutType.smart:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: CustomPaint(
                  painter: _LayoutPreviewPainter(
                    layout: layout,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getLayoutIcon(layout.type),
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getLayoutName(layout.type),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${layout.cells.length} cells',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
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

class _LayoutPreviewPainter extends CustomPainter {
  final CollageLayout layout;
  final Color color;

  _LayoutPreviewPainter({
    required this.layout,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final cell in layout.cells) {
      final rect = Rect.fromLTWH(
        cell.x * size.width,
        cell.y * size.height,
        cell.width * size.width,
        cell.height * size.height,
      );

      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(_LayoutPreviewPainter oldDelegate) =>
      oldDelegate.layout != layout || oldDelegate.color != color;
}
