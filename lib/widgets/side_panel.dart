import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/crop_state.dart';
import '../utils/image_utils.dart';

class SidePanel extends StatelessWidget {
  final ScrollController? scrollController;
  const SidePanel({this.scrollController, super.key});

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<CropState>(context);
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Orientation'),
          Wrap(
            spacing: 6,
            children: OrientationMode.values
                .map(
                  (m) => ChoiceChip(
                    label: Text(m.name),
                    selected: s.orientation == m,
                    onSelected: (_) => s.setOrientation(m),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text('Frame'),
          Wrap(
            spacing: 6,
            children: FrameMode.values
                .map(
                  (f) => ChoiceChip(
                    label: Text(f.name),
                    selected: s.frame == f,
                    onSelected: (_) => s.setFrame(f),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text('Border Color'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickColor(context, true),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: s.borderColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.frame == FrameMode.variable
                ? 'Horizontal Border Width'
                : 'Border Width',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${s.borderThickness.toInt()}'),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: s.borderThickness,
                  min: 0,
                  max: 200,
                  onChanged: (v) => s.setBorderThickness(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (s.frame == FrameMode.variable)
            const Text('Vertical Border Width'),
          if (s.frame == FrameMode.variable) const SizedBox(height: 8),
          if (s.frame == FrameMode.variable)
            Row(
              children: [
                Text('${s.borderThickness2.toInt()}'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: s.borderThickness2,
                    min: 0,
                    max: 200,
                    onChanged: (v) => s.setBorderThickness2(v),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          const Text('Background Color'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickColor(context, false),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: s.backgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Rounded corners'),
            value: s.roundedCorners,
            onChanged: (_) => s.toggleRoundedCorners(),
          ),
          if (s.roundedCorners)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('Corner radius'),
                Slider(
                  value: s.cornerRadius,
                  min: 0,
                  max: 300,
                  onChanged: (v) => s.setCornerRadius(v),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  if (s.images.length >= 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Maximum of 4 images allowed.'),
                      ),
                    );
                    return;
                  }
                  final f = await pickImageFromDevice(ImageSource.gallery);
                  if (f != null) s.addImage(f);
                },
                icon: const Icon(Icons.photo),
                label: const Text('Add'),
              ),
              const SizedBox(width: 8),
              if (Platform.isAndroid || Platform.isIOS)
                ElevatedButton.icon(
                  onPressed: () async {
                    final f = await pickImageFromDevice(ImageSource.camera);
                    if (f != null) s.addImage(f);
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (s.images.length >= 2) const Text('Divider Thickness'),
          if (s.images.length >= 2) const SizedBox(height: 8),
          if (s.images.length >= 2)
            Row(
              children: [
                Text('${s.dividerThickness.toInt() * 2}'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: s.dividerThickness,
                    min: 4,
                    max: 50,
                    onChanged: (v) => s.setDividerThickness(v),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          const Text('Images'),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) =>
                s.reorderImages(oldIndex, newIndex),
            children: List.generate(
              s.images.length,
              (i) => ListTile(
                key: ValueKey(s.images[i]),
                leading: Image.file(
                  s.images[i],
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
                title: Text(get_image_name_from_path(s.images[i].path)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => s.removeImage(s.images[i]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _pickColor(BuildContext context, bool border) {
    final s = Provider.of<CropState>(context, listen: false);
    final List<Color> colorChoices = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.limeAccent,
      Colors.grey,
      Colors.blueGrey,
      Colors.white70,
      Colors.black,
      Colors.white,
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...colorChoices.map((color) {
              return GestureDetector(
                onTap: () {
                  if (border) {
                    s.setBorderColor(color);
                  } else {
                    s.setBackgroundColor(color);
                  }
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              );
            }).toList(),
            GestureDetector(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
                child: const Icon(Icons.add, color: Colors.grey),
              ),
              onTap: () async {
                Color? customColor = await showDialog<Color>(
                  context: ctx,
                  builder: (context) {
                    Color? _customColor = Colors.white;
                    return AlertDialog(
                      title: const Text('Select Custom Color'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: Colors.white,
                          onColorChanged: (color) {
                            _customColor = color;
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, _customColor),
                          child: const Text('Select'),
                        ),
                      ],
                    );
                  },
                );

                if (customColor != null) {
                  if (border) {
                    s.setBorderColor(customColor!);
                  } else {
                    s.setBackgroundColor(customColor!);
                  }
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ...existing code...
}
