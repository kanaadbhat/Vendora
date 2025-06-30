import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class PickAndUpload {
  final Dio _dio = Dio();

  Future<String?> pickAndUploadImage(BuildContext context) async {
    final source = await _determineImageSource(context);
    if (source == null) return null;
    debugPrint('[DEBUG PRINT] - Image source fetched: $source');
    final pickedFile = await _pickImage(source);
    if (pickedFile == null) return null;
    debugPrint('[DEBUG PRINT] - File picked: ${pickedFile.name}');
    final fileName = pickedFile.name;

    // Check if cached URL exists
    final cachedUrl = await _getCachedUrl(fileName);
    if (cachedUrl != null) return cachedUrl;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uploadedUrl = await _uploadToCloudinary(pickedFile);
      Navigator.pop(context); // Close loading dialog

      if (uploadedUrl != null) {
        await _cacheUrl(fileName, uploadedUrl);
      }
      debugPrint('[DEBUG PRINT] - Uploaded URL: $uploadedUrl');
      return uploadedUrl;
    } catch (e) {
      Navigator.pop(context); // Ensure dialog is closed on error
      debugPrint('[Cloudinary Upload Error] $e');
      return null;
    }
  }

  Future<ImageSource?> _determineImageSource(BuildContext context) async {
    if (kIsWeb) return ImageSource.gallery;

    return await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take a Photo"),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
    );
  }

  Future<XFile?> _pickImage(ImageSource source) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;

    if (file.bytes == null) return null;

    return XFile.fromData(
      file.bytes!,
      name: file.name,
      mimeType:
          file.extension != null ? 'image/${file.extension}' : 'image/jpeg',
    );
  }

  Future<String?> _uploadToCloudinary(XFile pickedFile) async {
    final cloudName, uploadPreset;
    if (kIsWeb && kReleaseMode) {
      cloudName = const String.fromEnvironment(
        'CLOUDINARY_CLOUD_NAME',
        defaultValue: '',
      );
      uploadPreset = const String.fromEnvironment(
        'CLOUDINARY_UPLOAD_PRESET',
        defaultValue: '',
      );
    } else {
      cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];
    }

    if (cloudName == null || uploadPreset == null) {
      debugPrint('[Cloudinary] Missing env vars');
      return null;
    }

    final url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";
    FormData formData;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      final u8bytes = Uint8List.fromList(bytes);

      // Get MIME type and split into type/subtype
      final mimeType = lookupMimeType(pickedFile.name) ?? 'image/jpeg';
      final parts = mimeType.split('/');
      final mainType = parts[0];
      final subType = parts.length > 1 ? parts[1] : 'jpeg';

      formData = FormData.fromMap({
        'upload_preset': uploadPreset,
        'file': MultipartFile.fromBytes(
          u8bytes,
          filename: pickedFile.name,
          contentType: MediaType(mainType, subType),
        ),
      });
    } else {
      formData = FormData.fromMap({
        'upload_preset': uploadPreset,
        'file': await MultipartFile.fromFile(
          pickedFile.path,
          filename: pickedFile.name,
        ),
      });
    }

    final response = await _dio.post(url, data: formData);

    if (response.statusCode == 200) {
      return response.data['secure_url'];
    } else {
      debugPrint('Upload failed: ${response.statusCode}');
      return null;
    }
  }

  Future<void> _cacheUrl(String fileName, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cloudinary_$fileName', url);
  }

  Future<String?> _getCachedUrl(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cloudinary_$fileName');
  }
}
