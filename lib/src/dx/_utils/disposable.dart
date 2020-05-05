import 'dart:async';

abstract class Disposable {
  bool get isDisposed;
  Future<void> get didDispose;

  Future<void> dispose();
}
