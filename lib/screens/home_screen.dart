import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/image_picker_service.dart';
import '../core/widgets/loading_dialog.dart';
import 'collage/collage_creator_screen.dart';
import 'slideshow/slideshow_creator_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Debug logging for landscape navigation bar
    final viewPadding = MediaQuery.of(context).viewPadding;
    debugPrint('=== HomeScreen Debug ===');
    debugPrint('viewPadding: bottom=${viewPadding.bottom}');
    debugPrint('viewInsets: bottom=${MediaQuery.of(context).viewInsets.bottom}');
    debugPrint('orientation: ${MediaQuery.of(context).orientation}');
    
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.only(bottom: viewPadding.bottom), // Add bottom padding for navigation bar
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.secondary.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SZ Picture Create',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Collage & Slideshow Creator',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Main Menu Cards
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16), // Add some top spacing for scroll
                        _MenuCard(
                          icon: Icons.grid_on_rounded,
                          title: 'Create Collage',
                          subtitle: 'Combine photos into beautiful layouts',
                          color: theme.colorScheme.primary,
                          onTap: _isLoading ? null : () => _navigateToCollageCreator(context),
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 16),
                        _MenuCard(
                          icon: Icons.slideshow_rounded,
                          title: 'Create Slideshow',
                          subtitle: 'Make animated photo presentations',
                          color: theme.colorScheme.secondary,
                          onTap: _isLoading ? null : () => _navigateToSlideshowCreator(context),
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 16), // Add some bottom spacing for scroll
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'v0.5',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToCollageCreator(BuildContext context) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    // Show loading dialog
    LoadingDialog.show(
      context,
      message: 'Preparing your images...',
      showProgress: false,
    );

    try {
      final imagePickerService = context.read<ImagePickerService>();
      
      // Pick images first
      final images = await imagePickerService.pickMultipleImages();
      
      // Hide loading dialog
      if (mounted) {
        LoadingDialog.hide(context);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (images.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No images selected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CollageCreatorScreen(images: images),
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog on error
      if (mounted) {
        LoadingDialog.hide(context);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading images: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _navigateToSlideshowCreator(BuildContext context) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    // Show loading dialog
    LoadingDialog.show(
      context,
      message: 'Preparing your images...',
      showProgress: false,
    );

    try {
      final imagePickerService = context.read<ImagePickerService>();
      
      // Pick images first
      final images = await imagePickerService.pickMultipleImages();
      
      // Hide loading dialog
      if (mounted) {
        LoadingDialog.hide(context);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (images.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No images selected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SlideshowCreatorScreen(initialImages: images),
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog on error
      if (mounted) {
        LoadingDialog.hide(context);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading images: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature is under development and will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(
                        icon,
                        size: 32,
                        color: color,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLoading)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
