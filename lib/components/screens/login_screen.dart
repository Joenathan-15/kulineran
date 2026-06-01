import 'package:flutter/material.dart';
import 'package:kulineran/components/widgets/kulineran_logo.dart';
import 'package:kulineran/components/widgets/custom_text_field.dart';
import 'package:kulineran/components/widgets/primary_button.dart';
import 'package:kulineran/components/widgets/secoundary_button.dart';
import 'package:kulineran/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isGoogleLoading = false;
  bool _isGithubLoading = false;

  void _login() async {
    final authService = AuthService();
    if (_formKey.currentState!.validate()) {
      try {
        await authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login successful")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login failed: ${e.toString()}")),
          );
        }
      }
    }
  }

  void _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await AuthService().signInWithGoogle();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Centered Brand Logo
                const Center(
                  child: KulineranLogo(fontSize: 24),
                ),
                
                const SizedBox(height: 50),
                
                // Title and Subtitle
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    
                    fontSize: 28,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter Your Credentials to continue your Journey",
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 40),
                
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
                
                const SizedBox(height: 20),
                
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
                
                const SizedBox(height: 40),
                
                // Actions
                Center(
                  child: Column(
                    children: [
                      PrimaryButton(
                        onPressed: _login,
                        text: "Login",
                      ),
                      const SizedBox(height: 16),
                      SecoundaryButton(
                        onPressed: () {
                          Navigator.pushNamed(context, "/register");
                        },
                        text: "Register",
                      ),
                      
                      // Divider "or login with"
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
                                'or login with',
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
                      
                      // Social login buttons
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
