import 'dart:io';
import 'package:flrames/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/crop_state.dart';

class CropCanvas extends StatelessWidget {
  const CropCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<CropState>(context);
    return DragTarget<File>(
      onWillAcceptWithDetails: (data) {
        print('Dragging file: ${data.data.path}');
        return isImageFile(data.data);
      },
      onAcceptWithDetails: (details) {
        final s = Provider.of<CropState>(context, listen: false);
        s.addImage(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        if (state.images.isEmpty) {
          return Center(
            child: Column(
              children: [
                Text(
                  'No images added',
                  style: TextStyle(color: Colors.white70),
                ),
                TextButton(
                  onPressed: () async {
                    // Trigger image selection
                    final s = Provider.of<CropState>(context, listen: false);
                    final f = await pickImageFromDevice(ImageSource.gallery);
                    if (f != null) s.addImage(f);
                  },
                  child: Text("Add Image"),
                ),
              ],
            ),
          );
        }

        final viewers = state.images
            .map((ci) => _ImageViewer(file: ci))
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            if (state.images.length == 1)
              return SizedBox.expand(child: viewers.first);
            return state.orientation == OrientationMode.portrait
                ? Column(
                    children: viewers
                        .map(
                          (v) => Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: state.dividerThickness,
                              ),
                              child: v,
                            ),
                          ),
                        )
                        .toList(),
                  )
                : Row(
                    children: viewers
                        .map(
                          (v) => Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: state.dividerThickness,
                              ),
                              child: v,
                            ),
                          ),
                        )
                        .toList(),
                  );
          },
        );
      },
    );
  }
}

class _ImageViewer extends StatefulWidget {
  final File file;
  const _ImageViewer({required this.file, super.key});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late TransformationController _controller;
  late double _initialScale;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _initialScale = 1.0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitImage());
  }

  void _fitImage() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final image = Image.file(widget.file);
    image.image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((info, _) {
            final w = info.image.width.toDouble();
            final h = info.image.height.toDouble();
            final scale =
                (size.width / w).clamp(0.0, size.height / h) < (size.height / h)
                ? size.width / w
                : size.height / h;
            setState(() {
              _initialScale = scale;
              _controller.value = Matrix4.identity()..scale(scale);
            });
          }),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: InteractiveViewer(
        transformationController: _controller,
        panEnabled: widget.file != null,
        scaleEnabled: widget.file != null,
        minScale: 0.01,
        maxScale: 10.0,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        child: widget.file != null
            ? FittedBox(fit: BoxFit.contain, child: Image.file(widget.file))
            : Center(
                child: Text(
                  'Tap to select an image',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
      ),
    );
  }
}
