import 'package:pubnub/src/core/core.dart';

typedef decryptFunction = List<int> Function(CipherKey key, List<int> data);

class GenerateFileUploadUrlParams extends Parameters {
  Keyset keyset;
  String channel;
  String fileName;

  GenerateFileUploadUrlParams(this.keyset, this.channel, this.fileName);

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'files',
      keyset.subscribeKey,
      'channels',
      channel,
      'generate-upload-url'
    ];
    return Request(RequestType.post, pathSegments, body: fileName);
  }
}

class GenerateFileUploadUrlBody {
  String fileName;

  GenerateFileUploadUrlBody(this.fileName);

  Map<String, dynamic> toJson() => <String, dynamic>{'name': fileName};
}

class GenerateFileUploadUrlResult extends Result {
  Map<String, dynamic> data;

  Map<String, dynamic> fileUploadRequest;

  GenerateFileUploadUrlResult._();

  factory GenerateFileUploadUrlResult.fromJson(dynamic object) =>
      GenerateFileUploadUrlResult._()
        ..data = object['data']
        ..fileUploadRequest = object['file_upload_request'];
}

class FileUploadParams extends Parameters {
  Uri requestUrl;
  dynamic formData;

  FileUploadParams(this.requestUrl, this.formData);

  @override
  Request toRequest() {
    return Request(RequestType.post, [], body: formData, url: requestUrl);
  }
}

class FileUploadResult extends Result {
  int statusCode;
  FileUploadResult._();

  factory FileUploadResult.fromJson(dynamic object) =>
      FileUploadResult._()..statusCode = object.statusCode;
}

class PublishFileMessageParams extends Parameters {
  String channel;
  String message;

  bool storeMessage;
  Keyset keyset;
  int ttl;
  String meta;

  PublishFileMessageParams(this.keyset, this.channel, this.message,
      {this.storeMessage, this.meta, this.ttl});
  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'files',
      'publish-file',
      keyset.publishKey,
      keyset.subscribeKey,
      '0',
      channel,
      '0',
      message
    ];

    var queryParameters = {
      if (storeMessage == true)
        'store': '1'
      else if (storeMessage == false)
        'store': '0',
      if (keyset.uuid != null) 'uuid': keyset.uuid.value,
      if (ttl != null) 'ttl': ttl.toString(),
      if (meta != null) 'meta': meta
    };
    return Request(RequestType.get, pathSegments,
        queryParameters: queryParameters);
  }
}

class PublishFileMessageResult extends Result {
  bool isError;
  String description;
  int timetoken;
  dynamic fileInfo;

  PublishFileMessageResult();

  factory PublishFileMessageResult.fromJson(dynamic object) {
    return PublishFileMessageResult()
      ..timetoken = int.tryParse(object[2])
      ..description = object[1]
      ..isError = object[0] == 1 ? false : true;
  }
}

class DownloadFileParams extends Parameters {
  Uri url;

  DownloadFileParams(this.url);

  @override
  Request toRequest() {
    return Request(RequestType.get, [], url: url);
  }
}

class DownloadFileResult extends Result {
  dynamic fileContent;

  DownloadFileResult._();

  factory DownloadFileResult.fromJson(dynamic object,
      {CipherKey cipherKey, Function decryptFunction}) {
    if (cipherKey != null) {
      return DownloadFileResult._()
        ..fileContent = decryptFunction(cipherKey, object.data as List<int>);
    }
    return DownloadFileResult._()..fileContent = object.data;
  }
}

class ListFilesParams extends Parameters {
  Keyset keyset;
  String channel;

  int limit;
  String next;

  ListFilesParams(this.keyset, this.channel, {this.limit, this.next});

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'files',
      keyset.subscribeKey,
      'channels',
      channel,
      'files'
    ];

    var queryParameters = {
      if (limit != null) 'limit': '$limit',
      if (next != null) 'next': next
    };

    return Request(RequestType.get, pathSegments,
        queryParameters: queryParameters);
  }
}

class ListFilesResult extends Result {
  List<FileDetail> _filesDetail;
  String _next;
  int _count;

  List<FileDetail> get filesDetail => _filesDetail;
  String get next => _next;
  int get count => _count;

  ListFilesResult._();

  factory ListFilesResult.fromJson(dynamic object) => ListFilesResult._()
    .._filesDetail = (object['data'] as List)
        ?.map((e) => e == null ? null : FileDetail.fromJson(e))
        ?.toList()
    .._next = object['next'] as String
    .._count = object['count'] as int;
}

class FileDetail {
  String _name;
  String _id;
  int _size;
  String _created;

  String get name => _name;
  int get size => _size;
  String get id => _id;
  String get created => _created;

  FileDetail._();

  factory FileDetail.fromJson(dynamic object) => FileDetail._()
    .._name = object['name']
    .._id = object['id']
    .._size = object['size']
    .._created = object['created'];
}

class DeleteFileParams extends Parameters {
  Keyset keyset;
  String channel;
  String fileId;
  String fileName;

  DeleteFileParams(this.keyset, this.channel, this.fileId, this.fileName);

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'files',
      keyset.subscribeKey,
      'channels',
      channel,
      'files',
      fileId,
      fileName
    ];
    return Request(RequestType.delete, pathSegments);
  }
}

class DeleteFileResult extends Result {
  DeleteFileResult._();

  factory DeleteFileResult.fromJson(dynamic object) => DeleteFileResult._();
}
