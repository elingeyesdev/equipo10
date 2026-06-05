import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final String? tag;
  final String? title;
  final String? subtitle;

  const FullScreenImageView({
    super.key,
    required this.imageUrl,
    this.tag,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: title != null ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title!, style: const TextStyle(color: Colors.white, fontSize: 16)),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ) : null,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: tag ?? imageUrl,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.error,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
