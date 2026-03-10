import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import 'profile_photo_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  bool _isLoading = true;
  UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getProfile();

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _refreshProfile() async {
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Profil bulunamadı',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.22),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                  // Profile Photo
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        // Fotoğraf düzenleme ekranına git
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePhotoEditScreen(
                              profile: _profile!,
                            ),
                          ),
                        );
                        // Geri gelince profili yenile
                        _refreshProfile();
                      },
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipOval(
                              child: _buildProfilePhoto(),
                            ),
                            // Edit overlay
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                            color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: AppColors.primary.withValues(alpha: 0.9),
                ),
                onPressed: () {
                  // TODO: Edit profile details (bio, interests, etc.)
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: AppColors.primary.withValues(alpha: 0.9),
                ),
                onPressed: () {
                  // TODO: Settings
                },
              ),
            ],
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Age
                  Center(
                    child: Text(
                      '${_profile!.name}, ${_profile!.age}',
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Archetype Badge (Minds First - Sadece Arketip Gösterilir)
                  if (_profile!.archetype != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.psychology,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _profile!.archetype!,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Location
                  if (_profile!.locationText != null)
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _profile!.locationText!,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Bio
                  _buildSection(
                    title: 'Hakkımda',
                    child: Text(
                      _profile!.bio,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Interests
                  if (_profile!.interests.isNotEmpty)
                    _buildSection(
                      title: 'İlgi Alanları',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _profile!.interests.map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              interest,
                              style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Basic Info
                  _buildSection(
                    title: 'Temel Bilgiler',
                    child: Column(
                      children: [
                        _buildInfoRow(
                            Icons.school, 'Eğitim', _profile!.education),
                        if (_profile!.occupation != null)
                          _buildInfoRow(
                              Icons.work, 'Meslek', _profile!.occupation!),
                        _buildInfoRow(
                            Icons.favorite, 'Arıyor', _profile!.lookingFor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lifestyle (if filled)
                  if (_hasLifestyleInfo())
                    _buildSection(
                      title: 'Yaşam Tarzı',
                      child: Column(
                        children: [
                          if (_profile!.drinking != null)
                            _buildInfoRow(
                                Icons.local_bar, 'İçki', _profile!.drinking!),
                          if (_profile!.smoking != null)
                            _buildInfoRow(
                                Icons.smoke_free, 'Sigara', _profile!.smoking!),
                          if (_profile!.pets != null)
                            _buildInfoRow(
                                Icons.pets, 'Evcil Hayvan', _profile!.pets!),
                          if (_profile!.children != null)
                            _buildInfoRow(
                                Icons.child_care, 'Çocuk', _profile!.children!),
                          if (_profile!.religion != null)
                            _buildInfoRow(
                                Icons.church, 'Din', _profile!.religion!),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    // Fotoğraf varsa göster, yoksa placeholder
    if (_profile!.profilePhotoUrl != null && 
        _profile!.profilePhotoUrl!.isNotEmpty) {
      return Image.network(
        _profile!.profilePhotoUrl!,
        fit: BoxFit.cover,
        width: 150,
        height: 150,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading profile photo: $error');
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        },
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 150,
      height: 150,
      color: Colors.grey.shade900,
      child: Icon(
        Icons.person,
        size: 80,
        color: AppColors.primary,
      ),
    );
  }

  bool _hasLifestyleInfo() {
    return _profile!.drinking != null ||
        _profile!.smoking != null ||
        _profile!.pets != null ||
        _profile!.children != null ||
        _profile!.religion != null;
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
