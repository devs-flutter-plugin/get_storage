import 'dart:convert';

import 'package:web/web.dart' as web;

import '../value.dart';

class StorageImpl {
  StorageImpl(this.fileName, [this.path]);

  final String? path;
  final String fileName;

  final ValueStorage<Map<String, dynamic>> subject =
      ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  web.Storage get localStorage => web.window.localStorage;

  void clear() {
    localStorage.removeItem(fileName);
    subject.value.clear();
    subject.changeValue('', null);
  }

  Future<void> flush() => _writeToStorage(subject.value);

  T? read<T>(String key) => subject.value[key] as T?;

  T getKeys<T>() => subject.value.keys as T;

  T getValues<T>() => subject.value.values as T;

  Future<void> init([Map<String, dynamic>? initialData]) async {
    subject.value = Map<String, dynamic>.from(
      initialData ?? const <String, dynamic>{},
    );

    final storedData = localStorage.getItem(fileName);
    if (storedData == null) {
      await _writeToStorage(subject.value);
      return;
    }

    try {
      final decoded = jsonDecode(storedData);
      if (decoded is! Map) {
        throw const FormatException('Stored value is not a JSON object.');
      }
      subject.value = Map<String, dynamic>.from(decoded);
    } on FormatException {
      await _writeToStorage(subject.value);
    }
  }

  void remove(String key) {
    subject
      ..value.remove(key)
      ..changeValue(key, null);
  }

  void write(String key, dynamic value) {
    subject
      ..value[key] = value
      ..changeValue(key, value);
  }

  Future<void> _writeToStorage(Map<String, dynamic> data) async {
    localStorage.setItem(fileName, jsonEncode(data));
  }
}
