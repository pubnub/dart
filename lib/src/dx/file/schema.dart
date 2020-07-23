class FileMessage {
  Map<String, String> file;
  dynamic message;

  FileMessage(this.file, {this.message});

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'message': message, 'file': file};
}
