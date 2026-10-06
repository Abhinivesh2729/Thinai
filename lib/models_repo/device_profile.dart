/// What this phone can actually run.
///
/// Read from `/proc/meminfo`, which Android exposes to every app, rather than
/// through a plugin: the two numbers that matter are already there and a
/// dependency for them would not earn its place.
library;

import 'dart:io';

/// Rough hardware class, used to estimate decode speed.
enum DeviceClass {
  /// Budget phone: slow memory, and the OOM killer arrives early.
  entry,

  /// Mid-range: the bulk of Android devices.
  mid,

  /// Flagship: fast LPDDR5-class memory and headroom to spare.
  flagship,

  /// Nothing could be measured — recommendations still work, but size and fit
  /// advice is generic.
  unknown,
}

class DeviceProfile {
  /// Physical RAM, or null when it could not be read.
  final int? totalRamBytes;

  /// RAM the kernel says is available right now, or null.
  final int? availableRamBytes;

  final int cores;

  const DeviceProfile({
    this.totalRamBytes,
    this.availableRamBytes,
    required this.cores,
  });

  static const unknownProfile = DeviceProfile(cores: 4);

  bool get known => totalRamBytes != null;

  DeviceClass get deviceClass {
    final total = totalRamBytes;
    if (total == null) return DeviceClass.unknown;
    final gb = total / (1024 * 1024 * 1024);
    if (gb >= 7.5 && cores >= 8) return DeviceClass.flagship;
    if (gb >= 5.5) return DeviceClass.mid;
    return DeviceClass.entry;
  }

  /// The most memory a model may need before this phone should be told no.
  ///
  /// Deliberately a share of *total* RAM rather than of what is free at this
  /// instant. llama.cpp mmaps the weights, so they are file-backed pages the
  /// kernel can drop and re-read under pressure — a model larger than
  /// `MemAvailable` still runs, just with more page faults. Gating on the
  /// live figure instead refuses most of the catalogue on an ordinary phone
  /// that happens to have its cache full, which is nearly always.
  ///
  /// 55% leaves the system and the foreground app their share while still
  /// allowing a 4B model on an 8 GB device.
  int? get modelBudgetBytes {
    final total = totalRamBytes;
    if (total == null) return null;
    return (total * 0.55).round();
  }

  /// What a model can occupy right now without forcing the kernel to reclaim.
  /// Above this a model still works but pays for it in page faults and evicted
  /// background apps — the difference between "runs well" and "tight".
  int? get comfortableBytes {
    final available = availableRamBytes;
    final budget = modelBudgetBytes;
    if (budget == null) return null;
    if (available == null) return (budget * 0.7).round();
    final byAvailable = (available * 0.8).round();
    return byAvailable < budget ? byAvailable : budget;
  }

  /// Memory bandwidth actually achieved by llama.cpp on this class of device,
  /// in GB/s. Decode of a quantised model is bandwidth-bound — every token
  /// reads the whole weight set — so this plus the file size is enough for a
  /// usable speed estimate.
  ///
  /// These are deliberately conservative: an estimate that reads low and is
  /// beaten is a better experience than one that promises 30 tok/s and
  /// delivers 8.
  double get effectiveBandwidthGBps => switch (deviceClass) {
        DeviceClass.flagship => 26,
        DeviceClass.mid => 12,
        DeviceClass.entry => 6,
        DeviceClass.unknown => 12,
      };

  String get summary {
    final total = totalRamBytes;
    if (total == null) return '$cores cores';
    final gb = total / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(gb >= 10 ? 0 : 1)} GB RAM · $cores cores';
  }

  /// Reads the current device's profile. Never throws: an unreadable
  /// `/proc/meminfo` (any non-Linux host, or a locked-down device) degrades to
  /// [unknownProfile] with the core count still filled in.
  static Future<DeviceProfile> read() async {
    final cores = Platform.numberOfProcessors;
    try {
      final file = File('/proc/meminfo');
      if (!await file.exists()) return DeviceProfile(cores: cores);
      return parseMemInfo(await file.readAsString(), cores: cores);
    } on Object {
      return DeviceProfile(cores: cores);
    }
  }
}

/// Parses the `/proc/meminfo` fields worth having. Values there are in kB.
///
/// `MemAvailable` is the one to trust over `MemFree`: the kernel's own
/// estimate of what a new allocation could get, cache reclaim included.
DeviceProfile parseMemInfo(String contents, {required int cores}) {
  int? total;
  int? available;
  for (final line in contents.split('\n')) {
    final match = RegExp(r'^(\w+):\s+(\d+)\s*kB').firstMatch(line.trim());
    if (match == null) continue;
    final bytes = int.parse(match.group(2)!) * 1024;
    switch (match.group(1)) {
      case 'MemTotal':
        total = bytes;
      case 'MemAvailable':
        available = bytes;
    }
  }
  return DeviceProfile(
    totalRamBytes: total,
    availableRamBytes: available,
    cores: cores,
  );
}
