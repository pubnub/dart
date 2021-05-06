/// @nodoc
enum RequestType { get, post, patch, subscribe, delete, file }

const _sendTimeoutRequestDefault = {
  RequestType.get: 10000,
  RequestType.post: 10000,
  RequestType.delete: 10000,
  RequestType.patch: 10000,
  RequestType.subscribe: 300000,
  RequestType.file: 30000,
};

const _receiveTimeoutRequestDefault = {
  RequestType.get: 10000,
  RequestType.post: 10000,
  RequestType.delete: 10000,
  RequestType.patch: 10000,
  RequestType.subscribe: 300000,
  RequestType.file: 30000,
};

const _connectTimeoutRequestDefault = {
  RequestType.get: 10000,
  RequestType.post: 10000,
  RequestType.delete: 10000,
  RequestType.patch: 10000,
  RequestType.subscribe: 300000,
  RequestType.file: 30000,
};

/// @nodoc
extension RequestTypeExtension on RequestType {
  static const methods = {
    RequestType.get: 'GET',
    RequestType.post: 'POST',
    RequestType.patch: 'PATCH',
    RequestType.subscribe: 'GET',
    RequestType.delete: 'DELETE',
    RequestType.file: 'POST',
  };

  String get method => methods[this]!;

  int get sendTimeout => _sendTimeoutRequestDefault[this]!;
  int get receiveTimeout => _receiveTimeoutRequestDefault[this]!;
  int get connectTimeout => _connectTimeoutRequestDefault[this]!;
}
