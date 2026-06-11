import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/constants.dart';
import 'home_map_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authViewModel = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authViewModel.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeMapScreen()),
      );
    } else if (authViewModel.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage!),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: AppStyles.glassBoxDecoration,
                child: Consumer<AuthProvider>(
                  builder: (context, authViewModel, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/logo.png',
                            width: 80,
                            height: 80,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text("Welcome Back", style: AppStyles.heading1),
                        const SizedBox(height: 8),
                        const Text("Sign in to continue your journey", style: AppStyles.subtitle, textAlign: TextAlign.center),
                        const SizedBox(height: 48),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: AppStyles.inputDecoration("Email", Icons.email_outlined),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return "Email is required";
                                  if (!value.contains('@')) return "Enter a valid email address";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: AppStyles.inputDecoration("Password", Icons.lock_outline),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return "Password is required";
                                  if (value.length < 6) return "Password must be at least 6 characters";
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: authViewModel.isLoading ? null : _login,
                            child: authViewModel.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("LOGIN", style: AppStyles.buttonText),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?", style: TextStyle(color: AppColors.textSecondary)),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                                );
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
