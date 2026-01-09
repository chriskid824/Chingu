import 'package:flutter/material.dart';

class ZoomableImage extends StatelessWidget {
  final ImageProvider imageProvider;
  final String? heroTag;

  const ZoomableImage({
    super.key,
    required this.imageProvider,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: heroTag != null
              ? Hero(
                  tag: heroTag!,
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                  ),
                )
              : Image(
                  image: imageProvider,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}
