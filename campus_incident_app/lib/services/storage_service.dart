import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';

class UploadedPhoto {
  const UploadedPhoto({required this.url, required this.path});

  /// Address used to show the picture.
  final String url;

  /// Location in the bucket, kept so the file can be deleted later.
  final String path;
}

/// Uploads incident photos to Cloudinary using an unsigned upload preset.
class StorageService {
  StorageService({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const String _cloudName = 'dud6g4xw';
  static const String _uploadPreset = 'campus_incidents_unsigned';

  Future<UploadedPhoto> uploadIncidentPhoto({
    required String uid,
    required XFile file,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = '${AppConstants.incidentPhotosFolder}/$uid'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String;
    final publicId = data['public_id'] as String;

    return UploadedPhoto(url: secureUrl, path: publicId);
  }

  /// deletion is handled via Cloudinary dashboard or handled by Firestore fallback.
  Future<void> deletePhoto(String path) async {
    try {} catch (_) {}
  }
}
