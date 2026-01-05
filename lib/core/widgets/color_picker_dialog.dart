import 'package:flutter/material.dart';

class ColorPickerDialog extends StatelessWidget {
  final int selectedColor;

  const ColorPickerDialog({
    super.key,
    required this.selectedColor,
  });

  static const List<Color> presetColors = [
    Colors.white,
    Colors.black,
    Colors.grey,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Background Color'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current color preview
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Color(selectedColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _colorToHex(Color(selectedColor)),
                  style: TextStyle(
                    color: _getContrastColor(Color(selectedColor)),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Preset colors grid
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: presetColors.length,
              itemBuilder: (context, index) {
                final color = presetColors[index];
                final isSelected = color.value == selectedColor;

                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(color.value),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: _getContrastColor(color),
                            size: 20,
                          )
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Custom color button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCustomColorPicker(context),
                icon: const Icon(Icons.palette),
                label: const Text('Custom Color'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _showCustomColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Color'),
        content: SizedBox(
          width: 300,
          child: ColorPicker(
            selectedColor: Color(selectedColor),
            onColorSelected: (color) {
              Navigator.of(context).pop();
              Navigator.of(context).pop(color.value);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if we should use black or white text
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  static Future<int?> show(BuildContext context, int currentColor) {
    return showDialog<int>(
      context: context,
      builder: (context) => ColorPickerDialog(selectedColor: currentColor),
    );
  }
}

class ColorPicker extends StatefulWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color preview
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Hue slider
        const Text('Hue'),
        Slider(
          value: HSVColor.fromColor(_currentColor).hue,
          min: 0,
          max: 360,
          divisions: 360,
          label: '${HSVColor.fromColor(_currentColor).hue.round()}°',
          onChanged: (hue) {
            final hsv = HSVColor.fromColor(_currentColor);
            setState(() {
              _currentColor = hsv.withHue(hue).toColor();
            });
          },
        ),
        // Saturation slider
        const Text('Saturation'),
        Slider(
          value: HSVColor.fromColor(_currentColor).saturation,
          min: 0,
          max: 1,
          divisions: 100,
          label: '${(HSVColor.fromColor(_currentColor).saturation * 100).round()}%',
          onChanged: (saturation) {
            final hsv = HSVColor.fromColor(_currentColor);
            setState(() {
              _currentColor = hsv.withSaturation(saturation).toColor();
            });
          },
        ),
        // Value (brightness) slider
        const Text('Brightness'),
        Slider(
          value: HSVColor.fromColor(_currentColor).value,
          min: 0,
          max: 1,
          divisions: 100,
          label: '${(HSVColor.fromColor(_currentColor).value * 100).round()}%',
          onChanged: (value) {
            final hsv = HSVColor.fromColor(_currentColor);
            setState(() {
              _currentColor = hsv.withValue(value).toColor();
            });
          },
        ),
        const SizedBox(height: 16),
        // Apply button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.onColorSelected(_currentColor),
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}
