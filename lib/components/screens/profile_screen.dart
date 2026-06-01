import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kulineran/components/widgets/kulineran_logo.dart';
import 'package:kulineran/components/widgets/custom_text_field.dart';
import 'package:kulineran/components/widgets/primary_button.dart';
import 'package:kulineran/services/auth_service.dart';
import 'package:kulineran/services/user_service.dart';
import 'package:kulineran/components/widgets/loading_indicator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = _authService.currentUid;
    if (uid != null) {
      final user = await _userService.getUser(uid);
      final email = _authService.currentEmail;
      if (mounted) {
        setState(() {
          _user = user;
          _nameController.text = user?['displayName'] ?? '';
          _bioController.text = user?['bio'] ?? '';
          _emailController.text = email ?? user?['email'] ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickProfilePhoto() async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 400,
      );

      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        final encoded = base64Encode(bytes);
        
        final uid = _authService.currentUid;
        if (uid != null) {
          await _userService.updateUser(uid, {'photoBase64': encoded});
          _loadUser();
        }
      }
    } catch (e) {
      debugPrint("Error picking profile photo: $e");
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _saveProfile() async {
    final uid = _authService.currentUid;
    if (uid != null) {
      setState(() => _isSaving = true);
      await _userService.updateUser(uid, {
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
      });
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated")),
        );
      }
    }
  }

  Future<void> _toggleThemeMode() async {
    final uid = _authService.currentUid;
    if (uid != null && _user != null) {
      final currentMode = _user!['darkMode'] ?? false;
      await _userService.setDarkMode(uid, !currentMode);
      _loadUser();
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingIndicator());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131313) : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.bookmark_border),
          tooltip: 'Favorites',
          onPressed: () => Navigator.pushNamed(context, '/favorites'),
        ),
        title: const KulineranLogo(fontSize: 20),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.mode_night_outlined),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: _toggleThemeMode,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              
              // Profile Photo Avatar
              GestureDetector(
                onTap: _pickProfilePhoto,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                  backgroundImage: _user?['photoBase64'] != null && _user!['photoBase64'].isNotEmpty
                      ? MemoryImage(base64Decode(_user!['photoBase64']))
                      : null,
                  child: _user?['photoBase64'] == null || _user!['photoBase64'].isEmpty
                      ? Icon(
                          Icons.person, 
                          size: 70, 
                          color: isDark ? Colors.white54 : Colors.black45,
                        )
                      : null,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Change Photo Pill Button
              SizedBox(
                height: 38,
                child: TextButton(
                  onPressed: _pickProfilePhoto,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7260),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text(
                    "Change Photo",
                    style: TextStyle(
                      color: Colors.black,
                      
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Name Input
              CustomTextField(
                label: "Nama",
                hintText: "Anastasia Kirana",
                controller: _nameController,
              ),
              
              const SizedBox(height: 20),
              
              // Bio Input
              CustomTextField(
                label: "Bio",
                hintText: "Total Foodies and likes to explore...",
                controller: _bioController,
                maxLines: 3,
              ),
              
              const SizedBox(height: 20),
              
              // Email Input (Read-only)
              CustomTextField(
                label: "Email",
                hintText: "johnDoe@gmail.com",
                controller: _emailController,
                readOnly: true,
              ),
              
              const SizedBox(height: 40),
              
              // Save Changes Pill Button
              _isSaving
                  ? const CircularProgressIndicator()
                  : PrimaryButton(
                      text: "Save Changes",
                      onPressed: _saveProfile,
                    ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}