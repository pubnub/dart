import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/files.dart';

import 'schema.dart';
import 'extensions/keyset.dart';

export 'schema.dart';
export 'extensions/keyset.dart';
export '../_endpoints/files.dart'
    show
        PublishFileMessageResult,
        DeleteFileResult,
        DownloadFileResult,
        FileUploadResult,
        GenerateFileUploadUrlResult,
        ListFilesResult,
        FileDetail;

/// Groups **file** methods together.
///
/// Available as [PubNub.files].
/// Introduced with [File API](https://www.pubnub.com/docs/platform/messages/files).
///
/// {@category Files}
class FileDx {
  final Core _core;

  /// @nodoc
  FileDx(this._core);

  /// This method allows to send a [file] to a [channel] with an optional [fileMessage].
  ///
  /// > Ensure that your [Keyset] has a `publishKey` defined.
  ///
  /// If you provide a [cipherKey], the file will be encrypted with it.
  /// If its missing, then [Keyset.cipherKey] will be used.
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
  /// * Provide [fileMessageMeta] for additional information.
  Future<PublishFileMessageResult> sendFile(
      String channel, String fileName, List<int> file,
      {CipherKey? cipherKey,
      dynamic? fileMessage,
      bool? storeFileMessage,
      int? fileMessageTtl,
      dynamic? fileMessageMeta,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    var requestPayload = await _core.parser.encode({'name': fileName});

    var uploadDetails = await defaultFlow<GenerateFileUploadUrlParams,
            GenerateFileUploadUrlResult>(
        keyset: keyset,
        core: _core,
        params: GenerateFileUploadUrlParams(keyset, channel, requestPayload),
        serialize: (object, [_]) =>
            GenerateFileUploadUrlResult.fromJson(object));

    if (keyset.cipherKey != null || cipherKey != null) {
      file = _core.crypto.encryptFileData(cipherKey ?? keyset.cipherKey!, file);
    }

    var fileInfo = FileInfo(
      uploadDetails.fileId,
      uploadDetails.fileName,
      getFileUrl(channel, uploadDetails.fileId, uploadDetails.fileName,
              keyset: keyset)
          .toString(),
    );

    var publishMessage = FileMessage(fileInfo, message: fileMessage);

    var retryCount = keyset.fileMessagePublishRetryLimit;

    var params = FileUploadParams(
        uploadDetails.uploadUri, {...uploadDetails.formFields, 'file': file});

    await defaultFlow<FileUploadParams, FileUploadResult>(
        keyset: keyset,
        core: _core,
        params: params,
        deserialize: false,
        serialize: (object, [_]) => FileUploadResult.fromJson(object));

    var publishFileResult = PublishFileMessageResult();

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
            'File message publish failed due to $e please refer fileInfo for file details';
        publishFileResult.isError = true;
      }
      if (!publishFileResult.isError!) {
        publishFileResult.fileInfo = fileInfo;
        return publishFileResult;
      }
      --retryCount;
    } while (retryCount > 0);

    return publishFileResult..fileInfo = fileInfo;
  }

  /// Allows to publish file message.
  ///
  /// In case `sendFile` method doesn't publish message to [channel], this method
  /// can be used to explicitly publish message
  ///
  /// Provide [cipherKey] to encrypt the message. It takes precedence over [Keyset.cipherKey].
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
      {bool? storeMessage,
      int? ttl,
      dynamic? meta,
      CipherKey? cipherKey,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];
    Ensure(keyset.publishKey).isNotNull('publish key');

    var messagePayload = await _core.parser.encode(message);
    if (cipherKey != null || keyset.cipherKey != null) {
      messagePayload = await _core.parser.encode(
          _core.crypto.encrypt(cipherKey ?? keyset.cipherKey!, messagePayload));
    }
    if (meta != null) meta = await _core.parser.encode(meta);
    return defaultFlow(
        keyset: keyset,
        core: _core,
        params: PublishFileMessageParams(keyset, channel, messagePayload,
            storeMessage: storeMessage, ttl: ttl, meta: meta),
        serialize: (object, [_]) => PublishFileMessageResult.fromJson(object));
  }

  /// This method allows to download the file with [fileId] and [fileName] from channel [channel]
  /// It returns file content in bytes format `List<int>`.
  ///
  /// Provided [cipherKey] overrides [Keyset.cipherKey].
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  Future<DownloadFileResult> downloadFile(
      String channel, String fileId, String fileName,
      {CipherKey? cipherKey, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    return defaultFlow<DownloadFileParams, DownloadFileResult>(
        keyset: keyset,
        core: _core,
        params: DownloadFileParams(getFileUrl(channel, fileId, fileName)
            .replace(scheme: '', host: '')),
        deserialize: false,
        serialize: (object, [_]) => DownloadFileResult.fromJson(object,
            cipherKey: cipherKey ?? keyset!.cipherKey,
            decryptFunction: _core.crypto.decryptFileData));
  }

  /// Lists all files in a [channel].
  ///
  /// You can limit this list by providing [limit] parameter.
  ///
  /// Pagination can be managed by using [next] parameter.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  Future<ListFilesResult> listFiles(String channel,
      {int? limit, String? next, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    return defaultFlow<ListFilesParams, ListFilesResult>(
        keyset: keyset,
        core: _core,
        params: ListFilesParams(keyset, channel, limit: limit, next: next),
        serialize: (object, [_]) => ListFilesResult.fromJson(object));
  }

  /// Deletes file with [fileId] and [fileName] from [channel].
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  Future<DeleteFileResult> deleteFile(
      String channel, String fileId, String fileName,
      {Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];
    return defaultFlow<DeleteFileParams, DeleteFileResult>(
        keyset: keyset,
        core: _core,
        params: DeleteFileParams(keyset, channel, fileId, fileName),
        serialize: (object, [_]) => DeleteFileResult.fromJson(object));
  }

  /// Returns [Uri] to download the file with [fileId] and [fileName] from [channel].
  ///
  /// You can download the file by making a GET request to returned Uri.
  ///
  /// > If the file is encrypted, you will have to decrypt it on your own.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  Uri getFileUrl(String channel, String fileId, String fileName,
      {Keyset? keyset, String? using}) {
    keyset ??= _core.keysets[using];
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
    var queryParams = {
      'pnsdk': 'PubNub-Dart/${Core.version}',
      'uuid': keyset.uuid.value,
      if (keyset.secretKey != null)
        'timestamp': '${Time().now()!.millisecondsSinceEpoch ~/ 1000}',
      if (keyset.authKey != null) 'auth': keyset.authKey!
    };
    if (keyset.secretKey != null) {
      queryParams.addAll(
          {'signature': computeSignature(keyset, pathSegments, queryParams)});
    }

    return Uri(
      scheme: 'https',
      host: 'ps.pndsn.com',
      pathSegments: pathSegments,
      queryParameters: queryParams,
    );
  }

  /// Encrypts file content in bytes format.
  ///
  /// Provide [cipherKey] to override [Keyset.cipherKey].
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  List<int> encryptFile(List<int> bytes,
      {CipherKey? cipherKey, Keyset? keyset, String? using}) {
    keyset ??= _core.keysets[using];
    return _core.crypto
        .encryptFileData((cipherKey ?? keyset.cipherKey)!, bytes);
  }

  /// Decrypts file content in bytes format.
  ///
  /// Provide [cipherKey] to override [Keyset.cipherKey].
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  List<int> decryptFile(List<int> bytes,
      {CipherKey? cipherKey, Keyset? keyset, String? using}) {
    keyset ??= _core.keysets[using];
    return _core.crypto
        .decryptFileData((cipherKey ?? keyset.cipherKey)!, bytes);
  }
}
