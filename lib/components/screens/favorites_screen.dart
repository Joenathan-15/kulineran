import 'package:flutter/material.dart';
import 'package:kulineran/components/widgets/loading_indicator.dart';
import 'package:kulineran/components/widgets/grid_post_card.dart';
import 'package:kulineran/components/widgets/kulineran_logo.dart';
import 'package:kulineran/services/auth_service.dart';
import 'package:kulineran/services/post_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _postService = PostService();
  final _authService = AuthService();
  
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final uid = _authService.currentUid;
    if (uid == null) return;
    try {
      final posts = await _postService.getFavorites(uid);
      if (mounted) {
        setState(() {
          _favorites = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUid;
    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Please login",
            style: TextStyle( fontSize: 14),
          ),
        ),
      );
    }

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // Page Title
              const Text(
                "My Favorites",
                style: TextStyle(
                  
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Grid list of favorite spots
              Expanded(
                child: _isLoading
                    ? const LoadingIndicator()
                    : _favorites.isEmpty
                        ? const Center(
                            child: Text(
                              "No favorites yet.",
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
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _favorites.length,
                            itemBuilder: (context, index) {
                              return GridPostCard(
                                post: _favorites[index],
                                onTap: () async {
                                  // Navigate to details and reload favorites on return in case they unfavorited it
                                  await Navigator.pushNamed(
                                    context,
                                    '/detail',
                                    arguments: _favorites[index],
                                  );
                                  setState(() => _isLoading = true);
                                  _loadFavorites();
                                },
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