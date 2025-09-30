import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ImageUploadService {
  final String? _cloudName;
  final String? _uploadPreset;

  ImageUploadService() 
      : _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'],
        _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

  Future<String> uploadImage(Uint8List fileBytes, String fileName) async {
    if (_cloudName == null || _uploadPreset == null) {
      throw Exception('Cloudinary cloud name or upload preset is not set in .env file');
    }

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = _uploadPreset!;
    final multipartFile = http.MultipartFile.fromBytes('file', fileBytes, filename: fileName);
    request.files.add(multipartFile);

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = json.decode(responseData);
        return decodedData['secure_url'];
      } else {
        final errorData = await response.stream.bytesToString();
        throw Exception('Cloudinary upload failed: ${response.statusCode}, $errorData');
      }
    } catch (e) {
      throw Exception('Error uploading to Cloudinary: $e');
    }
  }
}
