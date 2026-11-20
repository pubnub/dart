# Subscribe

How subscriptions and typed events work. Confirm details against `lib/src/subscribe/`. DataSync event rules also live in [datasync.md](datasync.md).

## Lifecycle

`PubNub` mixes in `SubscribeDx`. Each `Keyset` gets one `Manager` and one `SubscribeLoop`. Subscriptions on that keyset are multiplexed into a single `/v2/subscribe/...` call. Adding or removing a subscription rebuilds the channel set and restarts the loop.

- `pubnub.subscribe(...)` creates a subscription and resumes it.
- `pubnub.subscription(...)` creates an inactive subscription. Activate it with `subscription.subscribe()`.
- `subscription.dispose()` / `cancel()` removes it from the manager. A cancelled subscription cannot be reused.
- `pubnub.unsubscribeAll()` cancels every manager. Integration `tearDown` uses this.
- `PubNub.dispose()` does not cancel subscriptions. It releases logging and, for `NetworkingModule`, HTTP/2 connections.

Presence is not a separate subscribe call. `withPresence: true` adds the `-pnpres` suffixed names to the same loop. Channels ending in `-pnpres` parse as `PresenceEvent`.

## Projections

`withProjection` applies only to `channels`, not channel groups. `normalizeProjection` treats null, blank, `default`, and `__default__` (any case) as the base projection: channels are subscribed as given. Any other trimmed name becomes `__{name}__{id}` via `projectionChannel`. Ids are copied verbatim, so a wildcard such as `customer.*` stays a wildcard. Do not pre-prefix ids.

One subscription observes one projection. A second projection is a second subscription.

## Events

`SubscriptionEvent` is a sealed class. Subtypes: `MessageEvent`, `SignalEvent`, `MessageActionEvent`, `FileEvent`, `ObjectsEvent`, `DataSyncEvent`, `PresenceEvent`.

`SubscriptionEvent.fromEnvelope` is the only parser. Message type integers are `MessageType` (`0` normal, `1` signal, `2` objects, `3` message action, `4` file, `5` data sync, anything else `unknown`). Unknown types and payloads that throw while parsing return `null` and are discarded.

Typed streams on `Subscription` (`messages`, `signals`, `messageActions`, `files`, `objects`, `dataSync`, `presence`) filter `events`. Handle every kind with an exhaustive `switch` on `events`. Adding a subtype means updating `fromEnvelope`, the `show` list in `lib/pubnub.dart`, and those switches.

Decrypt runs in the subscribe loop before `Envelope.fromJson`, for message types null/`0`/`4` when a cipher key is set or `crypto` is a `CryptoModule`, except presence channels. Failure is stored on the envelope and exposed as `MessageEvent.error`; the event is still delivered.

## Request path

`SubscribeLoop` does not call `defaultFlow`. It builds `SubscribeParams`, which already sets `tt`, `uuid`, optional `auth`, `filter-expr`, `heartbeat`, channel groups (`channel-group`), region (`tr`), and the v2 signature when `secretKey` is set. The loop then calls `handler.response` and `parser.decode` itself.

`SubscribeParams` sends `state.timetoken`. `Manager._updateLoop` sets that timetoken to `0` and stores the caller's timetoken as `customTimetoken`. After a response, the next timetoken is `customTimetoken` when it is set, otherwise the server timetoken. `SubscribeLoopState.clone` clears `customTimetoken` when a new timetoken is passed. Read both methods before changing catch-up behavior.

`RequestType.subscribe` uses the long timeout (300000 ms). The loop retries through the supervisor with its own `SubscribeFiber`. It does not use the `Fiber` inside `defaultFlow`. `UpdateException` and `CancelException` restart the loop without a diagnostic.

`FileEvent.url` calls `buildFileUrl` (`lib/src/dx/files/file_url.dart`). `Manager.origin` supplies scheme, host, and port only. The file URL sets its own `pnsdk`, `uuid`, and, when `secretKey` is set, `timestamp` and signature.

## What not to change casually

- Do not give each subscription its own HTTP subscribe loop.
- Do not route subscribe through `defaultFlow` without removing the auth, uuid, and signature already added in `SubscribeParams`.
- Do not drop type `5` messages that fail `DataSyncEvent._isDataSyncPayload`. Those are ordinary messages.
- Channel name on the event is the wire channel, which is the projection channel when a projection is set. Match on that string.
