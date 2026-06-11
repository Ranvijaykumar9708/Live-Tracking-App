import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _homeController = TextEditingController();
  final _workController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthProvider>(context, listen: false);
    final user = authViewModel.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _mobileController.text = user.mobile;
      _homeController.text = user.homeAddress ?? '';
      _workController.text = user.workAddress ?? '';
      if (user.imagePath != null) {
        _image = File(user.imagePath!);
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final authViewModel = Provider.of<AuthProvider>(context, listen: false);
    
    bool success = await authViewModel.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      imagePath: _image?.path,
      homeAddress: _homeController.text.trim().isEmpty ? null : _homeController.text.trim(),
      workAddress: _workController.text.trim().isEmpty ? null : _workController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else if (authViewModel.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authViewModel.errorMessage!), backgroundColor: AppColors.errorColor),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _homeController.dispose();
    _workController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthProvider>(
            builder: (context, authViewModel, child) {
              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _image != null ? FileImage(_image!) : null,
                            child: _image == null
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.black),
                      decoration: AppStyles.inputDecoration("Full Name", Icons.person_outline),
                      validator: (value) => (value == null || value.isEmpty) ? "Name is required" : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black),
                      decoration: AppStyles.inputDecoration("Email", Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Email is required";
                        if (!value.contains('@')) return "Enter a valid email address";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.black),
                      decoration: AppStyles.inputDecoration("Mobile Number", Icons.phone_outlined),
                      validator: (value) => (value == null || value.isEmpty) ? "Mobile is required" : null,
                    ),
                    const SizedBox(height: 40),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Saved Places", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _homeController,
                      style: const TextStyle(color: Colors.black),
                      decoration: AppStyles.inputDecoration("Home Address", Icons.home_outlined),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _workController,
                      style: const TextStyle(color: Colors.black),
                      decoration: AppStyles.inputDecoration("Work Address", Icons.work_outline),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: authViewModel.isLoading ? null : _saveProfile,
                        child: authViewModel.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("SAVE CHANGES", style: AppStyles.buttonText),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
