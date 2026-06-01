import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kulineran/services/location_service.dart';
import 'package:kulineran/services/auth_service.dart';
import 'package:kulineran/services/post_service.dart';
import 'package:kulineran/services/user_service.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final double? userLat;
  final double? userLon;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    this.userLat,
    this.userLon,
    required this.onTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _postService = PostService();
  final _authService = AuthService();
  final _userService = UserService();

  bool _isLiked = false;
  bool _isFavorited = false;
  int _likeCount = 0;
  int _currentImageIndex = 0;

  StreamSubscription? _postSub;
  StreamSubscription? _likeSub;
  StreamSubscription? _favoriteSub;
  StreamSubscription? _uploaderSub;
  String? _uploaderName;

  List<Uint8List> _decodedPhotos = [];
  Uint8List? _decodedSinglePhoto;
  Uint8List? _decodedLegacyUserPhoto;
  Uint8List? _decodedUploaderPhoto;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post['likeCount'] ?? widget.post['favoriteCount'] ?? 0;
    _decodePostImages();
    _subscribeToStreams();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post['postId'] != oldWidget.post['postId']) {
      setState(() {
        _likeCount = widget.post['likeCount'] ?? widget.post['favoriteCount'] ?? 0;
        _currentImageIndex = 0;
      });
      _decodePostImages();
      _subscribeToStreams();
    }
  }

  @override
  void dispose() {
    _postSub?.cancel();
    _likeSub?.cancel();
    _favoriteSub?.cancel();
    _uploaderSub?.cancel();
    super.dispose();
  }

  void _subscribeToStreams() {
    _postSub?.cancel();
    _likeSub?.cancel();
    _favoriteSub?.cancel();
    _uploaderSub?.cancel();

    final uid = _authService.currentUid;
    if (uid == null) return;

    final postId = widget.post['postId'];
    final uploaderUid = widget.post['userId'];

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

    if (uploaderUid != null) {
      _uploaderSub = _userService.getUserStream(uploaderUid).listen((userData) {
        if (userData != null && mounted) {
          Uint8List? decodedUpPhoto;
          final upPhoto = userData['photoBase64'];
          if (upPhoto is String && upPhoto.isNotEmpty) {
            try {
              decodedUpPhoto = base64Decode(upPhoto);
            } catch (_) {}
          }
          setState(() {
            _uploaderName = userData['displayName'];
            _decodedUploaderPhoto = decodedUpPhoto;
          });
        }
      });
    }
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

  Future<void> _confirmDeletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text(
          "Delete Post",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to delete this food spot post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              "Delete",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _postService.deletePost(widget.post['postId']);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post deleted successfully")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting post: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationService = LocationService();
    String distanceStr = '';
    
    if (widget.userLat != null && widget.userLon != null && widget.post['latitude'] != null && widget.post['longitude'] != null) {
      double distance = locationService.distanceBetween(
        widget.userLat!,
        widget.userLon!,
        widget.post['latitude'] as double,
        widget.post['longitude'] as double,
      );
      distanceStr = locationService.formatDistance(distance);
    }

    final displayName = _uploaderName ?? widget.post['userName'] ?? 'Anonymous';

    final timestamp = widget.post['createdAt'];
    String postTime = 'Recently';
    if (timestamp != null) {
      DateTime? dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp is String) {
        dateTime = DateTime.tryParse(timestamp);
      }
      if (dateTime != null) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        postTime = '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header (Avatar + Username + Location + optional Delete Menu)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Row(
                    children: [
                      (() {
                        final activeUserPhoto = _decodedUploaderPhoto ?? _decodedLegacyUserPhoto;
                        if (activeUserPhoto != null && activeUserPhoto.isNotEmpty) {
                          return CircleAvatar(
                            radius: 20,
                            backgroundImage: MemoryImage(activeUserPhoto),
                          );
                        } else {
                          return CircleAvatar(
                            radius: 20,
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                            child: Icon(Icons.person, color: isDark ? Colors.white70 : Colors.black54),
                          );
                        }
                      })(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              distanceStr.isNotEmpty ? "$distanceStr From Your Location" : "Unknown Location",
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.post['userId'] == _authService.currentUid)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDeletePost(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Delete Post",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Large Rounded Spot Image / Carousel
          GestureDetector(
            onTap: widget.onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.1, // slightly taller/square image
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
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Action Row (Heart, Comment, Spacer, Bookmark)
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 28,
                  color: _isLiked ? const Color(0xFFFF7260) : (isDark ? Colors.white : Colors.black),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _toggleLike,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.mode_comment_outlined, size: 26),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onTap,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isFavorited ? Icons.bookmark : Icons.bookmark_border,
                  size: 28,
                  color: _isFavorited ? const Color(0xFFFF7260) : (isDark ? Colors.white : Colors.black),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _toggleFavorite,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Caption Description (Username : Description)
          Builder(
            builder: (context) {
              final description = widget.post['description'] ?? '';
              final isLongDescription = description.length > 100;
              return GestureDetector(
                onTap: widget.onTap,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: "$displayName : ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: isLongDescription
                            ? '${description.substring(0, 100)}... '
                            : description,
                      ),
                      if (isLongDescription)
                        TextSpan(
                          text: 'read more',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 6),
          
          // Post Age Text
          Text(
            postTime,
            style: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleImage(Uint8List imgBytes, bool isDark) {
    return Image.memory(
      imgBytes,
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
    final legacyUserPhoto = widget.post['userPhotoBase64'];
    if (legacyUserPhoto is String && legacyUserPhoto.isNotEmpty) {
      try {
        _decodedLegacyUserPhoto = base64Decode(legacyUserPhoto);
      } catch (_) {}
    } else {
      _decodedLegacyUserPhoto = null;
    }
  }
}