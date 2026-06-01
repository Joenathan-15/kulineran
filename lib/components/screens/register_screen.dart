import 'package:flutter/material.dart';
import 'package:kulineran/components/widgets/kulineran_logo.dart';
import 'package:kulineran/components/widgets/custom_text_field.dart';
import 'package:kulineran/components/widgets/primary_button.dart';
import 'package:kulineran/components/widgets/secoundary_button.dart';
import 'package:kulineran/services/auth_service.dart';
import 'package:kulineran/services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _key = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isGithubLoading = false;

  void _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await AuthService().signInWithGoogle();
        // AuthGate will handle navigation on successful sign-in
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (!msg.contains('cancelled')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Google sign-in failed: $msg")),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _signInWithGitHub() async {
    setState(() => _isGithubLoading = true);
    try {
      await AuthService().signInWithGitHub();
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (!msg.contains('cancelled')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("GitHub sign-in failed: $msg")),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isGithubLoading = false);
    }
  }

  void _register() async {
    final authService = AuthService();
    final userService = UserService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_key.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await authService.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        final uid = authService.currentUid;
        if (uid != null) {
          await userService.createUser(uid, {
            'displayName': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phoneNumber': _phoneNumberController.text.trim(),
            'bio': '',
            'photoBase64': '',
            'darkMode': isDark,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration successful")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration failed: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Form(
            key: _key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // Title and Subtitle
                const Text(
                  "Create your account",
                  style: TextStyle(
                    
                    fontSize: 28,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your details to begin your Journey",
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Name Field
                CustomTextField(
                  label: "Nama",
                  hintText: "John Doe",
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter your name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email Field
                CustomTextField(
                  label: "Email",
                  hintText: "johnDoe@gmail.com",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter your email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone Number Field
                CustomTextField(
                  label: "Phone Number",
                  hintText: "0123456789123",
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter your phone number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password Field
                CustomTextField(
                  label: "Password",
                  hintText: "********",
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter your password";
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 30),
                
                // Actions
                Center(
                  child: Column(
                    children: [
                      _isLoading
                          ? const CircularProgressIndicator()
                          : PrimaryButton(
                              onPressed: _register,
                              text: "Create Account",
                            ),
                      
                      // Divider "or register with"
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.grey[800] : Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or register with',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                  
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.grey[800] : Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Social buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _isGoogleLoading
                                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                                : SecoundaryButton(
                                    text: "Google",
                                    onPressed: _signInWithGoogle,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isGithubLoading
                                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                                : SecoundaryButton(
                                    text: "Github",
                                    onPressed: _signInWithGitHub,
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
        ),
      ),
    );
  }
}
