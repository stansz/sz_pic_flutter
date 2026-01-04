import 'package:flutter/material.dart';

/// A reusable loading dialog with optional progress indicator
class LoadingDialog extends StatelessWidget {
  final String message;
  final bool showProgress;
  final int? current;
  final int? total;

  const LoadingDialog({
    super.key,
    required this.message,
    this.showProgress = false,
    this.current,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (showProgress && current != null && total != null) ...[
              const SizedBox(height: 12),
              Text(
                'Processing $current of $total images...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: current! / total!,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show the loading dialog
  static void show(
    BuildContext context, {
    required String message,
    bool showProgress = false,
    int? current,
    int? total,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(
        message: message,
        showProgress: showProgress,
        current: current,
        total: total,
      ),
    );
  }

  /// Hide the loading dialog
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}