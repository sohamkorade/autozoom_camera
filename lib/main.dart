import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  // ensure camera is initialized
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  // get the first camera
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: CaptureImage(
        camera: firstCamera,
      ),
    ),
  );
}

class CaptureImage extends StatefulWidget {
  const CaptureImage({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  CaptureImageState createState() => CaptureImageState();
}

class CaptureImageState extends State<CaptureImage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  double zoom = 1.0;
  double minZoom = 0.0;
  double maxZoom = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    // initialize the controller
    _initializeControllerFuture =
        Future<void>(() => _controller.initialize().then((value) => {
              _controller.getMinZoomLevel().then((value) => {minZoom = value}),
              _controller.getMaxZoomLevel().then((value) => {maxZoom = value}),
              _controller.setZoomLevel(zoom)
            }));
  }

  @override
  void dispose() {
    // dispose controller
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autozoom Camera')),
      // show loading until camera is initialized
      body: Column(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          // zoom slider
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Slider(
                  value: zoom,
                  min: minZoom,
                  max: maxZoom,
                  onChanged: (value) {
                    setState(() {
                      zoom = value;
                      _controller.setZoomLevel(zoom);
                    });
                  },
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            // ensure camera is initialized
            await _initializeControllerFuture;

            // take picture
            final image = await _controller.takePicture();

            if (!mounted) return;

            // display picture
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ImagePreview(
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            // display error
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: Center(
                    child: Text(e.toString()),
                  ),
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class ImagePreview extends StatelessWidget {
  final String imagePath;

  const ImagePreview({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Preview')),
      body: Image.file(File(imagePath)),
    );
  }
}
