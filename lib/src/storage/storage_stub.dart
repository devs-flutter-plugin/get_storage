import '../value.dart';

class StorageImpl {
  StorageImpl(this.fileName, [this.path]);

  final String? path;
  final String fileName;

  final ValueStorage<Map<String, dynamic>> subject =
      ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  Never _unsupported() {
    throw UnsupportedError(
      'GetStorage is not supported on this Dart platform.',
    );
  }

  void clear() => _unsupported();

  Future<void> flush() => _unsupported();

  T? read<T>(String key) => _unsupported();

  T getKeys<T>() => _unsupported();

  T getValues<T>() => _unsupported();

  Future<void> init([Map<String, dynamic>? initialData]) => _unsupported();

  void remove(String key) => _unsupported();

  void write(String key, dynamic value) => _unsupported();
}
