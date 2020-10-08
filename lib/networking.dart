/// Default networking module used by PubNub SDK.
///
/// Uses `package:dio` under the hood.
///
/// {@category Modules}
library pubnub.networking;

export 'src/net/net.dart' show NetworkingModule;
export 'src/net/meta/meta.dart'
    show ExponentialRetryPolicy, LinearRetryPolicy, RetryPolicy;
