import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kulineran/components/widgets/loading_indicator.dart';
import 'package:kulineran/components/widgets/post_card.dart';
import 'package:kulineran/components/widgets/kulineran_logo.dart';
import 'package:kulineran/services/location_service.dart';
import 'package:kulineran/services/post_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _postService = PostService();
  final _locationService = LocationService();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final pos = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    }
  }

  double _calculateScore(Map<String, dynamic> post, Position? currentPosition) {
    final likes = (post['likeCount'] ?? post['favoriteCount'] ?? 0) as num;
    if (currentPosition == null) {
      return likes.toDouble();
    }
    final lat = post['latitude'] as double?;
    final lon = post['longitude'] as double?;
    if (lat == null || lon == null) {
      return likes.toDouble();
    }
    final distanceMeters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      lat,
      lon,
    );
    final distanceKm = distanceMeters / 1000.0;
    return (likes + 1) / (distanceKm + 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131313) : Colors.white,
      appBar: AppBar(
        title: const KulineranLogo(fontSize: 20),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postService.getFeed(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(
              child: Text(
                "No posts yet. Be the first to share!",
                style: TextStyle( fontSize: 13),
              ),
            );
          }

          final sortedPosts = List<Map<String, dynamic>>.from(posts);
          sortedPosts.sort((a, b) {
            final scoreA = _calculateScore(a, _currentPosition);
            final scoreB = _calculateScore(b, _currentPosition);
            if (scoreA != scoreB) {
              return scoreB.compareTo(scoreA); // Descending score
            }
            // Fallback: createdAt descending
            final timeA = a['createdAt'];
            final timeB = b['createdAt'];
            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;
            
            DateTime dtA = timeA is Timestamp ? timeA.toDate() : DateTime.tryParse(timeA.toString()) ?? DateTime(0);
            DateTime dtB = timeB is Timestamp ? timeB.toDate() : DateTime.tryParse(timeB.toString()) ?? DateTime(0);
            return dtB.compareTo(dtA);
          });

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            itemCount: sortedPosts.length,
            itemBuilder: (context, index) {
              return PostCard(
                post: sortedPosts[index],
                userLat: _currentPosition?.latitude,
                userLon: _currentPosition?.longitude,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/detail',
                  arguments: sortedPosts[index],
                ),
              );
            },
          );
        },
      ),
    );
  }
}