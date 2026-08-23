import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ChatImageUpload {
  const ChatImageUpload({
    required this.downloadUrl,
    required this.storagePath,
  });

  final String downloadUrl;
  final String storagePath;
}

class ChatMediaService {
  ChatMediaService({
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  Future<ChatImageUpload?> pickAndUploadImage({
    required String threadId,
  }) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 2048,
      maxHeight: 2048,
    );

    if (picked == null) return null;

    final file = File(picked.path);
    final fileSize = await file.length();

    if (fileSize <= 0 || fileSize >= 8 * 1024 * 1024) {
      throw StateError('Selected image is too large.');
    }

    final extension = _safeExtension(picked.path);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final fileName = 'chat_${me.uid}_$timestamp.$extension';
    final storagePath = 'chat_media/$threadId/${me.uid}/$fileName';

    final ref = _storage.ref().child(storagePath);

    await ref.putFile(
      file,
      SettableMetadata(
        contentType: _contentTypeForExtension(extension),
        cacheControl: 'public,max-age=86400',
      ),
    );

    final downloadUrl = await ref.getDownloadURL();

    return ChatImageUpload(
      downloadUrl: downloadUrl,
      storagePath: storagePath,
    );
  }

  String _safeExtension(String path) {
    final name = path.toLowerCase();

    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    if (name.endsWith('.heic')) return 'heic';
    if (name.endsWith('.heif')) return 'heif';

    return 'jpg';
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }
}
