/// Represents file information.
///
/// {@category Files}
class FileInfo {
  String id;
  String name;
  String? url;

  FileInfo(this.id, this.name, [this.url]);

  Map<String, String> toJson() {
    return {'id': id, 'name': name};
  }
}

/// Represents message with attached file.
///
/// {@category Files}
class FileMessage {
  FileInfo file;
  dynamic message;

  FileMessage(this.file, {this.message});

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'message': message, 'file': file.toJson()};
}
