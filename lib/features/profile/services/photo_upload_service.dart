import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/auth_service.dart';

class PhotoUploadService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  final _authService = AuthService();

  Future<List<String>> pickMultipleImages({int maxImages = 9}) async {
    final List<XFile> images = await _picker.pickMultipleMedia(
      imageQuality: 80,
    );

    if (images.isEmpty) {
      return [];
    }

    if (images.length > maxImages) {
      throw 'En fazla $maxImages fotoğraf seçebilirsiniz';
    }

    return await _uploadImages(images);
  }

  Future<String?> pickSingleImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return null;

    final urls = await _uploadImages([image]);
    return urls.isNotEmpty ? urls.first : null;
  }

  Future<List<String>> _uploadImages(List<XFile> images) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) throw 'Kullanıcı oturumu bulunamadı';

    List<String> uploadedUrls = [];

    for (int i = 0; i < images.length; i++) {
      try {
        final file = File(images[i].path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'profile_${userId}_${timestamp}_$i.jpg';
        final ref = _storage.ref().child('profile_photos/$userId/$fileName');

        // Upload
        await ref.putFile(file);

        // Get download URL
        final downloadUrl = await ref.getDownloadURL();

        debugPrint('✅ Photo uploaded: $downloadUrl');
        uploadedUrls.add(downloadUrl);
      } catch (e) {
        debugPrint('❌ Error uploading photo $i: $e');
        // Continue with other photos
      }
    }

    return uploadedUrls;
  }

  Future<void> deletePhoto(String photoUrl) async {
    try {
      // Check if URL is valid Firebase Storage URL
      if (!photoUrl.contains('firebasestorage.googleapis.com')) {
        debugPrint('⚠️ Invalid photo URL, skipping delete: $photoUrl');
        return;
      }

      final ref = _storage.refFromURL(photoUrl);

      // Try to get metadata first to check if file exists
      try {
        await ref.getMetadata();
        // File exists, safe to delete
        await ref.delete();
        debugPrint('✅ Photo deleted: $photoUrl');
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          // File doesn't exist, but that's okay
          debugPrint('⚠️ Photo already deleted or doesn\'t exist: $photoUrl');
        } else {
          // Other Firebase error
          throw 'Firebase error: ${e.message}';
        }
      }
    } catch (e) {
      debugPrint('❌ Error deleting photo: $e');
      // Don't throw - just log it
      // This allows Firestore cleanup to continue
    }
  }
}
