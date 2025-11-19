import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import '../utils/constants.dart';
import '../providers/crop_state.dart';
import '../widgets/crop_canvas.dart';
import '../widgets/frame_overlay.dart';
import '../widgets/side_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey previewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<CropState>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insta Cropper'),
        actions: [
          IconButton(
            icon: Icon(state.darkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => state.toggleDarkMode(),
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: () => _exportImage(state),
          ),
        ],
      ),
      body: isMobile
          ? Stack(
              children: [
                Center(child: _createPaintArea(state)),
                DraggableScrollableSheet(
                  initialChildSize: 0.12,
                  minChildSize: 0.08,
                  maxChildSize: 0.6,
                  builder: (context, controller) =>
                      SidePanel(scrollController: controller),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: Center(child: _createPaintArea(state))),
                SizedBox(width: 340, child: SidePanel()),
              ],
            ),
    );
  }

  RepaintBoundary _createPaintArea(CropState state) {
    return RepaintBoundary(
      key: previewKey,
      child: AspectRatio(
        aspectRatio: _aspectForMode(state.orientation),
        child: ClipRRect(
          child: Container(
            color: state.backgroundColor,
            child: InteractiveViewer(
              panEnabled: true, // Enable panning
              scaleEnabled: true, // Enable zooming
              minScale: 0.5, // Minimum zoom scale
              maxScale: 5.0, // Maximum zoom scale
              child: Stack(
                children: [
                  const CropCanvas(),
                  const FrameOverlay(),
                  if (state.watermarkText.isNotEmpty)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Text(
                        state.watermarkText,
                        style: state.watermarkStyle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _aspectForMode(OrientationMode mode) {
    switch (mode) {
      case OrientationMode.portrait:
        return 4 / 5;
      case OrientationMode.square:
        return 1.0;
      case OrientationMode.landscape:
        return 191 / 100;
    }
  }

  Future<void> _exportImage(CropState state) async {
    try {
      final boundary =
          previewKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      if (Platform.isAndroid) {
        final picturesDir = Directory('$androidImagesPath/FLRAMES');
        if (!await picturesDir.exists())
          await picturesDir.create(recursive: true);
        final fileName = state.images.length == 1
            ? state.images.first.uri.pathSegments.last
            : state.images
                      .map((img) => img.uri.pathSegments.last.split('.').first)
                      .join('_') +
                  '.png';
        final file = File('${picturesDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        // Notify the gallery about the new image
        MediaScanner.loadMedia(path: file.path);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
        }
      } else if (Platform.isWindows) {
        final suggestedName = state.images.length == 1
            ? state.images.first.uri.pathSegments.last
            : state.images
                      .map((img) => img.uri.pathSegments.last.split('.').first)
                      .join('_') +
                  '.png';
        final typeGroup = XTypeGroup(label: 'png', extensions: ['png']);
        final path = await getSaveLocation(
          suggestedName: suggestedName,
          acceptedTypeGroups: [typeGroup],
        );
        if (path == null) return;
        final path_str = path.path;
        final file = File(path_str);
        await file.writeAsBytes(bytes);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export not yet supported on this platform.'),
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
