# get_storage

A fast, lightweight key-value storage for Flutter, maintained by Devs Tecnologia from the original GetStorage project.

## Compatibility

- Flutter 3.47+
- Dart 3.13+
- Android
- iOS
- macOS
- Windows
- Linux
- Flutter Web (JavaScript)
- Flutter Web (WebAssembly / Wasm)

Native platforms persist data using files in the application documents directory. Web platforms use `window.localStorage` through `package:web`, without `dart:html`.

## Usage

```dart
import 'package:get_storage/get_storage.dart';

Future<void> main() async {
  await GetStorage.init();

  final box = GetStorage();

  await box.write('name', 'Lucas');
  final name = box.read<String>('name');

  await box.remove('name');
  await box.erase();
}
```

### In-memory batching

```dart
final box = GetStorage();

box.writeInMemory('one', 1);
box.writeInMemory('two', 2);
await box.save();
```

### ReadWriteValue

```dart
final box = GetStorage();
final counter = 0.val('counter', getBox: () => box);

counter.val = 10;
await box.save();
```

## WebAssembly

The web backend uses `package:web` and is selected with `dart.library.js_interop`, so applications can be compiled with:

```bash
flutter build web --wasm
```

## Repository

https://github.com/devs-flutter-plugin/get_storage

## License

MIT. The original license and attribution are preserved in `LICENSE`.
