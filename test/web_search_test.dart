import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/web/web_search.dart';

/// A cut-down copy of what html.duckduckgo.com/html/ serves: redirect-wrapped
/// links, `<b>` inside titles, an advert with nothing behind it, and entities
/// throughout.
const _htmlPage = '''
<div class="results">
  <div class="result result--ad">
    <a rel="nofollow" class="result__a" href="//duckduckgo.com/y.js?ad_provider=x">Buy a phone</a>
    <a class="result__snippet">Sponsored listing.</a>
  </div>
  <div class="result">
    <a rel="nofollow" class="result__a"
       href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fwww.thehindu.com%2Fnews%2Ftamil&amp;rut=abc">
       Tamil Nadu <b>news</b> today
    </a>
    <a class="result__snippet">Chief Minister announced the scheme on <b>31 August</b> &amp; more.</a>
  </div>
  <div class="result">
    <a rel="nofollow" class="result__a" href="https://dinamalar.com/news">Dinamalar &#8212; latest</a>
    <a class="result__snippet">&#x0BA4;&#x0BAE;&#x0BBF;&#x0BB4; headlines.</a>
  </div>
</div>
''';

/// The Lite surface: a table, direct hrefs, and snippets in a `<td>`.
const _litePage = '''
<table>
<tr><td valign="top">1.&nbsp;</td><td>
  <a rel="nofollow" href="https://example.com/one" class='result-link'>First result</a>
</td></tr>
<tr><td>&nbsp;</td><td class='result-snippet'>The first summary.</td></tr>
<tr><td valign="top">2.&nbsp;</td><td>
  <a rel="nofollow" href="https://example.org/two" class='result-link'>Second result</a>
</td></tr>
<tr><td>&nbsp;</td><td class='result-snippet'>The second summary.</td></tr>
</table>
''';

WebSearchResults _results(List<WebResult> results, {String query = 'news'}) =>
    WebSearchResults(
      query: query,
      results: results,
      fetchedAt: DateTime(2026, 9, 2),
    );

void main() {
  group('searchQueryFrom', () {
    test('keeps a plain question as it was asked', () {
      expect(
        searchQueryFrom('who won the test match yesterday?'),
        'who won the test match yesterday?',
      );
    });

    test('drops the instruction to the app from the front', () {
      // Left in, the engine matches on "search the web" instead of the news.
      expect(searchQueryFrom("just search the web what's the news"),
          "what's the news");
      expect(searchQueryFrom('Search the web for tamil nadu rainfall'),
          'tamil nadu rainfall');
      expect(searchQueryFrom('google chennai metro timings'),
          'chennai metro timings');
    });

    test('drops it from the end too', () {
      expect(
        searchQueryFrom(
          '31 August 2026 , whats the news in tamil search the web give me '
          'results',
        ),
        '31 August 2026 , whats the news in tamil',
      );
      expect(
        searchQueryFrom('rupee to dollar rate, check online'),
        'rupee to dollar rate',
      );
    });

    test('falls back to the message when it was nothing but the instruction',
        () {
      expect(searchQueryFrom('search the web'), 'search the web');
    });

    test('collapses whitespace and caps a rambling message', () {
      expect(searchQueryFrom('  weather   in   erode  '), 'weather in erode');
      final long = 'a' * 400;
      expect(searchQueryFrom(long).length, lessThanOrEqualTo(240));
    });

    test('is empty only when there was nothing to search for', () {
      expect(searchQueryFrom('   '), isEmpty);
    });
  });

  group('searchQueryFrom, following on from an earlier question', () {
    test('carries the subject of the last question into a follow-up', () {
      // Live, "what is its price" on its own returned grammar guides to "its",
      // and "how old is he" returned the film Old.
      expect(
        searchQueryFrom('what is its price',
            previousUserTurns: ['latest iphone']),
        'iphone what is its price',
      );
      expect(
        searchQueryFrom('how old is he',
            previousUserTurns: ['who is the CEO of Nvidia']),
        'CEO Nvidia how old is he',
        reason: 'acronyms keep their case, which is how they are recognised',
      );
    });

    test('borrows from the most recent question only', () {
      expect(
        searchQueryFrom('how old is he', previousUserTurns: [
          'latest iphone',
          'who is the CEO of Nvidia',
        ]),
        'CEO Nvidia how old is he',
      );
    });

    test('leaves a new question alone, however short', () {
      // Five words, no pronoun, and a subject of its own: a new topic, not a
      // follow-up, and dragging "IPL match" into it would wreck the search.
      expect(
        searchQueryFrom('gold price in chennai today',
            previousUserTurns: ["who won yesterday's IPL match"]),
        'gold price in chennai today',
      );
    });

    test('does not repeat what the follow-up already says', () {
      expect(
        searchQueryFrom('is it cheaper than the iphone',
            previousUserTurns: ['latest iphone price']),
        'price is it cheaper than the iphone',
      );
    });

    test('strips the instruction from the earlier question too', () {
      expect(
        searchQueryFrom('what is its price',
            previousUserTurns: ['search the web for latest pixel phone']),
        'pixel phone what is its price',
      );
    });

    test('stays within the query cap', () {
      final rambling = List.generate(80, (i) => 'subject$i').join(' ');
      final query = searchQueryFrom('how much is it',
          previousUserTurns: [rambling]);
      expect(query.length, lessThanOrEqualTo(240));
      expect(query, endsWith('how much is it'),
          reason: 'the question itself is the part that must survive');
    });

    test('is unchanged with no earlier question', () {
      expect(searchQueryFrom('what is its price'), 'what is its price');
    });
  });

  group('parseDuckDuckGoHtml', () {
    test('reads results off the HTML surface', () {
      final results = parseDuckDuckGoHtml(_htmlPage);
      expect(results, hasLength(2));

      final first = results.first;
      // The redirect wrapper is unwrapped, so the model and the user both get
      // the real page rather than a duckduckgo.com link.
      expect(first.url, 'https://www.thehindu.com/news/tamil');
      expect(first.displayUrl, 'thehindu.com');
      expect(first.title, 'Tamil Nadu news today');
      expect(first.snippet, contains('31 August'));
      expect(first.snippet, contains('&'));
      expect(first.snippet, isNot(contains('<b>')));

      expect(results[1].title, 'Dinamalar — latest');
      expect(results[1].snippet, startsWith('தமிழ'));
    });

    test('drops adverts, which carry no destination', () {
      final results = parseDuckDuckGoHtml(_htmlPage);
      expect(results.map((r) => r.url), isNot(contains(contains('y.js'))));
      expect(results.map((r) => r.title), isNot(contains('Buy a phone')));
    });

    test('reads results off the Lite surface', () {
      final results = parseDuckDuckGoHtml(_litePage);
      expect(results, hasLength(2));
      expect(results[0].url, 'https://example.com/one');
      expect(results[0].title, 'First result');
      expect(results[0].snippet, 'The first summary.');
      expect(results[1].url, 'https://example.org/two');
      expect(results[1].snippet, 'The second summary.');
    });

    test('does not let a missing snippet steal the next result\'s', () {
      const page = '''
        <a class="result__a" href="https://a.example/1">A</a>
        <a class="result__a" href="https://b.example/2">B</a>
        <a class="result__snippet">Belongs to B.</a>
      ''';
      final results = parseDuckDuckGoHtml(page);
      expect(results[0].snippet, isEmpty);
      expect(results[1].snippet, 'Belongs to B.');
    });

    test('keeps one entry per destination', () {
      const page = '''
        <a class="result__a" href="https://a.example/1">A</a>
        <a class="result__a" href="https://a.example/1">A again</a>
      ''';
      expect(parseDuckDuckGoHtml(page), hasLength(1));
    });

    test('only unwraps redirects that really are DuckDuckGo\'s', () {
      const page = '''
        <a class="result__a" href="https://notduckduckgo.com/l/?uddg=https%3A%2F%2Fevil.example%2F">Spoof</a>
        <a class="result__a" href="https://duckduckgo.com.evil.example/l/?uddg=https%3A%2F%2Fevil.example%2F">Spoof 2</a>
        <a class="result__a" href="https://html.duckduckgo.com/l/?uddg=https%3A%2F%2Freal.example%2F">Real</a>
      ''';
      final urls = parseDuckDuckGoHtml(page).map((r) => r.url).toList();
      expect(urls, contains('https://real.example/'));
      // The lookalikes are ordinary links to themselves, not unwrapped to the
      // destination they name.
      expect(urls, isNot(contains('https://evil.example/')));
    });

    test('survives a page it cannot make sense of', () {
      expect(parseDuckDuckGoHtml(''), isEmpty);
      expect(parseDuckDuckGoHtml('<html><body>blocked</body></html>'), isEmpty);
    });
  });

  group('needsWebSearch', () {
    test('looks up what only the world knows', () {
      for (final question in [
        'latest anthropic model',
        'whats the news in tamil',
        'gold rate today',
        'who won the match',
        'weather in erode tomorrow',
        'recently released antropic model abd it usage',
        'chennai metro timings',
        'best phone under 20000 in 2026',
      ]) {
        expect(needsWebSearch(question), isTrue, reason: question);
      }
    });

    test('leaves the model to do its own work', () {
      for (final question in [
        'write a poem about rain',
        'translate this to tamil: good morning',
        'explain the code I sent',
        'solve 12 x 34',
        'summarize the document',
        'hi',
      ]) {
        expect(needsWebSearch(question), isFalse, reason: question);
      }
    });

    test('an explicit ask beats the guess, in both directions', () {
      // "search the web" carries none of the usual signals, and is the
      // clearest instruction there is.
      expect(searchQueryFrom('search the web for pasta recipes'), isNotEmpty);
      expect(needsWebSearch('search the web for pasta recipes'), isTrue);
      expect(needsWebSearch('google it'), isTrue);
      expect(
        needsWebSearch('what is the news today, without searching the web'),
        isFalse,
      );
    });
  });

  group('webSearchPrompt', () {
    final results = _results(const [
      WebResult(
        title: 'Tamil Nadu news today',
        url: 'https://www.thehindu.com/news/tamil',
        snippet: 'Rain warning issued for six districts.',
      ),
      WebResult(
        title: 'Dinamalar',
        url: 'https://dinamalar.com/news',
        snippet: 'Headlines.',
      ),
    ], query: 'whats the news in tamil');

    test('dates the results and numbers them for citation', () {
      final prompt = webSearchPrompt(results, 'whats the news in tamil');
      expect(prompt, contains('2 September 2026'));
      expect(prompt, contains('[1] Tamil Nadu news today'));
      expect(prompt, contains('thehindu.com'));
      expect(prompt, contains('[2] Dinamalar'));
    });

    test('ends with the question, after telling the model what to do', () {
      // The order is the fix for a 0.5B model answering "[1] Anthropic Models
      // — 25 Releases": given a block of headlines and nothing after it, a
      // small model continues the list instead of using it.
      final prompt = webSearchPrompt(results, 'what happened today?');
      expect(prompt.trimRight(), endsWith('Question: what happened today?'));
      expect(prompt.indexOf('[1] Tamil Nadu'),
          lessThan(prompt.indexOf('Question:')));
      expect(prompt, contains('your own words'));
      expect(prompt.toLowerCase(), contains('do not copy a headline'));
    });

    test('the system line stops the "I cannot browse" reflex', () {
      expect(kWebSearchSystemLine.toLowerCase(), contains('cannot access'));
    });

    test('trims a long snippet rather than the result', () {
      final prompt = webSearchPrompt(
        _results([
          WebResult(
            title: 'Long',
            url: 'https://example.com',
            snippet: 'x' * 900,
          ),
        ]),
        'q',
      );
      expect(prompt, contains('…'));
      expect(prompt, isNot(contains('x' * 700)));
    });

    test('spends no more than the budget, but always carries one result', () {
      final many = _results([
        for (var i = 0; i < 5; i++)
          WebResult(
            title: 'Result $i',
            url: 'https://example.com/$i',
            snippet: 'y' * 300,
          ),
      ]);
      final context = webSearchContext(many, charBudget: 700);
      expect(context, contains('[1] Result 0'));
      expect(context, isNot(contains('[3] Result 2')));

      final oversized = _results([
        WebResult(
          title: 'Only',
          url: 'https://example.com/only',
          snippet: 'z' * 300,
        ),
      ]);
      expect(
        webSearchContext(oversized, charBudget: 10),
        contains('[1] Only'),
      );
    });
  });

  group('parseHeadingResults', () {
    test('reads results whichever way round the heading and link sit', () {
      const page = '''
        <li class="b_algo">
          <h2><a href="https://benchlm.ai/anthropic">Ranked by benchmark</a></h2>
          <p class="b_lineclamp3">Claude Fable 5.1 leads with a score of 83.</p>
        </li>
        <li class="b_algo">
          <a href="https://www.anthropic.com/news/fable"><h2>Introducing <strong>Fable</strong> 5.1</h2></a>
          <div class="b_caption"><p>Up to 45 percent cheaper for agentic work.</p></div>
        </li>
      ''';
      final results = parseHeadingResults(page);
      expect(results, hasLength(2));
      expect(results[0].url, 'https://benchlm.ai/anthropic');
      expect(results[0].snippet, contains('score of 83'));
      // The second is the inside-out shape, which is what Bing serves.
      expect(results[1].url, 'https://www.anthropic.com/news/fable');
      expect(results[1].title, 'Introducing Fable 5.1');
      expect(results[1].snippet, contains('45 percent cheaper'));
    });

    test('unwraps a click tracker back to the page behind it', () {
      // Bing base64s the destination into `u`, behind an "a1" marker.
      const page = '<h2><a href="https://www.bing.com/ck/a?!&amp;&amp;p=1&amp;'
          'u=a1aHR0cHM6Ly9leGFtcGxlLmNvbS9zdG9yeQ&amp;ntb=1">Story</a></h2>';
      final results = parseHeadingResults(page);
      expect(results.single.url, 'https://example.com/story');
    });

    test('drops the engine talking about itself', () {
      const page = '''
        <h2><a href="https://www.bing.com/images/search?q=x">Images</a></h2>
        <h2><a href="https://go.microsoft.com/fwlink/?linkid=1">Privacy</a></h2>
        <h2><a href="https://example.com/real">A real result</a></h2>
      ''';
      final results = parseHeadingResults(page);
      expect(results.single.url, 'https://example.com/real');
    });

    test('an unclosed paragraph earlier on does not swallow the first snippet',
        () {
      // Bing's mobile page has a stray `<p` above the results; the lazy match
      // started there and ran through the first result's `</p>`, so result [1]
      // always arrived with no snippet.
      const page = '''
        <div id="b_header"><p class="b_hide">Menu
        <ol id="b_results"><li class="b_algo">
          <div class="b_algoheader"><a href="https://ceodelhi.gov.in/"><h2>Chief Electoral Officer</h2></a></div>
          <div class="b_caption"><p class="b_lineclamp3">Electors are requested to search their names.</p></div>
        </li></ol>
      ''';
      final results = parseHeadingResults(page);
      expect(results.single.snippet, 'Electors are requested to search their names.');
    });

    test('survives a page with no results on it', () {
      expect(parseHeadingResults(''), isEmpty);
      expect(parseHeadingResults('<h2>No link here</h2>'), isEmpty);
    });
  });

  group('keepRelevant', () {
    test('drops a result ranked on a word the question did not mean', () {
      // What a fallback engine actually returned for a cricket question.
      const results = [
        WebResult(
          title: 'South Korean won - Wikipedia',
          url: 'https://en.wikipedia.org/wiki/South_Korean_won',
          snippet: 'The South Korean won is the currency of South Korea.',
        ),
        WebResult(
          title: 'India vs Australia, 3rd ODI highlights',
          url: 'https://espncricinfo.com/match',
          snippet: 'India beat Australia by seven wickets.',
        ),
      ];
      final kept = keepRelevant(results, 'who won the last india vs australia match');
      expect(kept, hasLength(1));
      expect(kept.single.url, 'https://espncricinfo.com/match');
    });

    test('a search that matched nothing is empty, not wrong', () {
      // "WhatsApp Web" for "whats the news in tamil nadu": a real page about
      // nothing that was asked. An empty result says so honestly; feeding it
      // to the model produces a confident wrong answer instead.
      const results = [
        WebResult(
          title: 'WhatsApp Web',
          url: 'https://web.whatsapp.com',
          snippet: 'Send and receive messages without keeping your phone.',
        ),
      ];
      expect(keepRelevant(results, 'whats the news in tamil nadu today'),
          isEmpty);
    });

    test('keeps everything when the question is all common words', () {
      const results = [
        WebResult(title: 'Anything', url: 'https://example.com'),
      ];
      expect(keepRelevant(results, 'what is it now'), hasLength(1));
    });

    test('matches on the words that carry the question', () {
      expect(queryTerms('whats the news in tamil nadu today'),
          ['news', 'tamil', 'nadu']);
      expect(queryTerms('gold rate today in chennai'),
          ['gold', 'rate', 'chennai']);
    });

    test('keeps acronyms, which are short but the most specific word', () {
      expect(queryTerms("who won yesterday's IPL match"), ['ipl', 'match']);
      expect(queryTerms('who is the CEO of Nvidia'), ['ceo', 'nvidia']);
      // A lower-case three-letter word is still just a word.
      expect(queryTerms('who won the cup'), isEmpty);
    });

    test('reads Tamil words whole, vowel signs and all', () {
      // Split on "not a letter", the vowel signs cut every word into
      // fragments too short to count, and the question had no terms at all.
      expect(queryTerms('இன்றைய சென்னை வானிலை'), ['சென்னை', 'வானிலை']);
    });

    test('puts the result that matches the most of the question first', () {
      const results = [
        WebResult(
          title: 'Gold rate news',
          url: 'https://a.example',
          snippet: 'The price moved again today.',
        ),
        WebResult(
          title: 'Gold price in Chennai today',
          url: 'https://b.example',
          snippet: '22K gold is ₹14,170 per gram.',
        ),
        WebResult(
          title: 'Today in Chennai',
          url: 'https://c.example',
          snippet: 'Gold and silver prices across the city.',
        ),
      ];
      final kept = keepRelevant(results, 'gold price in chennai');
      // All three terms in the title beats the same terms in a snippet, which
      // beats two of them.
      expect(kept.map((r) => r.url),
          ['https://b.example', 'https://c.example', 'https://a.example']);
    });

    test('with three or more terms, half of them must be there', () {
      const results = [
        WebResult(
          title: 'Next Official Site: Online Fashion',
          url: 'https://next.example',
          snippet: 'Next day delivery.',
        ),
        WebResult(
          title: 'ISRO launch schedule',
          url: 'https://isro.example',
          snippet: 'The next launch is PSLV-C62.',
        ),
      ];
      expect(
        keepRelevant(results, 'when is the next ISRO launch')
            .map((r) => r.url),
        ['https://isro.example'],
      );
    });

    test('with two terms, one is enough unless another result has both', () {
      // A synonym is not a miss: "headlines" answers "news".
      const synonym = [
        WebResult(
          title: 'Dinamalar',
          url: 'https://dinamalar.example',
          snippet: 'Tamil headlines.',
        ),
      ];
      expect(keepRelevant(synonym, 'tamil news'), hasLength(1));

      // But beside a result that names both, the one that names only
      // "weather" is the Ulhasnagar forecast read out as Erode's.
      const results = [
        WebResult(
          title: 'Ulhasnagar, Maharashtra Weather Forecast',
          url: 'https://msn.example',
          snippet: 'Hourly forecasts for today and tomorrow.',
        ),
        WebResult(
          title: 'Erode Weather Forecast',
          url: 'https://erode.example',
          snippet: '32°C and cloudy.',
        ),
      ];
      expect(
        keepRelevant(results, 'weather in erode tomorrow').map((r) => r.url),
        ['https://erode.example'],
      );
    });

    test('matches a word from its start, not from its middle', () {
      const results = [
        WebResult(title: 'A separate matter', url: 'https://x.example'),
        WebResult(title: 'Gold prices', url: 'https://y.example'),
        WebResult(title: 'Repo rate cut', url: 'https://z.example'),
      ];
      // "rate" inside "separate" is not the word.
      expect(keepRelevant(results, 'rate today').map((r) => r.url),
          ['https://z.example']);
      // "price" at the start of "prices" is.
      expect(keepRelevant(results, 'price today').map((r) => r.url),
          ['https://y.example']);
    });
  });

  group('extractReadableText', () {
    test('keeps the prose and drops the furniture', () {
      const page = '''
        <html><head><style>.a{color:red}</style><title>T</title></head>
        <body>
          <nav><a href="/">Home</a><a href="/about">About</a></nav>
          <script>window.tracker = 1;</script>
          <h1>Anthropic releases Claude Fable 5.1</h1>
          <p>Claude Fable 5.1 scores 83 on the leaderboard, ahead of Opus 5 at
             82.4, the company said on Tuesday.</p>
          <li>Menu</li>
          <footer><p>Copyright</p></footer>
        </body></html>
      ''';
      final text = extractReadableText(page);
      expect(text, contains('Claude Fable 5.1 scores 83'));
      // A headline is worth having; a nav link and a tracker are not.
      expect(text, contains('Anthropic releases Claude Fable 5.1'));
      expect(text, isNot(contains('window.tracker')));
      expect(text, isNot(contains('color:red')));
      expect(text, isNot(contains('Menu')));
    });

    test('given the question, keeps the paragraphs that answer it', () {
      // Live, the Android page led with "You're all set to receive the latest
      // tips" and the iPhone page with pre-order banners; the answer was
      // further down and fell outside the budget.
      final page = '''
        <p>You're all set to receive the latest tips, news and offers from Android.</p>
        <p>${'Sign up for our newsletter and never miss a single update again. ' * 6}</p>
        <h2>What is the latest Android version?</h2>
        <p>Android 17 is the latest version, released to Pixel phones in June 2026.</p>
        <p>${'Cookie settings and privacy choices for this website are below. ' * 6}</p>
      ''';
      final text = extractReadableText(page, limit: 260,
          query: 'latest android version');
      expect(text, contains('Android 17 is the latest version'));
      expect(text, isNot(contains('newsletter')));
      // Names "Android" and nothing else of the question, beside paragraphs
      // that name two of its words: page chrome, not an answer.
      expect(text, isNot(contains('all set')));
      // In the order the page has them, so the heading still reads first.
      expect(text.indexOf('What is the latest Android'),
          lessThan(text.indexOf('Android 17 is')));

      // Without a question, the page is read from the top as before.
      expect(extractReadableText(page, limit: 260), contains('all set'));
    });

    test('spends no more than its budget', () {
      final page = '<p>${'word ' * 2000}</p>';
      final text = extractReadableText(page, limit: 300);
      expect(text.length, lessThanOrEqualTo(301));
      expect(text, endsWith('…'));
    });

    test('falls back to the whole page when there are no paragraphs', () {
      final text = extractReadableText(
        '<div>Claude Fable 5.1 leads the leaderboard with a score of 83.</div>',
      );
      expect(text, contains('score of 83'));
    });

    test('survives what is not a page at all', () {
      expect(extractReadableText(''), isEmpty);
      expect(extractReadableText('<html><body></body></html>'), isEmpty);
    });

    test('does not mistake a page\'s plumbing for its prose', () {
      // A megabyte of YouTube cut at the size cap leaves a script tag that
      // never closes, and its contents used to arrive as "prose".
      const truncated = '<html><body><div>Watch</div><script>'
          'window.ytplayer={};ytcfg.set({"CLIENT_CANARY_STATE":"none",'
          '"DEVICE":"ceng=U",'; // no closing tag: the page was cut here
      final text = extractReadableText(truncated);
      expect(text, isNot(contains('ytcfg')));
      expect(text, isNot(contains('CLIENT_CANARY_STATE')));
    });

    test('skips the sites whose pages are an app shell', () {
      // Fetching these buys a megabyte of nothing, so they are never read.
      expect(isReadablePage('https://www.youtube.com/watch?v=x'), isFalse);
      expect(isReadablePage('https://m.facebook.com/story'), isFalse);
      expect(isReadablePage('https://www.thehindu.com/news/tamil'), isTrue);
    });
  });

  group('page text in the prompt', () {
    test('what the top page says goes in beside the snippets', () {
      final results = WebSearchResults(
        query: 'latest anthropic model',
        results: const [
          WebResult(
            title: 'Best Anthropic Models',
            url: 'https://benchlm.ai/anthropic',
            snippet: 'Ranked by benchmark data.',
          ),
        ],
        fetchedAt: DateTime(2026, 9, 2),
        leadText: 'Claude Fable 5.1 leads with a score of 83.',
      );
      final prompt = webSearchPrompt(results, 'latest anthropic model');
      // The snippet says results were ranked; only the page says by what.
      expect(prompt, contains('From [1] benchlm.ai:'));
      expect(prompt, contains('score of 83'));
    });
  });

  group('webRecallPrompt', () {
    const sources = [
      WebResult(
        title: 'Best Anthropic Models',
        url: 'https://benchlm.ai/anthropic',
        snippet: 'Top picks: Claude Mythos 5, Claude Fable 5.',
      ),
      WebResult(
        title: 'Models overview',
        url: 'https://platform.claude.com/docs/models',
      ),
    ];

    test('puts the earlier results back behind a follow-up', () {
      // "what is the model name" after a searched answer used to reach a model
      // that could no longer see the search, and it refused outright.
      final prompt = webRecallPrompt(sources, 'what is the model name');
      expect(prompt, contains('earlier in this conversation'));
      expect(prompt, contains('Claude Fable 5'));
      expect(prompt.trimRight(), endsWith('Question: what is the model name'));
      expect(prompt, contains('rather than refusing'));
    });

    test('keeps only the few worth carrying', () {
      final many = [
        for (var i = 0; i < 5; i++)
          WebResult(title: 'Result $i', url: 'https://example.com/$i'),
      ];
      final prompt = webRecallPrompt(many, 'and then?');
      expect(prompt, contains('[1] Result 0'));
      expect(prompt, isNot(contains('Result 4')));
    });

    test('is just the question when there is nothing to recall', () {
      expect(webRecallPrompt(const [], 'hello'), 'hello');
    });
  });

  group('decodeHtmlEntities', () {
    test('reads the named entities pages actually use', () {
      // A gold-rate page arrived in the prompt as "99.9&percnt; purity".
      expect(decodeHtmlEntities('99.9&percnt; purity'), '99.9% purity');
      expect(decodeHtmlEntities('&copy; 2026 &middot; 30&deg;C'),
          '© 2026 · 30°C');
      expect(decodeHtmlEntities('&unknownthing;'), '&unknownthing;');
    });

    test('undoes double escaping in a snippet, and only there', () {
      const page = '''
        <h2><a href="https://example.com/gold">Gold rate</a></h2>
        <p>24 karat gold (99.9&amp;percnt; purity) is ₹15,458 per gram.</p>
      ''';
      expect(parseHeadingResults(page).single.snippet,
          contains('99.9% purity'));
      // Escaped once, "&percnt;" in the markup is already "%"; nothing to redo.
      expect(decodeHtmlEntities('AT&amp;T'), 'AT&T');
    });
  });

  group('keywordQuery', () {
    test('strips the question down to what an engine matches on', () {
      // Live, Bing answered "who is the CEO of Nvidia" with Delhi's Chief
      // Electoral Officer, and "Nvidia CEO" with Jensen Huang.
      expect(keywordQuery('who is the CEO of Nvidia?'), 'CEO Nvidia');
      expect(keywordQuery('when is the next ISRO launch'), 'next ISRO launch');
      // "won" alone got South Korean currency; "yesterday's IPL match" got
      // song lyrics; "IPL match yesterday" got the scorecards.
      expect(keywordQuery("who won yesterday's IPL match"),
          'IPL match yesterday');
      expect(keywordQuery('who won the IPL final'), 'IPL final');
    });

    test('drops Tamil filler that derails the engine the same way', () {
      expect(keywordQuery('இன்றைய சென்னை வானிலை'), 'சென்னை வானிலை');
    });

    test('has a second phrasing for when the first ranks on the wrong word',
        () {
      // Each pair is what was measured live against Bing: the first phrasing
      // missed, the second found it.
      expect(retryKeywordQuery('CEO Nvidia'), 'Nvidia CEO');
      expect(retryKeywordQuery('next ISRO launch'), 'ISRO next launch');
      expect(retryKeywordQuery('latest gemma model release google'),
          'gemma model release google latest');
      // One word has no other order.
      expect(retryKeywordQuery('bitcoin'), isNull);
    });

    test('keeps the query when there is nothing but filler', () {
      expect(keywordQuery('what is it'), 'what is it');
      expect(keywordQuery('gold price in chennai today'),
          'gold price chennai today');
    });
  });

  group('WebResult', () {
    test('round-trips through the conversation history', () {
      const source = WebResult(
        title: 'Tamil Nadu news today',
        url: 'https://www.thehindu.com/news/tamil',
        snippet: 'Rain warning issued for six districts.',
      );
      final restored = WebResult.fromJson(source.toJson())!;
      expect(restored.title, source.title);
      expect(restored.url, source.url);
      // Kept, so the source list still says what the page was about when the
      // chat is reopened next week.
      expect(restored.snippet, source.snippet);
    });

    test('stores a shortened snippet, not a whole page', () {
      final long = WebResult(
        title: 'Long',
        url: 'https://example.com',
        snippet: 'w' * 900,
      );
      final stored = long.toJson()['snippet'] as String;
      expect(stored.length,
          lessThanOrEqualTo(WebResult.storedSnippetLength + 1));
      expect(stored, endsWith('…'));
    });

    test('keeps the query it was found by, and reads old entries without one',
        () {
      const source = WebResult(
        title: 'iPhone 18 Pro price in India',
        url: 'https://example.com/iphone',
      );
      final searched = source.withQuery('iphone what is its price');
      final restored = WebResult.fromJson(searched.toJson())!;
      expect(restored.query, 'iphone what is its price');
      expect(restored.url, source.url);

      // Saved before queries were kept: no key, and nothing shown for it.
      expect(source.toJson().containsKey('query'), isFalse);
      expect(WebResult.fromJson(source.toJson())!.query, isEmpty);
    });

    test('refuses a stored entry with nothing to open', () {
      expect(WebResult.fromJson({'title': 'No link'}), isNull);
      expect(WebResult.fromJson('not a map'), isNull);
    });
  });
}
