import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kulineran/components/widgets/loading_indicator.dart';
import 'package:kulineran/components/widgets/grid_post_card.dart';
import 'package:kulineran/components/widgets/kulineran_logo.dart';
import 'package:kulineran/services/location_service.dart';
import 'package:kulineran/services/post_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _postService = PostService();
  final _locationService = LocationService();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allPosts = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  Position? _currentPosition;
  StreamSubscription? _feedSub;

  @override
  void initState() {
    super.initState();
    _loadAllPosts();
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPosts() async {
    _currentPosition = await _locationService.getCurrentPosition();
    
    // Listen to feed stream to populate all posts
    _feedSub = _postService.getFeed().listen((posts) {
      if (mounted) {
        setState(() {
          _allPosts = posts;
          _sortPostsByDistance(_allPosts);
          _results = _allPosts;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _sortPostsByDistance(List<Map<String, dynamic>> postsList) {
    if (_currentPosition == null) return;
    postsList.sort((a, b) {
      if (a['latitude'] == null || b['latitude'] == null) return 0;
      double distA = _locationService.distanceBetween(
        _currentPosition!.latitude, _currentPosition!.longitude, a['latitude'], a['longitude']);
      double distB = _locationService.distanceBetween(
        _currentPosition!.latitude, _currentPosition!.longitude, b['latitude'], b['longitude']);
      return distA.compareTo(distB);
    });
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = _allPosts;
      });
      return;
    }

    final filtered = _allPosts.where((post) {
      final name = (post['foodSpotName'] ?? '').toLowerCase();
      final desc = (post['description'] ?? '').toLowerCase();
      final searchVal = query.toLowerCase();
      return name.contains(searchVal) || desc.contains(searchVal);
    }).toList();

    setState(() {
      _results = filtered;
    });
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // Custom Search Input Box
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search...",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Section Title "Near me"
              const Text(
                "Near me",
                style: TextStyle(
                  
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Grid list of spots
              Expanded(
                child: _isLoading
                    ? const LoadingIndicator()
                    : _results.isEmpty
                        ? const Center(
                            child: Text(
                              "No spots found.",
                              style: TextStyle(
                                
                                fontSize: 13,
                              ),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.72, // taller card layout
                            ),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              return GridPostCard(
                                post: _results[index],
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/detail',
                                  arguments: _results[index],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}