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
                if (state.orientation == OrientationMode.splitLandscape)
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 2,
                      height: double.infinity,
                      color: Colors.red.withOpacity(
                        0.5,
                      ), // Static splitter indicator
                    ),
                  ),
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
                Expanded(
                  child: Stack(
                    children: [
                      Center(child: _createPaintArea(state)),
                      if (state.orientation == OrientationMode.splitLandscape)
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 2,
                            height: double.infinity,
                            color: Colors.red.withOpacity(
                              0.5,
                            ), // Static splitter indicator
                          ),
                        ),
                    ],
                  ),
                ),
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
      case OrientationMode.splitLandscape:
        return 2.0;
    }
  }

  Future<void> _exportImage(CropState state) async {
    try {
      final boundary =
          previewKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Export logic for splitLandscape
      if (state.orientation == OrientationMode.splitLandscape &&
          state.images.isNotEmpty) {
        // Get the full image
        final ui.Image fullImage = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await fullImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData == null) return;

        final fullBytes = byteData.buffer.asUint8List();
        final decodedImage = await decodeImageFromList(fullBytes);

        if (decodedImage != null) {
          final halfWidth = decodedImage.width ~/ 2;
          final squareSize = decodedImage.height; // Ensure square crops

          // Crop the left square
          final pictureRecorderLeft = ui.PictureRecorder();
          final canvasLeft = Canvas(pictureRecorderLeft);
          final paintLeft = Paint();
          canvasLeft.drawImageRect(
            fullImage,
            Rect.fromLTWH(0, 0, halfWidth.toDouble(), squareSize.toDouble()),
            Rect.fromLTWH(0, 0, squareSize.toDouble(), squareSize.toDouble()),
            paintLeft,
          );
          final croppedLeftImage = pictureRecorderLeft.endRecording().toImage(
            squareSize,
            squareSize,
          );
          final leftByteData = await (await croppedLeftImage).toByteData(
            format: ui.ImageByteFormat.png,
          );
          final leftBytes = leftByteData?.buffer.asUint8List();

          // Crop the right square
          final pictureRecorderRight = ui.PictureRecorder();
          final canvasRight = Canvas(pictureRecorderRight);
          final paintRight = Paint();
          canvasRight.drawImageRect(
            fullImage,
            Rect.fromLTWH(
              halfWidth.toDouble(),
              0,
              halfWidth.toDouble(),
              squareSize.toDouble(),
            ),
            Rect.fromLTWH(0, 0, squareSize.toDouble(), squareSize.toDouble()),
            paintRight,
          );
          final croppedRightImage = pictureRecorderRight.endRecording().toImage(
            squareSize,
            squareSize,
          );
          final rightByteData = await (await croppedRightImage).toByteData(
            format: ui.ImageByteFormat.png,
          );
          final rightBytes = rightByteData?.buffer.asUint8List();

          if (leftBytes != null && rightBytes != null) {
            final baseName = state.images.first.uri.pathSegments.last
                .split('.')
                .first;
            await _saveSplitImages(state, leftBytes, rightBytes, baseName);
          }
        }
      } else {
        // Export the entire image for other orientations
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return;
        final bytes = byteData.buffer.asUint8List();
        await _saveImage(state, bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _saveSplitImages(
    CropState state,
    Uint8List leftBytes,
    Uint8List rightBytes,
    String baseName,
  ) async {
    if (Platform.isAndroid) {
      final picturesDir = Directory('$androidImagesPath/FLRAMES');
      if (!await picturesDir.exists())
        await picturesDir.create(recursive: true);

      final leftFile = File('${picturesDir.path}/${baseName}_left.png');
      final rightFile = File('${picturesDir.path}/${baseName}_right.png');

      await rightFile.writeAsBytes(rightBytes);
      await leftFile.writeAsBytes(leftBytes);

      MediaScanner.loadMedia(path: leftFile.path);
      MediaScanner.loadMedia(path: rightFile.path);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to ${picturesDir.path}')));
      }
    } else if (Platform.isWindows) {
      final typeGroup = XTypeGroup(label: 'png', extensions: ['png']);
      final leftPath = await getSaveLocation(
        suggestedName: '${baseName}_left.png',
        acceptedTypeGroups: [typeGroup],
      );
      final rightPath = await getSaveLocation(
        suggestedName: '${baseName}_right.png',
        acceptedTypeGroups: [typeGroup],
      );

      if (leftPath != null && rightPath != null) {
        await File(leftPath.path).writeAsBytes(leftBytes);
        await File(rightPath.path).writeAsBytes(rightBytes);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved images successfully.')));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export not yet supported on this platform.'),
          ),
        );
      }
    }
  }

  Future<void> _saveImage(CropState state, Uint8List bytes) async {
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
      final file = File(path.path);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export not yet supported on this platform.'),
          ),
        );
      }
    }
  }
}
