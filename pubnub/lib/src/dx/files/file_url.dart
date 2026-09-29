import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/pam/extensions/keyset.dart';

/// Builds the [Uri] to download the file with [fileId] and [fileName] from [channel]
/// using [keyset].
///
/// @nodoc
Uri buildFileUrl(
    Keyset keyset, String channel, String fileId, String fileName) {
  // Validate input parameters to prevent path traversal attacks
  FileValidation.validateChannelName(channel);
  FileValidation.validateFileId(fileId);
  FileValidation.validateFileName(fileName);

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
    if (keyset.hasAuth()) 'auth': keyset.getAuth()
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
