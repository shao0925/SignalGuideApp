import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImagePreviewPage extends StatelessWidget {
  final String imageUrl;

  const ImagePreviewPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
        ),
      ),
    );
  }
}
