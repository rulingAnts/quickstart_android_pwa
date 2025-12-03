import 'package:test/test.dart';
import 'package:quickstart_wordlist_app/utils/filename.dart' as fn;

void main() {
  test('slugify trims and sanitizes', () {
    expect(fn.slugifyGloss('Hello World!'), 'hello.world');
    expect(fn.slugifyGloss('A B   C'), 'a.b.c');
    expect(fn.slugifyGloss('x' * 100), 'x' * 64);
  });

  test('generateAudioFilename pads and formats', () {
    expect(fn.generateAudioFilename('12', 'Body Parts'), '0012_body.parts.wav');
  });
}
