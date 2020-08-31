import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/files.dart';

import 'schema.dart';
import 'extensions/keyset.dart';

export 'schema.dart';
export 'extensions/keyset.dart';

class FileDx {
  final Core _core;
  FileDx(this._core);

  /// This method allows to send a [file] to a [channel] with an optional [fileMessage].
  ///
  /// > Ensure that your [Keyset] has a `publishKey` defined.
  ///
  /// If you provide a [cipherKey], the file will be encrypted with it.
  /// If its missing, then a `cipherKey` from [Keyset] will be used.
  /// If no `cipherKey` is provided, then the file won't be encrypted.
  ///
  /// If the upload was successful, but publishing the file event to the [channel] wasn't,
  /// this method will retry publishing up to a value configured in `fileMessagePublishRetryLimit`.
  /// In case that is unsuccessful, you can retry publishing the file event manually by passing [FileInfo]
  /// to the [publishFileMessage] method.
  ///
  /// #### Additional file event options
  /// * You can set a per-message time to live in storage using [fileMessageTtl] option.
  ///   If set to `0`, message won't expire. If unset, expiration will fall back to default.
  ///
  /// * You can override the default account configuration on message
  ///   saving using [storeFileMessage] flag - `true` to save and `false` to discard.
  ///   Leave this option unset if you want to use the default.
  ///
  /// * Provide [fileMessageMeta] for additional information
  Future<PublishFileMessageResult> sendFile(
      String channel, String fileName, List<int> file,
      {CipherKey cipherKey,
      dynamic fileMessage,
      bool storeFileMessage,
      int fileMessageTtl,
      dynamic fileMessageMeta,
      Keyset keyset,
      String using}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);

    Ensure(keyset.publishKey)
        .isNotNull('publish key is required for file upload');

    var requestPayload = await _core.parser.encode({'name': fileName});

    var uploadDetails = await defaultFlow<GenerateFileUploadUrlParams,
            GenerateFileUploadUrlResult>(
        core: _core,
        params: GenerateFileUploadUrlParams(keyset, channel, requestPayload),
        serialize: (object, [_]) =>
            GenerateFileUploadUrlResult.fromJson(object));

    if (keyset.cipherKey != null || cipherKey != null) {
      file = _core.crypto.encryptFileData(cipherKey ?? keyset.cipherKey, file);
    }

    // TODO: Decide what to do here
    // form['file'] = _fileManager.createMultipartFile(_fileManager.read(file),
    //     fileName: fileName);

    var fileInfo = FileInfo(
      uploadDetails.fileId,
      uploadDetails.fileName,
      getFileUrl(channel, uploadDetails.fileId, uploadDetails.fileName)
          .toString(),
    );

    var publishMessage = FileMessage(fileInfo, message: fileMessage);

    var retryCount = keyset.fileMessagePublishRetryLimit;

    var s3Response = await defaultFlow<FileUploadParams, FileUploadResult>(
        core: _core,
        params: FileUploadParams(uploadDetails.uploadUri,
            {...uploadDetails.formFields, 'file': file}),
        deserialize: false,
        serialize: (object, [_]) => FileUploadResult.fromJson(object));

    var publishFileResult = PublishFileMessageResult();

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
    return defaultFlow<DownloadFileParams, DownloadFileResult>(
        core: _core,
        params: DownloadFileParams(getFileUrl(channel, fileId, fileName)),
        deserialize: false,
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
    ]);
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
