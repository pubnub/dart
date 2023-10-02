import 'dart:io';

String getCryptoFilePath(String filename) {
  var assets = Directory(
      '../../service-contract-mock/contract/features/encryption/assets');
  return '${assets.path}/$filename';
}

bool listEquals<E>(List<E> list1, List<E> list2) {
  if (identical(list1, list2)) {
    return true;
  }

  if (list1.length != list2.length) {
    return false;
  }

  for (var i = 0; i < list1.length; i += 1) {
    if (list1[i] != list2[i]) {
      return false;
    }
  }

  return true;
}
