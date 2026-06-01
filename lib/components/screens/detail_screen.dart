import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:kulineran/components/widgets/comment_tile.dart';
import 'package:kulineran/components/widgets/loading_indicator.dart';
import 'package:kulineran/components/widgets/kulineran_logo.dart';
import 'package:kulineran/components/widgets/custom_text_field.dart';
import 'package:kulineran/components/widgets/primary_button.dart';
import 'package:kulineran/services/auth_service.dart';
import 'package:kulineran/services/post_service.dart';
import 'package:kulineran/services/user_service.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _postService = PostService();
  final _authService = AuthService();
  final _userService = UserService();
  final _commentController = TextEditingController();
  
  bool _isLiked = false;
  bool _isFavorited = false;
  int _likeCount = 0;
  int _currentImageIndex = 0;

  StreamSubscription? _postSub;
  StreamSubscription? _likeSub;
  StreamSubscription? _favoriteSub;

  List<Uint8List> _decodedPhotos = [];
  Uint8List? _decodedSinglePhoto;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post['likeCount'] ?? widget.post['favoriteCount'] ?? 0;
    _decodePostImages();
    _subscribeToStreams();
  }

  @override
  void dispose() {
    _postSub?.cancel();
    _likeSub?.cancel();
    _favoriteSub?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  void _subscribeToStreams() {
    final uid = _authService.currentUid;
    if (uid == null) return;

    final postId = widget.post['postId'];

    _postSub = _postService.getPostStream(postId).listen((postData) {
      if (postData != null && mounted) {
        setState(() {
          _likeCount = postData['likeCount'] ?? postData['favoriteCount'] ?? 0;
        });
      }
    });

    _likeSub = _postService.isLikedStream(uid, postId).listen((isLiked) {
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
        });
      }
    });

    _favoriteSub = _postService.isFavoritedStream(uid, postId).listen((isFavorited) {
      if (mounted) {
        setState(() {
          _isFavorited = isFavorited;
        });
      }
    });
  }

  Future<void> _toggleLike() async {
    final uid = _authService.currentUid;
    if (uid == null) return;

    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !wasLiked;
      _likeCount = wasLiked ? _likeCount - 1 : _likeCount + 1;
    });

    try {
      await _postService.toggleLike(uid, widget.post['postId'], wasLiked);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount = wasLiked ? _likeCount + 1 : _likeCount - 1;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final uid = _authService.currentUid;
    if (uid == null) return;

    final wasFavorited = _isFavorited;
    setState(() {
      _isFavorited = !wasFavorited;
    });

    try {
      await _postService.toggleFavorite(uid, widget.post['postId'], wasFavorited);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFavorited = wasFavorited;
        });
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final uid = _authService.currentUid;
    if (uid == null) return;

    final user = await _userService.getUser(uid);
    final commentText = _commentController.text.trim();
    _commentController.clear();
    
    await _postService.addComment(widget.post['postId'], {
      'userId': uid,
      'userName': user?['displayName'] ?? 'Anonymous',
      'text': commentText,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131313) : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            KulineranLogo(fontSize: 20),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image / Carousel
            SizedBox(
              width: double.infinity,
              height: 250,
              child: Builder(
                builder: (context) {
                  if (_decodedPhotos.isNotEmpty) {
                    if (_decodedPhotos.length == 1) {
                      return _buildSingleImage(_decodedPhotos[0], isDark);
                    }
                    return Stack(
                      children: [
                        PageView.builder(
                          itemCount: _decodedPhotos.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, idx) {
                            return _buildSingleImage(_decodedPhotos[idx], isDark);
                          },
                        ),
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _decodedPhotos.length,
                              (idx) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                height: 6,
                                width: _currentImageIndex == idx ? 16 : 6,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == idx
                                      ? const Color(0xFFFF7260)
                                      : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (_decodedSinglePhoto != null) {
                    return _buildSingleImage(_decodedSinglePhoto!, isDark);
                  }

                  return Container(
                    color: isDark ? Colors.grey[900] : Colors.grey[200],
                    child: const Icon(Icons.image, size: 50),
                  );
                },
              ),
            ),
              
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Spot Name Title
                  Text(
                    widget.post['foodSpotName'] ?? 'Detail',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Action Row (Heart + Bookmark)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Row(
                          children: [
                            Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked ? const Color(0xFFFF7260) : (isDark ? Colors.white : Colors.black),
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Liked by $_likeCount users",
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isFavorited ? Icons.bookmark : Icons.bookmark_border,
                          color: _isFavorited ? const Color(0xFFFF7260) : (isDark ? Colors.white : Colors.black),
                          size: 26,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Spot Description
                  Text(
                    widget.post['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Live Map Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E5E5),
                      ),
                      child: (widget.post['latitude'] != null && widget.post['longitude'] != null)
                          ? FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  widget.post['latitude'] as double,
                                  widget.post['longitude'] as double,
                                ),
                                initialZoom: 15.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.mdp.kulineran',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(
                                        widget.post['latitude'] as double,
                                        widget.post['longitude'] as double,
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Color(0xFFFF7260),
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 40,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Location coordinates not available",
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Comments Section Header
                  const Text(
                    "Comments about this place",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Comments Stream list
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _postService.getComments(widget.post['postId']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingIndicator();
                      }
                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            "No comments yet. Share your experience!",
                            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return CommentTile(comment: comments[index]);
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Comment TextFormField
                  CustomTextField(
                    label: "comments",
                    hintText: "Write your comments on this place",
                    controller: _commentController,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Save Comment Button
                  Center(
                    child: PrimaryButton(
                      text: "Save comment",
                      onPressed: _addComment,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleImage(Uint8List imgBytes, bool isDark) {
    return Image.memory(
      imgBytes,
      width: double.infinity,
      height: 250,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: isDark ? Colors.grey[900] : Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 50),
      ),
    );
  }

  void _decodePostImages() {
    _decodedPhotos.clear();
    final photos = widget.post['photosBase64'];
    if (photos is List) {
      for (var p in photos) {
        if (p is String && p.isNotEmpty) {
          try {
            _decodedPhotos.add(base64Decode(p));
          } catch (_) {}
        }
      }
    }
    final singlePhoto = widget.post['photoBase64'];
    if (singlePhoto is String && singlePhoto.isNotEmpty) {
      try {
        _decodedSinglePhoto = base64Decode(singlePhoto);
      } catch (_) {}
    } else {
      _decodedSinglePhoto = null;
    }
  }
}