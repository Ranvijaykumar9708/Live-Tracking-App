import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/constants.dart';
import 'home_map_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authViewModel.signup(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      imagePath: _image?.path,
    );

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeMapScreen()),
        (Route<dynamic> route) => false,
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
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: AppStyles.glassBoxDecoration,
                child: Consumer<AuthProvider>(
                  builder: (context, authViewModel, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Create Account", style: AppStyles.heading1),
                        const SizedBox(height: 8),
                        const Text("Join us and start tracking", style: AppStyles.subtitle),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.2),
                              border: Border.all(color: AppColors.accentColor, width: 2),
                              image: _image != null
                                  ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _image == null
                                ? const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.accentColor)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Profile Picture", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        const SizedBox(height: 32),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: AppStyles.inputDecoration("Full Name", Icons.person_outline),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return "Name is required";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: AppStyles.inputDecoration("Email", Icons.email_outlined),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return "Email is required";
                                  if (!value.contains('@')) return "Enter a valid email";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: AppStyles.inputDecoration("Mobile Number", Icons.phone_outlined),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return "Mobile is required";
                                  if (value.length < 10) return "Enter a valid mobile number";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
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
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: AppStyles.inputDecoration("Confirm Password", Icons.lock_reset),
                                validator: (value) {
                                  if (value != _passwordController.text) return "Passwords do not match";
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
                            onPressed: authViewModel.isLoading ? null : _signup,
                            child: authViewModel.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("SIGN UP", style: AppStyles.buttonText),
                          ),
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
