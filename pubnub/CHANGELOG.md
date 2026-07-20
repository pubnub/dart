## v8.0.1
July 20 2026

#### Fixed
- Added deprecation warning for legacy cryptor configuration, cipherKey initialisation at Keyset level.
- Refactored exception handling in cryptors without revealing extensive details of failure.

## v8.0.0
July 06 2026

#### Added
- **BREAKING CHANGES**: added support for h2 protocol using http2 package.

## v7.1.0
February 25 2026

#### Added
- Migration from dart html package to web for wasm compatibility.

## v7.0.1
November 17 2025

#### Modified
- Remove invalid switch cases for null message type which was causing issue with web assembly build. Fixed the following issues reported by [@Ali-Toosi](https://github.com/Ali-Toosi): [#145](https://github.com/pubnub/dart/issues/145).

## v7.0.0
October 28 2025

#### Added
- BREAKING CHANGES: The `hereNow` method will return a maximum of 1000 occupants per channel. Previously, it was returning all occupants without limit parameter support. Use pagination through offset when more than 1000 occupants present in channel.

#### Fixed
- Fixes issue of not getting proper error details when file upload fails.
- Fixes issue of no-op when `subscribe()` called on inactive or errored subscrption.
- Fixes issue of generate upload file url to incorporate token when configured or set explicitly.
- Discard use of gcm and replaced with fcm for push notification service type of google.

#### Modified
- Pubnub access manager tests.

## v6.0.2
October 20 2025

#### Fixed
- Fixes issue of delete message with `from` and `to` parameters. To delete range of message(s).

## v6.0.1
August 19 2025

#### Fixed
- Fixes package compatibility issues with web builds.

#### Modified
- Allow global custom logger to be ILogger based.
- Upgrade outdated dependencies.

## v6.0.0
August 06 2025

#### Added
- BREAKING CHANGES: Added support for `RetryPolicy.none()` to disable retry for subscription.

#### Modified
- Enhanced logging using standardized logging practices.

## v5.2.1
June 25 2025

#### Fixed
- Update and validation for `custom` field data type of app context apis to prevent accepting non scalar value.
- Added validation for channel and file names to prevent potential various path traversal techniques.

## v5.2.0
March 12 2025

#### Added
- Added Support of `eTag` for AppContext `setUUIDMetadata` and `setChannelMetadata` APIs.

## v5.1.1
January 20 2025

#### Fixed
- Fixes issue of getting error for setUUIDMetadata call without `custom` field.

## v5.1.0
December 18 2024

#### Added
- Added support for `status` and `type` fields in AppContext APIs.

## v5.0.0
December 10 2024

#### Added
- BREAKING CHANGES: support for customMessageType in subscription, history, publish, signal and files features.

## v4.3.4
April 15 2024

#### Fixed
- Fixes issue of parsing invalid presence data (which are not from pubnub server) in subscription.

## v4.3.3
March 28 2024

#### Added
- Added support for pagination params for listChannels api of push notification devices.

## v4.3.2
January 22 2024

#### Fixed
- Fixes issue of getting signature mismatch exception while publishing encrypted data.

## v4.3.1
November 27 2023

#### Fixed
- Handle unencrypted message while getting messages with cryptoModule configured.

## v4.3.0
October 16 2023

#### Added
- Add crypto module that allows configure SDK to encrypt and decrypt messages.

#### Fixed
- Improved security of crypto implementation by adding enhanced AES-CBC cryptor.

## v4.2.4
July 27 2023

#### Fixed
- Fixes issue of missing decrypt function in batch history api.

## v4.2.3
May 18 2023

#### Fixed
- Fixes issue of losing timetoken value precision in web environment. Fixed the following issues reported by [@RicharC293](https://github.com/RicharC293): [#110](https://github.com/pubnub/dart/issues/110).

## v4.2.2
November 14 2022

#### Added
- Support for Flutter 3.

#### Fixed
- Fixes issue of having old version of xml package dependency. Fixed the following issues reported by [@panalgin](https://github.com/panalgin): [#94](https://github.com/pubnub/dart/issues/94).

## v4.2.1
July 12 2022

#### Added
- Support for fire in publish feature.
- Allow to specify access rights for user and space in grantToken request.
- Allow users to specify userId instead of uuid.

## v4.1.3
April 21 2022

#### Fixed
- Fixes issue of `fetchMessages` with false includeUUID response parse error. Fixed the following issues reported by [@linsdev](https://github.com/linsdev): [#89](https://github.com/pubnub/dart/issues/89).
- Fixes issue of publish file message not triggered on browser.

## v4.1.2
April 06 2022

#### Fixed
- Adds a fix that prevents the SDK from adding forbidden headers in browser environments.
- Fixes getFileUrl method by adding uuid in query parameters.

## v4.1.1
April 04 2022

#### Fixed
- Fixes an issue in JS build of Dart SDK, where request bodies were improperly encoded and sent without a correct header.

## v4.1.0
December 16 2021

#### Added
- Added support for Revoke Token feature.

## v4.0.0
November 22 2021

#### Added
- Adds PAM v3 support with `grantToken` and `setToken`.
- After subscribe loop fails, call restore to restart it.

#### Fixed
- Subscribe loop no longer throws on unrecoverable failure, instead waits for restart. Fixed the following issues reported by [@willbryant](https://github.com/willbryant): [#63](https://github.com/pubnub/dart/issues/63).
- Adds more diagnostics for network module. Fixed the following issues reported by [@willbryant](https://github.com/willbryant): [#65](https://github.com/pubnub/dart/issues/65).
- WhenStarts future no longer throws and is now based on a stream. Fixed the following issues reported by [@willbryant](https://github.com/willbryant): [#64](https://github.com/pubnub/dart/issues/64).
- Networking should now release all resources after a failure. Fixed the following issues reported by [@aadil058](https://github.com/aadil058): [#62](https://github.com/pubnub/dart/issues/62).
- Fixes issue of Signature mismatch with PAM enabled keysets. Fixed the following issues reported by [@mahmoudsalah37](https://github.com/mahmoudsalah37): [#50](https://github.com/pubnub/dart/issues/50).
- Fixes issue of message decryption with subscription. Fixed the following issues reported by [@TabooSun](https://github.com/TabooSun): [#46](https://github.com/pubnub/dart/issues/46).

## [v3.0.0](https://github.com/pubnub/dart/releases/tag/v3.0.0)
October 8 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v2.0.1...v3.0.0)

- ⭐️️ Subscribe loop is now written using async generator and should be easier to debug. 
- ⭐️️ Exports now are more comprehensive and clear, documentation clarity has been improved. 
- 🐛 Removes additional query params from AWS calls. 
- 🐛 Fixes a bunch of issues with incorrect arguments passed in. 
- 🐛 Adds additional diagnostics to the networking module. 

## [v2.0.1](https://github.com/pubnub/dart/releases/tag/v2.0.1)
September 7 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v2.0.0...v2.0.1)

- 🐛 Fixes issue of upgrade failure. Fixed the following issues reported by [@devopsokdone](https://github.com/devopsokdone): [#14](https://github.com/pubnub/dart/issues/14).

## [v2.0.0](https://github.com/pubnub/dart/releases/tag/v2.0.0)
August 31 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.4.4...v2.0.0)

- 🌟️ Refactors networking module to allow additional flexibility. 
- 🌟️ Adds supervisor module that allows reconnection, retry and other additional, cross module functionalities. 
- 🌟️ Adds meta parameter to publish call and makes publish using GET instead of POST. 
- 🐛 Exposes `batch`, `objects` and other APIs from the PubNub class. Fixed the following issues reported by [@devopsokdone](https://github.com/devopsokdone): [#11](https://github.com/pubnub/dart/issues/11).
- 🐛 Fixes a typo in BatchHistory where timetoken was returned null. Fixed the following issues reported by [@devopsokdone](https://github.com/devopsokdone): [#13](https://github.com/pubnub/dart/issues/13).

## [v1.4.4](https://github.com/pubnub/dart/releases/tag/v1.4.4)
August 19 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.4.3...v1.4.4)

- 🌟️ Add flags in history v3 for including messageType and uuid. 
- 🌟️ Add support for fetch history with message actions. Fixed the following issues reported by [@edissonaguilar](https://github.com/edissonaguilar): [#12](https://github.com/pubnub/dart/issues/12).
- ⭐️️ Refactor for error message parsing for files. 

## [v1.4.3](https://github.com/pubnub/dart/releases/tag/v1.4.3)
August 5 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.4.2...v1.4.3)

- 🐛 Fixes issue of exception from server when publishKey os null with publish call. 
- 🐛 Fixes missing url component in file publish message for sendFile and support for message encryption. 

## [v1.4.2](https://github.com/pubnub/dart/releases/tag/v1.4.2)
July 27 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.4.1...v1.4.2)

- 🐛 Fixes issue of invalid type argument for fcm push gateway type. Fixed the following issues reported by [@vikram25897](https://github.com/vikram25897): [#10](https://github.com/pubnub/dart/issues/10).

## [v1.4.1](https://github.com/pubnub/dart/releases/tag/v1.4.1)
July 24 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.4.0...v1.4.1)

- 🐛 Fixes issue of missing exposed MessageType enum. 

## [v1.4.0](https://github.com/pubnub/dart/releases/tag/v1.4.0)
July 23 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.3.0...v1.4.0)

- 🌟️ Add file apis to support file feature. 
- ⭐️️ Add support for random initialization vector for messages and file. 

## [v1.3.0](https://github.com/pubnub/dart/releases/tag/v1.3.0)
June 25 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.2.0...v1.3.0)

- 🌟️ Add message encryption support. 

## [v1.2.0](https://github.com/pubnub/dart/releases/tag/v1.2.0)
June 10 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.1.3...v1.2.0)

- 🌟️ Add simplified Objects API support with UUID and Channel metadata / membership management. 
- 🐛 Fixes missing PushGateway type support of fcm for Push Notification. 

## [v1.1.3](https://github.com/pubnub/dart/releases/tag/v1.1.3)
May 11 2020

- 🐛 Fixes unsubscribeAll so its no longer modifying subscription list during iteration. Fixed the following issues reported by [@pushpendraKh](https://github.com/pushpendraKh): [#6](https://github.com/pubnub/dart/issues/6).
- 🐛 Fixes exports to include presence and channel group results. 

## [v1.1.2](https://github.com/pubnub/dart/releases/tag/v1.1.2)
May 6 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.1.1...v1.1.2)

- 🐛 Fixes issues of missing types for objects and push-notification. Fixed the following issues reported by [@pushpendraKh](https://github.com/pushpendraKh): [#5](https://github.com/pubnub/dart/issues/5).

## [v1.1.1](https://github.com/pubnub/dart/releases/tag/v1.1.1)
May 6 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.1.0...v1.1.1)

- 🐛 Expose missing types. 

## [v1.1.0](https://github.com/pubnub/dart/releases/tag/v1.1.0)
May 5 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.0.5...v1.1.0)

- ⭐️️ Bumps cbor package version and fixes analyzer warnings. 
- ⭐️️ Removes many dependencies that are unnecessary. 
- ⭐️️ Build_runner is no longer necessary to use. 
- 🐛 Refactors logging to rely on Zones. 
- 🐛 Fixes issues with resubscribing and improves injectLogger. 

## [v1.0.5](https://github.com/pubnub/dart/releases/tag/v1.0.5)
May 4 2020

- 🐛 Fix wrong API Uri in Push Notifications. Fixed the following issues reported by [@aadil058](https://github.com/aadil058): [#2](https://github.com/pubnub/dart/issues/2).
- 🐛 Fix Subscription.unsubscribe to correctly close the messages stream. Fixed the following issues reported by [@are](https://github.com/are): [#3](https://github.com/pubnub/dart/issues/3).

## [v1.0.4](https://github.com/pubnub/dart/releases/tag/v1.0.4)
April 27 2020

- 🌟️ Add HereNow to PresenceDx, usable as `pubnub.hereNow()`. 
- 🐛 Fix subscribe `withPresence: true` not properly forwarding messages when used with wildcard channels. 

## [v1.0.3](https://github.com/pubnub/dart/releases/tag/v1.0.3)
April 22 2020

- ⭐️️ Fix a typo in UserDx docstring. 
- 🐛 Change all Symbols to Strings to support Flutter better, fix a typo in SubscribeParams preventing subscribe from working. 

## [v1.0.2](https://github.com/pubnub/dart/releases/tag/v1.0.2)
April 18 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.0.1...v1.0.2)

- ⭐️️ Add backward synchronization to private repository for `pubspec.yaml` and `lib/src/core/core.dart`. 
- ⭐️️ Prevent tests from breaking when version is bumped. 

## [v1.0.1](https://github.com/pubnub/dart/releases/tag/v1.0.1)
April 18 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.0.0...v1.0.1)

- ⭐️️ Refactor PAM, hide logger instances and clean up tests. 
- ⭐️️ Add `package:pedantic` config to analysis, fix lint issues. 
- ⭐️️ Removes dummy changelog entry. 
- ⭐️️ Add simple example. 
- ⭐️️ Improve package description. 
- ⭐️️ Clean up test prefixes. 
- 🐛 Ensure()isEqual now uses correct template. 
- 🐛 Add PAM to library exports. 
- 🐛 Consistently use PubNubversion in tests. 

## [v1.0.0](https://github.com/pubnub/dart/releases/tag/v1.0.0)
April 15 2020

- 🌟️ Add ability to fetch current PubNub timetoken. 
- 🌟️ Add ability to publish messages and signals to channels and channel groups. 
- 🌟️ Add ability to subscribe to channels and channel groups. 
- 🌟️ Add ability to manage Objects (Spaces, Users and Memberships). 
- 🌟️ Add ability to manage PubNub Access Manager. 
- 🌟️ Add ability to manage device registration for Push Notification Service. 
- 🌟️ Add ability to add, delete and retrieve message actions. 
- 🌟️ Add channel and channel group abstractions to allow using History. 
