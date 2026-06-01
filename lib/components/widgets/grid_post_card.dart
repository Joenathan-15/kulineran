import 'dart:convert';
import 'package:flutter/material.dart';

class GridPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;

  const GridPostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image (Legacy single or first of multiple images)
            (() {
              final photos = post['photosBase64'];
              String? imgBase64;
              if (photos is List && photos.isNotEmpty) {
                imgBase64 = photos.first as String?;
              } else {
                imgBase64 = post['photoBase64'] as String?;
              }

              if (imgBase64 != null && imgBase64.isNotEmpty) {
                return Image.memory(
                  base64Decode(imgBase64),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isDark ? Colors.grey[950] : Colors.grey[100],
                    child: const Icon(Icons.broken_image, size: 30),
                  ),
                );
              } else {
                return Container(
                  color: isDark ? Colors.grey[950] : Colors.grey[100],
                  child: const Icon(Icons.image, size: 30),
                );
              }
            })(),
            
            // Bottom Gradient Overlay for Text Readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            
            // Text Details (Title & Likes)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    post['foodSpotName'] ?? 'Unknown Spot',
                    style: const TextStyle(
                      color: Colors.white,
                      
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Color(0xFFFF7260), // brand coral red
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Liked by ${post['likeCount'] ?? post['favoriteCount'] ?? 0} users",
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 10,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}