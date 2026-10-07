import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/pam/extensions/keyset.dart';

/// Builds the [Uri] to download the file with [fileId] and [fileName] from [channel]
/// using [keyset].
///
/// [origin] supplies the scheme, host, and port. When it is omitted, the Uri
/// uses `https` and `ps.pndsn.com`.
///
/// @nodoc
Uri buildFileUrl(Keyset keyset, String channel, String fileId, String fileName,
    {Uri? origin}) {
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
    scheme:
        origin != null && origin.scheme.isNotEmpty ? origin.scheme : 'https',
    host:
        origin != null && origin.host.isNotEmpty ? origin.host : 'ps.pndsn.com',
    port: origin != null && origin.hasPort ? origin.port : null,
    pathSegments: pathSegments,
    queryParameters: queryParams,
  );
}
