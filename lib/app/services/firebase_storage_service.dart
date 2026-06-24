import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Pick an image from the gallery and upload it to Firebase Storage.
  /// Returns the download URL or null if cancelled/failed.
  Future<String?> pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image == null) return null;

    return uploadImage(File(image.path), image.name);
  }

  /// Upload a file to the 'products' folder in Firebase Storage.
  Future<String> uploadImage(File file, String fileName) async {
    final ref = _storage.ref().child('products/$fileName');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload multiple images and return their download URLs.
  Future<List<String>> pickAndUploadMultipleImages() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (images.isEmpty) return [];

    final urls = <String>[];
    for (final image in images) {
      final url = await uploadImage(File(image.path), image.name);
      urls.add(url);
    }
    return urls;
  }

  /// Delete an image from Firebase Storage by its URL.
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (_) {
      // Image may not exist — ignore
    }
  }
}
