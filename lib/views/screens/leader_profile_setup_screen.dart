import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../widgets/leader_main_navigation.dart';

class LeaderProfileSetupScreen extends StatefulWidget {
  const LeaderProfileSetupScreen({super.key});

  @override
  State<LeaderProfileSetupScreen> createState() =>
      _LeaderProfileSetupScreenState();
}

class _LeaderProfileSetupScreenState extends State<LeaderProfileSetupScreen> {
  final _bioController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  File? _profileImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  /* ---------------- IMAGE PICK ---------------- */

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _profileImage = File(image.path);
    });
  }

  /* ---------------- CONTINUE ---------------- */

  Future<void> _onContinue() async {
    final appState = context.read<AppStateProvider>();
    final userId = appState.userId;

    if (userId == null) return;

    final bio = _bioController.text.trim();

    setState(() => _isSaving = true);

    try {
      String? profileImageUrl;

      /// Upload profile image (if selected)
      if (_profileImage != null) {
        profileImageUrl = await _storageService.uploadProfileImage(
          userId: userId,
          imageFile: _profileImage!,
        );
      }

      /// Update leader profile (MATCHES YOUR SERVICE)
      await _firestoreService.updateLeaderProfile(
        uid: userId,
        bio: bio.isNotEmpty ? bio : null,
        profileImageUrl: profileImageUrl,
        isProfileComplete: true,
      );

      /// Update local app state
      appState.completeLeaderProfile();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LeaderMainNavigation()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile Setup'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell worshipers about yourself',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              /// PROFILE IMAGE
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Add profile photo',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 24),

              /// BIO
              TextField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Short bio',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 28),

              /// CONTINUE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
