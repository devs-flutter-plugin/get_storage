import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/utils.dart';

import 'storage/storage_stub.dart'
    if (dart.library.io) 'storage/io.dart'
    if (dart.library.js_interop) 'storage/web.dart';
import 'value.dart';

/// Instantiate GetStorage to access storage driver APIs.
class GetStorage {
  factory GetStorage(
    [String container = 'GetStorage',
    String? path,
    Map<String, dynamic>? initialData]
  ) {
    return _sync.putIfAbsent(
      container,
      () => GetStorage._internal(container, path, initialData),
    );
  }

  GetStorage._internal(
    String key, [
    String? path,
    Map<String, dynamic>? initialData,
  ]) {
    _concrete = StorageImpl(key, path);
    _initialData = initialData;

    initStorage = Future<bool>(() async {
      await _init();
      return true;
    });
  }

  static final Map<String, GetStorage> _sync = <String, GetStorage>{};

  /// Retained for backward compatibility with the original public surface.
  final Microtask microtask = Microtask();

  /// Serializes persistence operations.
  final GetQueue queue = GetQueue();

  /// Start the storage driver.
  static Future<bool> init([String container = 'GetStorage']) {
    WidgetsFlutterBinding.ensureInitialized();
    return GetStorage(container).initStorage;
  }

  Future<void> _init() => _concrete.init(_initialData);

  /// Reads a value in your container with the given key.
  T? read<T>(String key) => _concrete.read<T>(key);

  T getKeys<T>() => _concrete.getKeys<T>();

  T getValues<T>() => _concrete.getValues<T>();

  /// Returns true when the key contains a non-null value.
  bool hasData(String key) => read(key) != null;

  Map<String, dynamic> get changes => _concrete.subject.changes;

  /// Listen to all changes in the container.
  VoidCallback listen(VoidCallback value) {
    return _concrete.subject.addListener(value);
  }

  final Map<Function, Function> _keyListeners = <Function, Function>{};

  /// Listen to changes for a single key.
  VoidCallback listenKey(String key, ValueSetter callback) {
    final VoidCallback listener = () {
      if (changes.isNotEmpty && changes.keys.first == key) {
        callback(changes[key]);
      }
    };

    _keyListeners[callback] = listener;
    return _concrete.subject.addListener(listener);
  }

  /// Writes data to memory and persists it asynchronously.
  Future<void> write(String key, dynamic value) {
    writeInMemory(key, value);
    return _tryFlush();
  }

  /// Writes data only to memory. Call [save] to persist batched changes.
  void writeInMemory(String key, dynamic value) {
    _concrete.write(key, value);
  }

  /// Writes data only if the key does not already contain a value.
  Future<void> writeIfNull(String key, dynamic value) {
    if (read(key) != null) return Future<void>.value();
    return write(key, value);
  }

  /// Removes data from the container by key.
  Future<void> remove(String key) {
    _concrete.remove(key);
    return _tryFlush();
  }

  /// Clears all data in the container.
  Future<void> erase() {
    _concrete.clear();
    return _tryFlush();
  }

  /// Persists the current in-memory state.
  Future<void> save() => _tryFlush();

  Future<void> _tryFlush() => queue.add<void>(_flush);

  Future<void> _flush() => _concrete.flush();

  late StorageImpl _concrete;

  /// Listenable container state.
  ValueStorage<Map<String, dynamic>> get listenable => _concrete.subject;

  /// Completes when this container has initialized.
  late Future<bool> initStorage;

  Map<String, dynamic>? _initialData;
}

/// Original microtask helper retained for source compatibility.
class Microtask {
  int _version = 0;
  int _microtask = 0;

  void exec(Function callback) {
    if (_microtask == _version) {
      _microtask++;
      scheduleMicrotask(() {
        _version++;
        _microtask = _version;
        callback();
      });
    }
  }
}

typedef KeyCallback = Function(String);
