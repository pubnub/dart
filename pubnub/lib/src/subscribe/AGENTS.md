# Subscribe guide

`lib/src/subscribe/` delivers real-time data. One long-poll subscribe loop per keyset feeds every `Subscription` created for that keyset. Each subscription filters the shared stream down to its own channels and exposes typed event streams.

There is **no event engine, no subscription status stream, and no heartbeat timer** in this SDK. Do not port those designs from other PubNub SDKs, and do not document them.

## Key files

| File | Contents |
| --- | --- |
| `subscribe.dart` | `mixin SubscribeDx on Core`: `subscribe(...)` (creates and starts), `subscription(...)` (creates, inactive until started), `unsubscribeAll()`, `getSubscribedChannelsForUUID`, `getSubscribedChannelGroupsForUUID`. Keeps one `Manager` per `Keyset`. |
| `manager.dart` | `Manager` (`@nodoc`): owns the loop for one keyset. It merges the channels and groups of all live subscriptions, adding `-pnpres` channels when presence is requested, and exposes `whenStarts`, `restore`, `reconnect`, `unsubscribeAll`. |
| `subscribe_loop/subscribe_loop.dart` | `SubscribeLoop`: an `async*` long-poll loop that yields `Envelope`s. |
| `subscribe_loop/subscribe_loop_state.dart` | Immutable `SubscribeLoopState`, changed only through `clone(...)`. |
| `subscribe_loop/subscribe_fiber.dart` | `SubscribeFiber`: a stand-in `Fiber` so the loop can ask the supervisor for diagnostics and strategies. |
| `subscription.dart` | `Subscription`: lifecycle and typed streams. |
| `envelope.dart` | `Envelope`: one decoded subscribe message. |
| `events.dart` | `sealed class SubscriptionEvent` and its `final` subtypes: `MessageEvent`, `SignalEvent`, `MessageActionEvent`, `FileEvent`, `ObjectsEvent` (sealed, with `UuidMetadataEvent`, `ChannelMetadataEvent`, `MembershipMetadataEvent`), `DataSyncEvent`, `PresenceEvent`. |
| `projection.dart` | DataSync projection channel naming (see `../dx/datasync/AGENTS.md`). |
| `extensions/keyset.dart` | `filterExpression` and `heartbeatInterval`, stored in keyset settings. |
| `_endpoints/subscribe.dart` | `SubscribeParams` / `SubscribeResult`. |

## Loop behavior

- Every state change calls `update(...)` with a `clone`. An update cancels the in-flight long-poll request (`withCancel` and `UpdateException`) and starts a new one with the new channel set. `CancelException` and `UpdateException` are control flow, not errors.
- A successful response resets the retry count, stores the new timetoken and region, and yields envelopes.
- Decryption happens in the loop, not in `Subscription`. When a cipher key or `CryptoModule` is configured, the loop decrypts messages with `e` `null`, `0`, or `4` (messages and file events) on non-`-pnpres` channels. A decryption failure is attached to the envelope as `error`; it does not stop the loop.
- Errors go through `core.supervisor.runDiagnostics` and `runStrategies` with a `SubscribeFiber`. With no diagnostic or no strategy, the loop marks the state `isErrored` and yields the error to the stream. `Subscription.restore()` clears that state.
- The loop restarts on `signals.networkIsConnected`. `SupervisorDx.reconnect()` emits `NetworkIsDownEvent`.
- Heartbeat: the interval is only sent as the `heartbeat` query parameter of the subscribe request (`_endpoints/subscribe.dart`). An explicit heartbeat is `PresenceDx.announceHeartbeat` in `../dx/presence/presence.dart`.
- Presence is not a separate call. `withPresence: true` adds the `-pnpres` channel names to the same loop, and envelopes on those channels parse as `PresenceEvent`.

## Request path

- Subscribe does **not** use `defaultFlow`. `SubscribeParams.toRequest()` (`_endpoints/subscribe.dart`) adds `tt`, `tr`, `state`, `channel-group`, `auth`, `uuid`, `filter-expr`, `heartbeat`, and, with a `secretKey`, `timestamp` and the v2 signature itself. The loop then calls `handler.response` and `parser.decode` directly. Do not route subscribe through `defaultFlow` without removing those parameters from `SubscribeParams`, or they will be sent twice.
- Catch-up: `Manager._updateLoop` restarts the loop and passes the caller's timetoken as `customTimetoken`. After a response, the next timetoken is `customTimetoken` when set, otherwise the server's. `SubscribeLoopState.clone` clears `customTimetoken` when a new timetoken is passed. Read both before changing catch-up behavior.
- `FileEvent.url` is built by `buildFileUrl` (`../dx/files/file_url.dart`) from the manager's origin. It adds its own `pnsdk`, `uuid`, and signature.

## Subscription lifecycle

- `subscribe()` resumes a paused subscription, or asks the manager to reconnect. `unsubscribe()` is an alias of `pause()`. `cancel()` (alias `dispose()`) closes the subscription's streams and removes it from the manager; a cancelled subscription cannot be reused.
- `whenStarts` completes when the shared loop starts its next request. When the loop is already running, it completes with the following request.
- Streams: `events` (all `SubscriptionEvent`s), `messages` (`Stream<Envelope>`), `presence`, `signals`, `messageActions`, `files`, `objects`, `dataSync`. They are broadcast streams backed by one controller, which `cancel()` closes.
- `pubnub.unsubscribeAll()` cancels every manager; integration tests call it in teardown. `PubNub.dispose()` does **not** cancel subscriptions. It only releases logging and, for `NetworkingModule`, HTTP/2 connections.
- `withProjection` applies to `channels` only, never to channel groups. One subscription observes one projection; a second projection needs a second subscription.

## Invariants

- `SubscriptionEvent` and `ObjectsEvent` are `sealed`, and consumers `switch` over them exhaustively. Adding a subtype is a **breaking change**; it needs a `BREAKING CHANGES:` PR entry and a migration-guide item.
- Adding a subtype also means updating `SubscriptionEvent.fromEnvelope`, the `show` list in `lib/pubnub.dart`, and every exhaustive `switch` on `events` in the package, examples, and tests.
- `SubscriptionEvent.fromEnvelope` is the only parser and must stay a pure mapping from an `Envelope`. Unknown message types, and payloads that throw while parsing, return `null` and are discarded rather than thrown. Unit tests exercise it directly with the wire fixtures in `test/unit/subscribe/fixtures/`.
- A type-5 message that is not a DataSync payload is an ordinary `MessageEvent`. Never drop it (see `../dx/datasync/AGENTS.md`).
- Keep one subscribe loop per keyset. Do not give each subscription its own HTTP loop.
- Keep `SubscribeLoopState` immutable. Add new state as a field plus a `clone` parameter, never as a mutable field on the loop.
- Timetokens are `Timetoken` (`BigInt`) end to end. Do not round-trip them through `int`.

## Testing

- Unit: `test/unit/subscribe/`. Decode wire fixtures through `SubscriptionEvent.fromEnvelope` and assert the typed event. Loop and manager behavior go through `FakeNetworkingModule` with queued subscribe responses.
- Integration: `test/integration/subscribe/`. Await `subscription.whenStarts` before triggering the event under test, and wait for events with `.timeout(...)`. Follow the `dart-test-writer` skill.
