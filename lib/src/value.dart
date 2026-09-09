import 'package:get/state_manager.dart';

class ValueStorage<T> extends Value<T> {
  ValueStorage(T value) : super(value);

  Map<String, dynamic> changes = <String, dynamic>{};

  /// GetX 4.7.4 exposes Value<T>.value as T? even when the Value was
  /// initialized with a non-null T. GetStorage always initializes its
  /// ValueStorage with a concrete value, so expose that invariant here once
  /// instead of propagating nullable casts through every storage backend.
  @override
  T get value {
    final current = super.value;
    if (current == null) {
      throw StateError('ValueStorage cannot contain a null value.');
    }
    return current;
  }

  void changeValue(String key, dynamic value) {
    changes = {key: value};
    refresh();
  }
}
