import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/chat/document_attachment.dart';
import 'package:local_llm/chat/image_attachment.dart';

Uint8List textBytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('readDocument', () {
    test('reads a text file', () {
      final doc = readDocument('notes.txt', textBytes('hello world'));
      expect(doc.name, 'notes.txt');
      expect(doc.text, 'hello world');
      expect(doc.truncated, isFalse);
    });

    test('trims a document that would not fit the context window', () {
      final long = 'a' * (kDocumentCharBudget + 5000);
      final doc = readDocument('big.md', textBytes(long));
      expect(doc.text.length, kDocumentCharBudget);
      expect(doc.truncated, isTrue);
      expect(doc.originalLength, long.length);
    });

    test('names the format when it cannot read it', () {
      // The message has to say what to do instead, since "unsupported" leaves
      // the user with a file and no next step.
      expect(
        () => readDocument('report.pdf', textBytes('%PDF-1.7')),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('PDF'), contains('text')),
        )),
      );
      expect(
        () => readDocument('deck.pptx', textBytes('PK')),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => readDocument('photo.png', textBytes('x')),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a binary file wearing a text extension', () {
      final binary = Uint8List.fromList([72, 101, 0, 108, 108, 111]);
      expect(
        () => readDocument('sneaky.txt', binary),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('binary'),
        )),
      );
    });

    test('rejects empty and whitespace-only files', () {
      expect(() => readDocument('empty.txt', Uint8List(0)),
          throwsA(isA<FormatException>()));
      expect(() => readDocument('blank.txt', textBytes('   \n\n  ')),
          throwsA(isA<FormatException>()));
    });

    test('accepts an unfamiliar extension that is plainly text', () {
      // The extension list steers the picker; it does not get to veto a file
      // that decodes cleanly.
      final doc = readDocument('notes.rfc', textBytes('some text'));
      expect(doc.text, 'some text');
    });

    test('rejects text that is not UTF-8', () {
      final latin1 = Uint8List.fromList([0xFF, 0xFE, 0x41, 0x42]);
      expect(() => readDocument('odd.txt', latin1),
          throwsA(isA<FormatException>()));
    });
  });

  group('documentSystemMessage', () {
    test('fences the document and tells the model to stay inside it', () {
      final message = documentSystemMessage(
        readDocument('spec.md', textBytes('the content')),
      );
      expect(message, contains('spec.md'));
      // A fence with a random id the file cannot forge, rather than the old
      // `--- END DOCUMENT ---` line any file could contain.
      expect(message, contains('<<<DOCUMENT id='));
      expect(message, contains('the content'));
      expect(message, contains('<<<END DOCUMENT id='));
      expect(message.indexOf('the content'),
          lessThan(message.indexOf('<<<END DOCUMENT')));
      expect(message, contains('not instructions'));
    });

    test('warns the model when the document was cut short', () {
      // Otherwise it answers "not in the document" about a section that was
      // simply never sent.
      final message = documentSystemMessage(
        readDocument('big.txt', textBytes('a' * (kDocumentCharBudget + 100))),
      );
      expect(message, contains('truncated'));
    });
  });

  group('readImage', () {
    final png = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3]);

    test('builds the tag the native bridge scans for', () {
      final image = readImage('cat.png', png);
      expect(image.mimeType, 'image/png');
      expect(image.promptTag, startsWith('<img src="data:image/png;base64,'));
      expect(image.promptTag, endsWith('">'));
      expect(image.promptTag, contains(base64Encode(png)));
    });

    test('maps the extensions llama.cpp can decode', () {
      expect(mimeTypeForImage('a.jpg'), 'image/jpeg');
      expect(mimeTypeForImage('a.jpeg'), 'image/jpeg');
      expect(mimeTypeForImage('a.WEBP'), 'image/webp');
      expect(mimeTypeForImage('a.svg'), isNull);
      expect(mimeTypeForImage('noextension'), isNull);
    });

    test('rejects formats and sizes it cannot handle', () {
      expect(() => readImage('diagram.svg', png),
          throwsA(isA<FormatException>()));
      expect(() => readImage('empty.png', Uint8List(0)),
          throwsA(isA<FormatException>()));
      expect(
        () => readImage('huge.png', Uint8List(kMaxImageBytes + 1)),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('MB'),
        )),
      );
    });

    test('puts the picture ahead of the question', () {
      final image = readImage('cat.png', png);
      final prompt = promptWithImage(image, 'what is this?');
      expect(prompt.indexOf('<img'), lessThan(prompt.indexOf('what is this?')));
    });

    test('leaves the text alone when nothing is attached', () {
      expect(promptWithImage(null, 'plain question'), 'plain question');
    });

    test('an image with no question still forms a prompt', () {
      final prompt = promptWithImage(readImage('cat.png', png), '');
      expect(prompt, startsWith('<img'));
      expect(prompt.trim(), endsWith('">'));
    });
  });
}
