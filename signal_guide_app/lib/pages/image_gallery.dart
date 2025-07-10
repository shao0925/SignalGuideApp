// image_gallery.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../constants.dart'; // 引入 kHostUrl

class ImageGalleryPage extends StatefulWidget {
  final List<dynamic> steps;
  final int initialIndex;

  const ImageGalleryPage({
    super.key,
    required this.steps,
    required this.initialIndex,
  });

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('圖片預覽 (${_currentIndex + 1}/${widget.steps.length})'),
      ),
      body: PhotoViewGallery.builder(
        pageController: _controller,
        itemCount: widget.steps.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        builder: (context, index) {
          final rawUrl = widget.steps[index]['file'].toString();
          final fileUrl = rawUrl.startsWith('http')
              ? rawUrl
              : '$kHostUrl$rawUrl'; // 可改成 kHostUrl

          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(fileUrl),
            heroAttributes: PhotoViewHeroAttributes(tag: 'step_$index'),
            minScale: PhotoViewComputedScale.contained * 1,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, _) =>
        const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
