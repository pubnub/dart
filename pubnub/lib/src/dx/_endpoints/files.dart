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
  final String fileId;
  final String fileName;

  final Uri uploadUri;
  final Map<String, String> formFields;

  GenerateFileUploadUrlResult._(
      this.fileId, this.fileName, this.uploadUri, this.formFields);

  factory GenerateFileUploadUrlResult.fromJson(dynamic object) =>
      GenerateFileUploadUrlResult._(
          object['data']['id'],
          object['data']['name'],
          Uri.parse(object['file_upload_request']['url']),
          (object['file_upload_request']['form_fields'] as List<dynamic>)
              .fold({}, (previousValue, element) {
            previousValue[element['key']] = element['value'];
            return previousValue;
          }));
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
  FileUploadResult._();

  factory FileUploadResult.fromJson(dynamic object) => FileUploadResult._();
}

class PublishFileMessageParams extends Parameters {
  String channel;
  String message;
  Keyset keyset;

  bool? storeMessage;
  int? ttl;
  String? meta;

  PublishFileMessageParams(this.keyset, this.channel, this.message,
      {this.storeMessage, this.meta, this.ttl});
  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'files',
      'publish-file',
      keyset.publishKey!,
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
      'uuid': keyset.uuid.value,
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
  final int? timetoken;

  bool? isError;
  String? description;
  FileInfo? fileInfo;

  PublishFileMessageResult({this.timetoken, this.description, this.isError});

  /// @nodoc
  factory PublishFileMessageResult.fromJson(dynamic object) {
    return PublishFileMessageResult(
        timetoken: int.parse(object[2]),
        description: object[1],
        isError: object[0] == 1 ? false : true);
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
  final dynamic fileContent;

  DownloadFileResult._(this.fileContent);

  /// @nodoc
  factory DownloadFileResult.fromJson(dynamic object,
      {CipherKey? cipherKey, Function? decryptFunction}) {
    if (cipherKey != null) {
      return DownloadFileResult._(
          decryptFunction!(cipherKey, object.byteList as List<int>));
    }
    return DownloadFileResult._(object.byteList);
  }
}

class ListFilesParams extends Parameters {
  Keyset keyset;
  String channel;

  int? limit;
  String? next;

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
  final List<FileDetail>? _filesDetail;
  final String? _next;
  final int? _count;

  /// List of file details.
  List<FileDetail>? get filesDetail => _filesDetail;

  /// Next page ID. Used for pagination.
  String? get next => _next;

  int? get count => _count;

  ListFilesResult._(this._filesDetail, this._count, this._next);

  /// @nodoc
  factory ListFilesResult.fromJson(dynamic object) => ListFilesResult._(
      (object['data'] as List).map((e) => FileDetail.fromJson(e)).toList(),
      object['count'] as int,
      object['next'] as String?);
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

  FileDetail._(this._name, this._id, this._size, this._created);

  factory FileDetail.fromJson(dynamic object) => FileDetail._(
      object['name'], object['id'], object['size'], object['created']);
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
