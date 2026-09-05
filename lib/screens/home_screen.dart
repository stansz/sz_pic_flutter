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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/image_picker_service.dart';
import '../core/services/project_repository.dart';
import '../core/widgets/loading_dialog.dart';
import '../core/widgets/recent_projects_widget.dart';
import '../core/models/project.dart';
import '../core/models/collage_models.dart';
import '../core/models/slideshow_models.dart';
import '../core/models/image_item.dart';
import 'collage/collage_creator_screen.dart';
import 'collage/collage_editor_screen.dart';
import 'slideshow/slideshow_creator_screen.dart';
import 'slideshow/slideshow_editor_screen.dart';
import 'photo_editor/photo_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  List<Project> _recentProjects = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecentProjects();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload drafts when app is resumed (e.g., returning from editor)
    if (state == AppLifecycleState.resumed) {
      _loadRecentProjects();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadRecentProjects() async {
    try {
      debugPrint('=== HomeScreen: Loading recent projects ===');
      final repo = context.read<ProjectRepository>();
      final projects = await repo.getDrafts();
      debugPrint('=== HomeScreen: Loaded ${projects.length} draft(s) ===');
      if (mounted) {
        setState(() {
          _recentProjects = projects.take(10).toList();
        });
        debugPrint('=== HomeScreen: Updated state with ${_recentProjects.length} projects ===');
      }
    } catch (e, stackTrace) {
      debugPrint('=== HomeScreen: Error loading recent projects ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

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
               
              // Recent Projects Widget
              RecentProjectsWidget(
                projects: _recentProjects,
                onProjectTap: _onProjectTap,
                onClearAll: _clearAllDrafts,
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
                        _MenuCard(
                          icon: Icons.edit,
                          title: 'Edit Photo',
                          subtitle: 'Apply film grain and effects',
                          color: theme.colorScheme.tertiary,
                          onTap: _isLoading ? null : () => _navigateToPhotoEditor(context),
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

  Future<void> _navigateToPhotoEditor(BuildContext context) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    // Show loading dialog
    LoadingDialog.show(
      context,
      message: 'Loading image...',
      showProgress: false,
    );

    try {
      final imagePickerService = context.read<ImagePickerService>();
      
      // Pick single image
      final image = await imagePickerService.pickImage();
      
      // Hide loading dialog
      if (mounted) {
        LoadingDialog.hide(context);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PhotoEditorScreen(image: image!),
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
            content: Text('Error loading image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _onProjectTap(Project project) async {
    debugPrint('=== _onProjectTap: Loading project ===');
    debugPrint('Project ID: ${project.id}');
    debugPrint('Project name: ${project.name}');
    debugPrint('Project type: ${project.type}');
    debugPrint('Project data keys: ${project.data.keys}');
    
    try {
      switch (project.type) {
        case ProjectType.collage:
          await _loadCollageProject(project);
          break;
        case ProjectType.slideshow:
          await _loadSlideshowProject(project);
          break;
        case ProjectType.photo:
          await _loadPhotoProject(project);
          break;
      }
    } catch (e, stackTrace) {
      debugPrint('=== _onProjectTap: Error loading project ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load project: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _clearAllDrafts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Drafts'),
        content: const Text(
          'Are you sure you want to delete all draft projects? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = context.read<ProjectRepository>();
        await repo.deleteAllDrafts();
        setState(() {
          _recentProjects = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All drafts deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting drafts: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
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

  Future<void> _loadCollageProject(Project project) async {
    debugPrint('=== Loading collage project ===');
    debugPrint('Project data: ${project.data}');
    
    // Deserialize layout and images from project.data
    final layoutJson = project.data['layout'] as Map<String, dynamic>;
    final imagesJson = project.data['images'] as List;
    
    debugPrint('Layout JSON: $layoutJson');
    debugPrint('Images JSON count: ${imagesJson.length}');
    
    // Import models
    final layout = CollageLayout.fromJson(layoutJson);
    final images = imagesJson
        .map((img) => ImageItem.fromJson(img as Map<String, dynamic>))
        .toList();
    
    debugPrint('Loaded layout with ${layout.cells.length} cells');
    debugPrint('Loaded ${images.length} images');
    
    // Navigate to collage editor
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CollageEditorScreen(
            layout: layout,
            images: images,
          ),
        ),
      );
    }
  }

  Future<void> _loadSlideshowProject(Project project) async {
    debugPrint('=== Loading slideshow project ===');
    debugPrint('Project data: ${project.data}');
    
    // Deserialize SlideshowProject from project.data
    final slideshowProject = SlideshowProject.fromJson(project.data);
    
    debugPrint('Loaded slideshow with ${slideshowProject.slides.length} slides');
    debugPrint('Total duration: ${slideshowProject.totalDuration}');
    debugPrint('Music path: ${slideshowProject.musicPath}');
    
    // Navigate to slideshow editor
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SlideshowEditorScreen(
            project: slideshowProject,
          ),
        ),
      );
    }
  }

  Future<void> _loadPhotoProject(Project project) async {
    debugPrint('=== Loading photo project ===');
    debugPrint('Project data: ${project.data}');
    
    // Deserialize PhotoEditData from project.data
    final photoEditData = PhotoEditData.fromJson(project.data);
    
    debugPrint('Photo edit data imageId: ${photoEditData.imageId}');
    debugPrint('Photo edit data imagePath: ${photoEditData.imagePath}');
    debugPrint('Photo edit data filter: ${photoEditData.filter}');
    
    // Create ImageItem from photo data
    final image = ImageItem(
      id: photoEditData.imageId,
      path: photoEditData.imagePath,
      name: 'Edited Photo',
      addedAt: DateTime.now(),
    );
    
    debugPrint('Created ImageItem: ${image.path}');
    
    // Navigate to photo editor
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PhotoEditorScreen(image: image),
        ),
      );
    }
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
