enum RequestType { get, post, patch, subscribe, delete }

extension RequestTypeExtension on RequestType {
  static const methods = {
    RequestType.get: 'GET',
    RequestType.post: 'POST',
    RequestType.patch: 'PATCH',
    RequestType.subscribe: 'GET',
    RequestType.delete: 'DELETE'
  };

  String get method => methods[this];
}
