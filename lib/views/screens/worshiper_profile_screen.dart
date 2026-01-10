import 'dart:io';

import 'package:faith_connect/views/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import 'sign_in_screen.dart';

class WorshiperProfileScreen extends StatefulWidget {
  const WorshiperProfileScreen({super.key});

  @override
  State<WorshiperProfileScreen> createState() => _WorshiperProfileScreenState();
}

class _WorshiperProfileScreenState extends State<WorshiperProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _name;
  String? _email;
  String? _profileImageUrl;
  File? _profileImage;
  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final appState = context.read<AppStateProvider>();
    if (appState.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userData = await _firestoreService.getWorshiperData(
        appState.userId!,
      );

      if (!mounted) return;

      setState(() {
        _name = userData?['name'];
        _email = userData?['email'];
        _profileImageUrl = userData?['profileImageUrl'];
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null || !mounted) return;

    final userId = context.read<AppStateProvider>().userId;
    if (userId == null) return;

    setState(() {
      _profileImage = File(image.path);
      _isUploadingImage = true;
    });

    try {
      // Upload to Firebase Storage
      final imageUrl = await _storageService.uploadProfileImage(
        userId: userId,
        imageFile: _profileImage!,
      );

      // Save image URL to Firestore
      await _firestoreService.updateWorshiperData(
        uid: userId,
        profileImageUrl: imageUrl,
      );

      if (!mounted) return;

      setState(() {
        _profileImageUrl = imageUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profileImage = null;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final appState = context.read<AppStateProvider>();

    await appState.signOut();
    if (!mounted) return;

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final community = appState.community ?? 'Not set';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // off-white
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
              child: const Icon(Icons.settings, color: Colors.black),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              /// PROFILE HEADER
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                    child: _profileImage == null && 
                           (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 64,
                            color: Colors.black54,
                          )
                        : _isUploadingImage
                            ? const CircularProgressIndicator()
                            : null,
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                _name ?? 'Loading...',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 6),

              Text(_email ?? '', style: const TextStyle(color: Colors.black54)),

              const SizedBox(height: 12),

              /// ROLE TAG
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'WORSHIPER',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              /// STATS
              Row(
                children: [
                  _buildStatCard('124', 'Prayers Joined'),
                  const SizedBox(width: 16),
                  _buildStatCard('12', 'Communities'),
                ],
              ),

              const SizedBox(height: 32),

              /// ACCOUNT DETAILS
              _buildSectionTitle('Account Details'),

              _buildListTile(
                icon: Icons.calendar_today,
                title: 'Member since',
                value: 'January 2023',
              ),
              _buildListTile(
                icon: Icons.groups,
                title: 'Community',
                value: community,
              ),
              _buildListTile(
                icon: Icons.language,
                title: 'Language',
                value: 'English',
              ),

              const SizedBox(height: 40),

              /// LOGOUT
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
