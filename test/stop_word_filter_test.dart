import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/llm/llm_engine.dart';

/// Feeds a filter the way llama.cpp feeds the engine: cumulative text, one
/// callback per token. Returns the concatenated deltas.
String streamThrough(StopWordFilter filter, List<String> tokens) {
  final out = StringBuffer();
  var cumulative = '';
  for (var i = 0; i < tokens.length; i++) {
    cumulative += tokens[i];
    out.write(filter.consume(cumulative, done: i == tokens.length - 1));
    if (filter.hit) break;
  }
  return out.toString();
}

void main() {
  group('StopWordFilter', () {
    test('passes everything through when there are no stop words', () {
      final filter = StopWordFilter(const []);
      expect(streamThrough(filter, ['Hello', ', ', 'world']), 'Hello, world');
      expect(filter.hit, isFalse);
    });

    test('cuts at the stop word and never emits it', () {
      final filter = StopWordFilter(['END']);
      expect(streamThrough(filter, ['one two ', 'END', ' three']), 'one two ');
      expect(filter.hit, isTrue);
      expect(filter.visible, 'one two ');
    });

    test('catches a stop word split across tokens', () {
      // The case the hold-back exists for: "EN" alone looks like ordinary
      // text, and emitting it would put half a stop word on the wire.
      final filter = StopWordFilter(['END']);
      expect(streamThrough(filter, ['abc', 'EN', 'D', 'more']), 'abc');
      expect(filter.hit, isTrue);
    });

    test('holds back only as much as the longest stop word needs', () {
      final filter = StopWordFilter(['END']);
      // "abcde" with a 3-char stop word: 2 characters stay held back.
      filter.consume('abcde', done: false);
      expect(filter.visible, 'abc');
    });

    test('releases the held-back tail when generation ends', () {
      final filter = StopWordFilter(['END']);
      expect(streamThrough(filter, ['abcd', 'ef']), 'abcdef');
      expect(filter.hit, isFalse);
    });

    test('takes the earliest match when several stop words are set', () {
      final filter = StopWordFilter(['STOP', 'END']);
      expect(streamThrough(filter, ['a END b STOP c']), 'a ');
    });

    test('sizes the hold-back to the longest stop word', () {
      final filter = StopWordFilter(['X', 'LONGSTOP']);
      expect(streamThrough(filter, ['hello ', 'LONGST', 'OP tail']), 'hello ');
      expect(filter.hit, isTrue);
    });

    test('emits nothing more once a stop word has been hit', () {
      final filter = StopWordFilter(['END']);
      filter.consume('done END', done: false);
      expect(filter.consume('done END and more', done: true), '');
      expect(filter.visible, 'done ');
    });

    test('never splits a surrogate pair across two deltas', () {
      // A lone surrogate on either side of the cut is not valid JSON, which
      // would break the SSE frame carrying it. The hold-back boundary lands
      // between the halves of this emoji unless it is nudged off.
      final filter = StopWordFilter(['END']);
      const emoji = '\u{1F600}'; // two UTF-16 code units
      final deltas = <String>[];
      var cumulative = '';
      const tokens = ['a', emoji, 'b', 'c'];
      for (var i = 0; i < tokens.length; i++) {
        cumulative += tokens[i];
        deltas.add(filter.consume(cumulative, done: i == tokens.length - 1));
      }

      for (final delta in deltas) {
        if (delta.isEmpty) continue;
        final last = delta.codeUnitAt(delta.length - 1);
        expect(last >= 0xD800 && last <= 0xDBFF, isFalse,
            reason: 'delta "$delta" ends on a high surrogate');
        final first = delta.codeUnitAt(0);
        expect(first >= 0xDC00 && first <= 0xDFFF, isFalse,
            reason: 'delta "$delta" starts on a low surrogate');
      }
      expect(deltas.join(), 'a${emoji}bc');
    });

    test('handles a stop word that is the entire output', () {
      final filter = StopWordFilter(['END']);
      expect(streamThrough(filter, ['END']), '');
      expect(filter.hit, isTrue);
      expect(filter.visible, isEmpty);
    });

    test('ignores empty stop strings, which would match everywhere', () {
      final filter = StopWordFilter(['']);
      expect(streamThrough(filter, ['abc', 'def']), 'abcdef');
      expect(filter.hit, isFalse);
    });
  });
}
