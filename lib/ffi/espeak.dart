import 'dart:ffi';
import 'dart:io';

import 'package:ffi_espeak/ffi/espeak_generated_bindings.dart';
import 'package:path/path.dart';

Espeak getEspeakLibrary() {
  return Espeak(
    DynamicLibrary.open(
      join(
        Directory.current.absolute.path,
        'native/espeak-ng-master/build/src/libespeak-ng/libespeak.dylib',
      ),
    ),
  );
}
