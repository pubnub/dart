# PubNub Dart SDK Flutter Extensions

[![Pub Version](https://img.shields.io/pub/v/pubnub)](https://pub.dev/packages/pubnub)

> `pubnub-flutter` is a collection of extensions that integrate with Flutter applications.

## Installation

### Using `pub` dependency management tool

`pubnub` uses the standard `pub` tool for package management to distribute Dart code.

To add the package to your Dart or Flutter project, add `pubnub` as a dependency in your `pubspec.yaml`.

```yaml
dependencies:
  pubnub_flutter: ^1.0.0
```

After adding the dependency to `pubspec.yaml`, run the `pub get` command in the root directory of your project (the same that the `pubspec.yaml` is in).

### Using Git

If you want to use the latest, unreleased version of `pubnub`, you can add it to `pubspec.yaml` as a Git package.

```yaml
dependencies:
  pubnub:
    git: git://github.com/pubnub/dart.git
    path: pubnub_flutter
```

### Using a local copy of the repository

If you want to copy the Dart repository and modify it locally, clone it using `git clone https://github.com/pubnub/dart` and then import it into `pubspec.yaml` as follows:

```yaml
dependencies:
  pubnub:
    path: ../path-to-cloned-pubnub-repo
```

## Importing

After you install the `pubnub_flutter` package, import it in your application.
You can import it in one of two ways:

```dart
// Import all PubNub objects into your namespace
import 'package:pubnub_flutter/pubnub_flutter.dart';
```
