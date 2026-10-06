import 'dart:io';

void main(List<String> args) {
  final lcovPath = args.isNotEmpty ? args[0] : 'coverage/lcov.info';
  final lcovFile = File(lcovPath);

  if (!lcovFile.existsSync()) {
    stderr.writeln('ERROR: Coverage file not found at "$lcovPath".');
    stderr.writeln('Run `flutter test --coverage` first to generate it.');
    exit(1);
  }

  final lines = lcovFile.readAsLinesSync();

  var totalFound = 0;
  var totalHit = 0;
  var branchFound = 0;
  var branchHit = 0;

  String? currentFile;
  var fileFound = 0;
  var fileHit = 0;
  final fileMissedLines = <int>[];

  final fileStats = <String, ({int found, int hit, List<int> missedLines})>{};

  void recordFile() {
    if (currentFile != null && fileFound > 0) {
      fileStats[currentFile!] = (
        found: fileFound,
        hit: fileHit,
        missedLines: List.unmodifiable(fileMissedLines),
      );
      totalFound += fileFound;
      totalHit += fileHit;
    }
    currentFile = null;
    fileFound = 0;
    fileHit = 0;
    fileMissedLines.clear();
  }

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      recordFile();
      currentFile = line.substring(3).trim();
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        final lineNum = int.tryParse(parts[0]) ?? 0;
        final hitCount = int.tryParse(parts[1]) ?? 0;
        if (hitCount == 0 && lineNum > 0) {
          fileMissedLines.add(lineNum);
        }
      }
    } else if (line.startsWith('LF:')) {
      fileFound = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LH:')) {
      fileHit = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('BRF:')) {
      branchFound += int.tryParse(line.substring(4).trim()) ?? 0;
    } else if (line.startsWith('BRH:')) {
      branchHit += int.tryParse(line.substring(4).trim()) ?? 0;
    } else if (line == 'end_of_record') {
      recordFile();
    }
  }
  recordFile();

  if (totalFound == 0) {
    stderr.writeln('ERROR: No instrumented lines found in "$lcovPath".');
    exit(1);
  }

  final coveragePct = (totalHit / totalFound) * 100.0;
  final coverageStr = coveragePct.toStringAsFixed(2);

  if (branchFound > 0) {
    final branchPct = (branchHit / branchFound) * 100.0;
    stdout.writeln('Branch coverage: ${branchPct.toStringAsFixed(2)}% ($branchHit/$branchFound)');
  }

  if (totalHit == totalFound) {
    stdout.writeln('Coverage: 100.00%');
    stdout.writeln('PASS');
    exit(0);
  } else {
    stdout.writeln('Coverage: $coverageStr%');
    stdout.writeln('Required: 100%');
    stdout.writeln('FAIL: test coverage is below the required threshold.\n');

    final uncovered = fileStats.entries
        .where((e) => e.value.hit < e.value.found)
        .toList()
      ..sort((a, b) {
        final pctA = (a.value.hit / a.value.found);
        final pctB = (b.value.hit / b.value.found);
        return pctA.compareTo(pctB);
      });

    stdout.writeln('Uncovered source files (${uncovered.length} files missing 100% coverage):');
    stdout.writeln('--------------------------------------------------------------------------------');
    for (final entry in uncovered) {
      final f = entry.key;
      final st = entry.value;
      final pct = ((st.hit / st.found) * 100.0).toStringAsFixed(2);
      final missedCount = st.found - st.hit;
      final sampleMissed = st.missedLines.take(10).join(', ');
      final suffix = st.missedLines.length > 10 ? ', ...' : '';
      stdout.writeln('  ${pct.padLeft(6)}% ($missedCount missed of ${st.found} lines)  $f');
      if (sampleMissed.isNotEmpty) {
        stdout.writeln('          Missed lines: $sampleMissed$suffix');
      }
    }
    stdout.writeln('--------------------------------------------------------------------------------');
    exit(1);
  }
}
