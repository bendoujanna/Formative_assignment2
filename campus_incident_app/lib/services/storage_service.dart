import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';

class UploadedPhoto {
  const UploadedPhoto({required this.url, required this.path});

  /// Address used to show the picture.
  final String url;

  /// Location in the bucket, kept so the file can be deleted later.
  final String path;
}

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<UploadedPhoto> uploadIncidentPhoto({
    required String uid,
    required XFile file,
  }) async {
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    final path =
        '${AppConstants.incidentPhotosFolder}/$uid/${DateTime.now().millisecondsSinceEpoch}.$extension';

    final ref = _storage.ref(path);
    await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();
    return UploadedPhoto(url: url, path: path);
  }

  Future<void> deletePhoto(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (_) {}
  }
}
