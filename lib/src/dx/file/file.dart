import 'dart:io';
import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/file.dart';
import 'package:pubnub/src/dx/file/fileManager.dart';
import 'schema.dart';
import 'extensions/keyset.dart';
export 'extensions/keyset.dart';
export 'schema.dart';

final _logger = injectLogger('dx.file');

class FileDx {
  final Core _core;
  final FileManager _fileManager;
  FileDx(this._core, this._fileManager);

  /// This method allows to send [file] to [channel]
  /// If file upload operation , It also publish [fileMessage] along with file data `fileId` and `fileName`
  ///
  /// Provide [cipherKey] to encrypt file content & fileEvent message if you want to override default `cipherKey` of `Keyset`
  /// * It gives priority of [cipherKey] provided in method argument over `keyset`'s `cipherKey`
  ///
  /// It retries for publishing [fileMessage] till default value of PubNub configuration value
  /// [fileMessagePublishRetryLimit] which is configurable
  ///
  /// * If all retry exhaused for publish file Message then response's `fileInfo`
  /// field will give file's id and name
  ///
  /// If [fileMessage] is null then only file information (fileId, fileName) will be published to [channel]
  /// * Additional Publish File Message options
  /// You can set a per-message time to live in storage using [fileMessageTtl] option.
  /// If set to `0`, message won't expire.
  /// If unset, expiration will fall back to default.
  /// You can override the default account configuration on message
  /// saving using [storeFileMessage] flag - `true` to save and `false` to discard.
  /// Leave this option unset if you want to use the default.
  /// Provide [fileMessageMeta] for additional information
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  /// Ensure that you provide [publishKey] as it is required for publishing message
  Future<PublishFileMessageResult> sendFile(
      String channel, File file, String fileName,
      {CipherKey cipherKey,
      dynamic fileMessage,
      bool storeFileMessage,
      int fileMessageTtl,
      dynamic fileMessageMeta,
      Keyset keyset,
      String using}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);

    Ensure(keyset.publishKey).isNotNull('publish key for file upload message');
    var requestPayload =
        await _core.parser.encode(GenerateFileUploadUrlBody(fileName));
    var fileUploadDetails = await defaultFlow<GenerateFileUploadUrlParams,
            GenerateFileUploadUrlResult>(
        logger: _logger,
        core: _core,
        params: GenerateFileUploadUrlParams(keyset, channel, requestPayload),
        serialize: (object, [_]) =>
            GenerateFileUploadUrlResult.fromJson(object));
    var uri = Uri.parse(fileUploadDetails.fileUploadRequest['url']);
    var form_fields = fileUploadDetails.fileUploadRequest['form_fields'];
    var form = <String, dynamic>{};
    form_fields.forEach((m) => form[m['key']] = m['value']);
    if (keyset.cipherKey != null || cipherKey != null) {
      form['file'] = _fileManager.createMultipartFile(_core.crypto
          .encryptFileData(
              cipherKey ?? keyset.cipherKey, _fileManager.read(file)));
    } else {
      form['file'] = _fileManager.createMultipartFile(_fileManager.read(file),
          fileName: fileName);
    }
    var fileInfo = fileUploadDetails.data.map((k, v) => MapEntry('$k', '$v'));
    fileInfo['url'] = getFileUrl(channel, '${fileUploadDetails.data['id']}',
            '${fileUploadDetails.data['name']}')
        .toString();
    var publishMessage = FileMessage(fileInfo, message: fileMessage);
    var publishFileResult = PublishFileMessageResult();
    var retryCount = keyset.fileMessagePublishRetryLimit;
    var s3Response = await customFlow<FileUploadParams, FileUploadResult>(
        logger: _logger,
        core: _core,
        params: FileUploadParams(uri, _fileManager.createFormData(form)),
        serialize: (object, [_]) => FileUploadResult.fromJson(object));
    if (s3Response.statusCode == 204) {
      do {
        try {
          publishFileResult = await publishFileMessage(channel, publishMessage,
              ttl: fileMessageTtl,
              storeMessage: storeFileMessage,
              meta: fileMessageMeta,
              cipherKey: cipherKey,
              keyset: keyset,
              using: using);
        } catch (e) {
          publishFileResult.description =
              'File message publish failed due to ${e.message} please refer fileInfo for file details';
          publishFileResult.isError = true;
        }
        if (!publishFileResult.isError) {
          return publishFileResult;
        }
        --retryCount;
      } while (retryCount > 0);
    }
    return publishFileResult..fileInfo = publishMessage.file;
  }

  /// This method allows to publish file Message
  /// In case `sendFile` method doesn't publish message to [channel], this method
  /// can be used to explicitly publish message
  ///
  /// Provide [cipherKey] to encrypt `message` it takes precedence over `keyset`'s cipherKey
  ///
  /// You can override the default account configuration on message
  /// saving using [storeMessage] flag - `true` to save and `false` to discard.
  /// Leave this option unset if you want to use the default.
  ///
  /// You can set a per-message time to live in storage using [ttl] option.
  /// If set to `0`, message won't expire.
  /// If unset, expiration will fall back to default.
  ///
  /// You can send additional information with [meta] parameter
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  Future<PublishFileMessageResult> publishFileMessage(
      String channel, FileMessage message,
      {bool storeMessage,
      int ttl,
      dynamic meta,
      CipherKey cipherKey,
      Keyset keyset,
      String using}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset.publishKey).isNotNull('publish key');

    var messagePayload = await _core.parser.encode(message);
    if (cipherKey != null || keyset.cipherKey != null) {
      messagePayload = await _core.parser.encode(
          _core.crypto.encrypt(cipherKey ?? keyset.cipherKey, messagePayload));
    }
    if (meta != null) meta = await _core.parser.encode(meta);
    return defaultFlow(
        logger: _logger,
        core: _core,
        params: PublishFileMessageParams(keyset, channel, messagePayload,
            storeMessage: storeMessage, ttl: ttl, meta: meta),
        serialize: (object, [_]) => PublishFileMessageResult.fromJson(object));
  }

  /// This method allows to download the file with [fileId] and [fileName] from channel [channel]
  /// It returns file content in bytes format `List<int>`
  ///
  /// Provide [cipherKey] to override default configuration of PubNub object's `keyset`'s `cipherKey`
  /// * It gives priority of [cipherKey] provided in method argument over `keyset`'s `cipherKey`
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  Future<DownloadFileResult> downloadFile(
      String channel, String fileId, String fileName,
      {CipherKey cipherKey, Keyset keyset, String using}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    Function decrypter;
    if (keyset.cipherKey != null || cipherKey != null) {
      decrypter = _core.crypto.decryptFileData;
    }
    return customFlow<DownloadFileParams, DownloadFileResult>(
        logger: _logger,
        core: _core,
        params: DownloadFileParams(getFileUrl(channel, fileId, fileName)),
        serialize: (object, [_]) => DownloadFileResult.fromJson(object,
            cipherKey: cipherKey ?? keyset.cipherKey,
            decryptFunction: decrypter));
  }

  /// This method gives list of all files information of channel [channel]
  ///
  /// You can limit this list by providing [limit] parameter
  ///
  /// Pagination can be managed by using [next] parameter
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  Future<ListFilesResult> listFiles(String channel,
      {int limit, String next, Keyset keyset, String using}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);

    return defaultFlow<ListFilesParams, ListFilesResult>(
        logger: _logger,
        core: _core,
        params: ListFilesParams(keyset, channel, limit: limit, next: next),
        serialize: (object, [_]) => ListFilesResult.fromJson(object));
  }

  /// It deletes file with [fileId], [fileName] from channel [channel]
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  Future<DeleteFileResult> deleteFile(
      String channel, String fileId, String fileName,
      {Keyset keyset, String using}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    return defaultFlow<DeleteFileParams, DeleteFileResult>(
        logger: _logger,
        core: _core,
        params: DeleteFileParams(keyset, channel, fileId, fileName),
        serialize: (object, [_]) => DeleteFileResult.fromJson(object));
  }

  /// It gives you the `Uri` to download the file with [fileId], [fileName] from channel [channel]
  ///
  /// You can your returned Url to download the file content by giving GET request
  ///
  /// * Ensure to manage decryption part since the returned content may be encrypted
  /// if file is uploaded in encrypted format
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  Uri getFileUrl(String channel, String fileId, String fileName,
      {Keyset keyset, String using}) {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    return Uri(scheme: 'https', host: 'ps.pndsn.com', pathSegments: [
      'v1',
      'files',
      keyset.subscribeKey,
      'channels',
      channel,
      'files',
      fileId,
      fileName
    ], queryParameters: {
      'pnsdk': 'PubNub-Dart/${Core.version}'
    });
  }

  /// This method helps to encrypt the file content in bytes format
  ///
  /// Provide [cipherKey] to override default configuration of PubNub object's `keyset`'s `cipherKey`
  /// * It gives priority of [cipherKey] provided in method argument over `keyset`'s `cipherKey`
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  List<int> encryptFile(List<int> bytes,
      {CipherKey cipherKey, Keyset keyset, String using}) {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    return _core.crypto.encryptFileData(cipherKey ?? keyset.cipherKey, bytes);
  }

  /// This method helps to decrypt the file content in bytes format
  ///
  /// Provide [cipherKey] to override default configuration of PubNub object's `keyset`'s `cipherKey`
  /// * it gives priority of [cipherKey] provided in method argument over `keyset`'s `cipherKey`
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  List<int> decryptFile(List<int> bytes,
      {CipherKey cipherKey, Keyset keyset, String using}) {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    return _core.crypto.decryptFileData(cipherKey ?? keyset.cipherKey, bytes);
  }
}
