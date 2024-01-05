import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:ffi_espeak/ffi/espeak.dart';
import 'package:ffi_espeak/ffi/espeak_generated_bindings.dart' as es;
import 'package:wav/wav.dart';

typedef T = Int Function(Pointer<Short>, Int, Pointer<es.espeak_EVENT>);

Pointer<Char> path = Pointer<Char>.fromAddress(0);
Pointer<UnsignedInt> uniqueId = Pointer<UnsignedInt>.fromAddress(0);
Pointer<Void> userData = Pointer<Void>.fromAddress(0);

late int sampleRate;

final List<int> audioData = [];

void main() {
  final espeak = getEspeakLibrary();

  const int options = 0;
  const int position = 0,
      positionType = es.espeak_POSITION_TYPE.POS_CHARACTER,
      endPosition = 0,
      flags = es.espeakCHARS_AUTO | es.espeakPHONEMES | es.espeakENDPAUSE;

  sampleRate = espeak.espeak_Initialize(
    es.espeak_AUDIO_OUTPUT.AUDIO_OUTPUT_SYNCHRONOUS,
    100,
    path,
    options,
  );

  espeak.espeak_SetVoiceByName('English (Scotland)'.toNativeUtf8().cast<Char>());
  espeak.espeak_SetSynthCallback(Pointer.fromFunction<T>(synthCallback, 1));

  final text = 'hello world. How are you today?'.toNativeUtf8();
  final textPtr = text.cast<Void>();

  final result = espeak.espeak_Synth(
    textPtr,
    text.length + 1,
    position,
    positionType,
    endPosition,
    flags,
    uniqueId,
    userData,
  );

  espeak.espeak_Synchronize();
}

int synthCallback(
  Pointer<Short> wavFile,
  int numberOfSamples,
  Pointer<es.espeak_EVENT> events,
) {
  if (wavFile.address == 0) {
    final wave = Wav(
      [
        Float64List.fromList([...audioData.map((e) => e.toDouble())]),
        Float64List(0)
      ],
      sampleRate,
      WavFormat.pcm32bit,
    );

    final fileName = '${Directory.current.absolute.path}/example.wav';
    wave.writeFile(fileName);
    return 1;
  }

  audioData.addAll([
    for (var i = 0; i < numberOfSamples; i++) wavFile.elementAt(i).value,
  ]);

  print(
    'Type ${events.ref.type} | Audio Position ${events.ref.audio_position} | Text Position ${events.ref.text_position}',
  );
  return 0;
}
