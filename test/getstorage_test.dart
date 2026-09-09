import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get_storage/src/storage/io.dart' as io_storage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  var containerSequence = 0;

  Future<GetStorage> createBox([Map<String, dynamic>? initialData]) async {
    final container = 'test_${containerSequence++}';
    final box = GetStorage(container, tempDirectory.path, initialData);
    await box.initStorage;
    return box;
  }

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('get_storage_test_');
  });

  tearDownAll(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('writes, reads, listens, and removes listeners', () async {
    final box = await createBox();
    String? listenedValue;

    final removeListener = box.listenKey('test', (value) {
      listenedValue = value as String?;
    });

    await box.write('test', 'a');
    expect(box.read<String>('test'), 'a');
    expect(listenedValue, 'a');

    removeListener();
    await box.write('test', 'b');

    expect(box.read<String>('test'), 'b');
    expect(listenedValue, 'a');
  });

  test('supports ReadWriteValue delegates', () async {
    final box = await createBox();
    final value = 0.val('counter', getBox: () => box);

    value.val = 42;
    await box.save();

    expect(value.val, 42);
  });

  test('writes only when a value is null', () async {
    final box = await createBox();

    await box.writeIfNull('key', 'first');
    await box.writeIfNull('key', 'second');

    expect(box.read<String>('key'), 'first');
  });

  test('removes and erases values', () async {
    final box = await createBox();

    await box.write('one', 1);
    await box.write('two', 2);
    await box.remove('one');

    expect(box.hasData('one'), isFalse);
    expect(box.read<int>('two'), 2);

    await box.erase();
    expect(box.getKeys<Iterable<String>>(), isEmpty);
  });

  test('returns stored keys and values in insertion order', () async {
    final box = await createBox();

    await box.write('key1', 1);
    await box.write('key2', 'a');
    await box.write('key3', 3.0);

    expect(
      box.getKeys<Iterable<String>>(),
      orderedEquals(<String>['key1', 'key2', 'key3']),
    );
    expect(
      box.getValues<Iterable<dynamic>>(),
      orderedEquals(<dynamic>[1, 'a', 3.0]),
    );
  });

  test('uses initial data when the container does not exist', () async {
    final box = await createBox(<String, dynamic>{'seed': 7});

    expect(box.read<int>('seed'), 7);
  });

  test('persists native data between storage instances', () async {
    const fileName = 'persistence_test';
    final first = io_storage.StorageImpl(fileName, tempDirectory.path);
    await first.init();
    first.write('value', 'persisted');
    await first.flush();

    final second = io_storage.StorageImpl(fileName, tempDirectory.path);
    await second.init();

    expect(second.read<String>('value'), 'persisted');
  });
}
