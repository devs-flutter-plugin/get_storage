import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../value.dart';

class StorageImpl {
  StorageImpl(this.fileName, [this.path]);

  final String? path;
  final String fileName;

  final ValueStorage<Map<String, dynamic>> subject =
      ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  RandomAccessFile? _randomAccessFile;

  void clear() {
    subject
      ..value.clear()
      ..changeValue('', null);
  }

  Future<void> deleteBox() async {
    await _randomAccessFile?.close();
    _randomAccessFile = null;

    final box = await _fileDb(isBackup: false);
    final backup = await _fileDb(isBackup: true);

    if (await box.exists()) await box.delete();
    if (await backup.exists()) await backup.delete();
  }

  Future<void> flush() async {
    final buffer = utf8.encode(jsonEncode(subject.value));
    final file = await _getRandomFile();

    await file.lock();
    try {
      await file.setPosition(0);
      await file.writeFrom(buffer);
      await file.truncate(buffer.length);
      await file.flush();
    } finally {
      await file.unlock();
    }

    await _makeBackup();
  }

  Future<void> _makeBackup() async {
    final backup = await _getFile(true);
    await backup.writeAsString(jsonEncode(subject.value), flush: true);
  }

  T? read<T>(String key) => subject.value[key] as T?;

  T getKeys<T>() => subject.value.keys as T;

  T getValues<T>() => subject.value.values as T;

  Future<void> init([Map<String, dynamic>? initialData]) async {
    subject.value = Map<String, dynamic>.from(
      initialData ?? const <String, dynamic>{},
    );

    final file = await _getRandomFile();
    if (await file.length() == 0) {
      await flush();
    } else {
      await _readFile();
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

  Future<void> _readFile() async {
    try {
      final file = await _getRandomFile();
      await file.setPosition(0);
      final buffer = Uint8List(await file.length());
      await file.readInto(buffer);

      final decoded = jsonDecode(utf8.decode(buffer));
      if (decoded is! Map) {
        throw const FormatException('Stored value is not a JSON object.');
      }
      subject.value = Map<String, dynamic>.from(decoded);
    } on Object {
      final backup = await _getFile(true);
      final content = (await backup.readAsString()).trim();

      if (content.isEmpty) {
        subject.value = <String, dynamic>{};
      } else {
        try {
          final decoded = jsonDecode(content);
          if (decoded is! Map) {
            throw const FormatException('Backup is not a JSON object.');
          }
          subject.value = Map<String, dynamic>.from(decoded);
        } on Object {
          subject.value = <String, dynamic>{};
        }
      }

      await flush();
    }
  }

  Future<RandomAccessFile> _getRandomFile() async {
    final cached = _randomAccessFile;
    if (cached != null) return cached;

    final fileDb = await _getFile(false);
    _randomAccessFile = await fileDb.open(mode: FileMode.append);
    return _randomAccessFile!;
  }

  Future<File> _getFile(bool isBackup) async {
    final fileDb = await _fileDb(isBackup: isBackup);
    if (!await fileDb.exists()) {
      await fileDb.create(recursive: true);
    }
    return fileDb;
  }

  Future<File> _fileDb({required bool isBackup}) async {
    final basePath = path ?? (await getApplicationDocumentsDirectory()).path;
    final extension = isBackup ? 'bak' : 'gs';
    final filePath =
        '$basePath${Platform.pathSeparator}$fileName.$extension';
    return File(filePath);
  }
}
