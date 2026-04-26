import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/elegant_warning.dart';
import '../models/user_profile_model.dart';
import '../services/photo_upload_service.dart';
import '../services/profile_service.dart';

class ProfilePhotoEditScreen extends StatefulWidget {
  final UserProfileModel profile;
  
  const ProfilePhotoEditScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ProfilePhotoEditScreen> createState() => _ProfilePhotoEditScreenState();
}

class _ProfilePhotoEditScreenState extends State<ProfilePhotoEditScreen> {
  final _photoService = PhotoUploadService();
  final _profileService = ProfileService();
  List<String> _photos = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.profile.photos);
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= 9) {
      showElegantWarning(context, 'En fazla 9 fotoğraf ekleyebilirsiniz');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final remainingSlots = 9 - _photos.length;
      final newPhotos = await _photoService.pickMultipleImages(
        maxImages: remainingSlots,
      );
      
      if (newPhotos.isNotEmpty) {
        setState(() {
          _photos.addAll(newPhotos);
        });

        await _savePhotos();
        
        if (mounted) {
          showElegantWarning(context, '✅ ${newPhotos.length} fotoğraf yüklendi');
        }
      }
    } catch (e) {
      debugPrint('Error picking photos: $e');
      if (mounted) {
        showElegantWarning(context, 'Hata: $e');
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _setAsMainPhoto(int index) async {
    if (index == 0) return; // Zaten ana fotoğraf
    
    setState(() {
      final photo = _photos.removeAt(index);
      _photos.insert(0, photo);
    });
    
    await _savePhotos();
    
    if (mounted) {
      showElegantWarning(context, '⭐ Ana fotoğraf güncellendi');
    }
  }

  Future<void> _deletePhoto(int index) async {
    try {
      final photoUrl = _photos[index];
      await _photoService.deletePhoto(photoUrl);
      
      setState(() {
        _photos.removeAt(index);
      });

      await _savePhotos();
      
      if (mounted) {
        showElegantWarning(context, 'Fotoğraf silindi');
      }
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      if (mounted) {
        showElegantWarning(context, 'Hata: $e');
      }
    }
  }

  Future<void> _savePhotos() async {
    final updatedProfile = widget.profile.copyWith(
      photos: _photos,
      profilePhotoUrl: _photos.isNotEmpty ? _photos.first : null,
    );
    
    await _profileService.saveProfile(updatedProfile);
  }

  void _showPhotoOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index != 0)
              ListTile(
                leading: Icon(Icons.star, color: AppColors.primary),
                title: Text(
                  'Ana Fotoğraf Yap',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _setAsMainPhoto(index);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                'Sil',
                style: GoogleFonts.inter(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deletePhoto(index);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Fotoğraflarım',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_photos.length}/9 fotoğraf',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fotoğrafa uzun basarak seçenekleri görebilirsiniz',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  if (index < _photos.length) {
                    return _buildPhotoTile(_photos[index], index);
                  } else {
                    return _buildEmptyTile();
                  }
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _pickPhotos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      )
                    : Text(
                        'FOTOĞRAF EKLE',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile(String photoUrl, int index) {
    return GestureDetector(
      onLongPress: () => _showPhotoOptions(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading photo at index $index: $error');
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.red.withValues(alpha: 0.5),
                    size: 32,
                  ),
                );
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
            ),
          ),
          
          // Altın Yıldız - Sadece ilk fotoğrafta
          if (index == 0)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.black,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.add_photo_alternate,
        color: AppColors.primary.withValues(alpha: 0.5),
        size: 32,
      ),
    );
  }
}
