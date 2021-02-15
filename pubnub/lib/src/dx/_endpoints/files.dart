import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';

typedef decryptFunction = List<int> Function(CipherKey key, List<int> data);

class GenerateFileUploadUrlParams extends Parameters {
  Keyset keyset;
  String channel;
  String payload;

  GenerateFileUploadUrlParams(this.keyset, this.channel, this.payload);

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
    return Request.post(uri: Uri(pathSegments: pathSegments), body: payload);
  }
}

class GenerateFileUploadUrlResult extends Result {
  String fileId;
  String fileName;

  Uri uploadUri;
  Map<String, String> formFields;

  GenerateFileUploadUrlResult._();

  factory GenerateFileUploadUrlResult.fromJson(dynamic object) =>
      GenerateFileUploadUrlResult._()
        ..fileId = object['data']['id']
        ..fileName = object['data']['name']
        ..uploadUri = Uri.parse(object['file_upload_request']['url'])
        ..formFields =
            (object['file_upload_request']['form_fields'] as List<dynamic>)
                .fold({}, (previousValue, element) {
          previousValue[element['key']] = element['value'];
          return previousValue;
        });
}

class FileUploadParams extends Parameters {
  Uri requestUrl;

  Map<String, dynamic> formData;

  FileUploadParams(this.requestUrl, this.formData);

  @override
  Request toRequest() {
    return Request.file(uri: requestUrl, body: formData);
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
    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of publish file message endpoint call.
///
/// {@category Results}
/// {@category Files}
class PublishFileMessageResult extends Result {
  bool isError;
  String description;
  int timetoken;
  FileInfo fileInfo;

  PublishFileMessageResult();

  /// @nodoc
  factory PublishFileMessageResult.fromJson(dynamic object) {
    return PublishFileMessageResult()
      ..timetoken = int.tryParse(object[2])
      ..description = object[1]
      ..isError = object[0] == 1 ? false : true;
  }
}

class DownloadFileParams extends Parameters {
  Uri uri;

  DownloadFileParams(this.uri);

  @override
  Request toRequest() {
    return Request.get(uri: uri);
  }
}

/// Result of download file endpoint call.
///
/// {@category Results}
/// {@category Files}
class DownloadFileResult extends Result {
  /// Content of the file.
  dynamic fileContent;

  DownloadFileResult._();

  /// @nodoc
  factory DownloadFileResult.fromJson(dynamic object,
      {CipherKey cipherKey, Function decryptFunction}) {
    if (cipherKey != null) {
      return DownloadFileResult._()
        ..fileContent =
            decryptFunction(cipherKey, object.byteList as List<int>);
    }
    return DownloadFileResult._()..fileContent = object.byteList;
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

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of list files endpoint call.
///
/// {@category Results}
/// {@category Files}
class ListFilesResult extends Result {
  List<FileDetail> _filesDetail;
  String _next;
  int _count;

  /// List of file details.
  List<FileDetail> get filesDetail => _filesDetail;

  /// Next page ID. Used for pagination.
  String get next => _next;

  int get count => _count;

  ListFilesResult._();

  /// @nodoc
  factory ListFilesResult.fromJson(dynamic object) => ListFilesResult._()
    .._filesDetail = (object['data'] as List)
        ?.map((e) => e == null ? null : FileDetail.fromJson(e))
        ?.toList()
    .._next = object['next'] as String
    .._count = object['count'] as int;
}

/// Represents a file uploaded to PubNub.
///
/// {@category Results}
/// {@category Files}
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
    return Request.delete(uri: Uri(pathSegments: pathSegments));
  }
}

/// Result of delete file endpoint call.
///
/// {@category Results}
/// {@category Files}
class DeleteFileResult extends Result {
  DeleteFileResult._();

  /// @nodoc
  factory DeleteFileResult.fromJson(dynamic object) => DeleteFileResult._();
}
