## [v1.0.5](https://github.com/pubnub/dart/releases/tag/v1.0.5)
May 4 2020

[Full Changelog](https://github.com/pubnub/dart/compare/v1.0.4...v1.0.5)

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
