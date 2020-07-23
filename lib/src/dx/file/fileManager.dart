import 'dart:io';

import 'package:dio/dio.dart';

abstract class FileManager {
  List<int> read(File file);
  MultipartFile createMultipartFile(List<int> bytes, {String fileName});
  FormData createFormData(Map<String, dynamic> form);
}

class PubNubFileManager implements FileManager {
  PubNubFileManager();
  @override
  List<int> read(File file) {
    return file.readAsBytesSync();
  }

  @override
  MultipartFile createMultipartFile(List<int> bytes, {String fileName}) {
    return MultipartFile.fromBytes(bytes, filename: fileName);
  }

  @override
  FormData createFormData(Map<String, dynamic> form) {
    return FormData.fromMap(form);
  }
}
