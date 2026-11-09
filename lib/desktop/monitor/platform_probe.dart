/// Raw machine readings for the load monitor: CPU time, memory, battery and,
/// where the battery reports it, real power draw.
///
/// Windows reads everything through kernel32/PowrProf, which is cheap enough
/// to call every second. macOS (developer harness only) shells out to `ps`,
/// `vm_stat` and `pmset`.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../../models_repo/desktop_memory.dart';

/// One reading. Times are cumulative; the sampler turns them into rates.
class ProbeReading {
  const ProbeReading({
    required this.at,
    this.systemBusy,
    this.systemTotal,
    this.appCpu,
    this.ramTotal,
    this.ramAvailable,
    required this.appRss,
    this.batteryPercent,
    this.onBattery,
    this.batteryWatts,
    this.systemCpuNow,
    this.appCpuNow,
  });

  final DateTime at;

  /// Cumulative busy and total CPU time across all cores, in 100 ns units
  /// (Windows). Null where the platform gives a percentage instead.
  final int? systemBusy;
  final int? systemTotal;

  /// Cumulative CPU time used by this process, 100 ns units (Windows).
  final int? appCpu;

  final int? ramTotal;
  final int? ramAvailable;
  final int appRss;
  final int? batteryPercent;
  final bool? onBattery;

  /// Power drawn from the battery in watts, when discharging and reported.
  final double? batteryWatts;

  /// Instant utilisation 0..1 where only a percentage is available (macOS).
  final double? systemCpuNow;
  final double? appCpuNow;
}

abstract final class PlatformProbe {
  static Future<ProbeReading> read() async {
    if (Platform.isWindows) return _Windows.read();
    if (Platform.isMacOS) return _Mac.read();
    return ProbeReading(at: DateTime.now(), appRss: ProcessInfo.currentRss);
  }
}

// ─── Windows ────────────────────────────────────────────────────────────────

final class _FileTime extends Struct {
  @Uint32()
  external int low;
  @Uint32()
  external int high;
}

final class _PowerStatus extends Struct {
  @Uint8()
  external int acLineStatus;
  @Uint8()
  external int batteryFlag;
  @Uint8()
  external int batteryLifePercent;
  @Uint8()
  external int systemStatusFlag;
  @Uint32()
  external int batteryLifeTime;
  @Uint32()
  external int batteryFullLifeTime;
}

// SYSTEM_BATTERY_STATE: 4 BOOLEANs, 3 spare bytes, a tag byte, then DWORDs.
final class _BatteryState extends Struct {
  @Uint8()
  external int acOnLine;
  @Uint8()
  external int batteryPresent;
  @Uint8()
  external int charging;
  @Uint8()
  external int discharging;
  @Uint8()
  external int spare1;
  @Uint8()
  external int spare2;
  @Uint8()
  external int spare3;
  @Uint8()
  external int tag;
  @Uint32()
  external int maxCapacity;
  @Uint32()
  external int remainingCapacity;
  @Int32()
  external int rate; // mW; negative while discharging
  @Uint32()
  external int estimatedTime;
  @Uint32()
  external int defaultAlert1;
  @Uint32()
  external int defaultAlert2;
}

typedef _GetSystemTimesC =
    Int32 Function(Pointer<_FileTime>, Pointer<_FileTime>, Pointer<_FileTime>);
typedef _GetSystemTimesD =
    int Function(Pointer<_FileTime>, Pointer<_FileTime>, Pointer<_FileTime>);
typedef _GetProcessTimesC =
    Int32 Function(
      IntPtr,
      Pointer<_FileTime>,
      Pointer<_FileTime>,
      Pointer<_FileTime>,
      Pointer<_FileTime>,
    );
typedef _GetProcessTimesD =
    int Function(
      int,
      Pointer<_FileTime>,
      Pointer<_FileTime>,
      Pointer<_FileTime>,
      Pointer<_FileTime>,
    );
typedef _GetCurrentProcessC = IntPtr Function();
typedef _GetCurrentProcessD = int Function();
typedef _GetPowerStatusC = Int32 Function(Pointer<_PowerStatus>);
typedef _GetPowerStatusD = int Function(Pointer<_PowerStatus>);
typedef _CallNtPowerC =
    Int32 Function(Int32, Pointer<Void>, Uint32, Pointer<Void>, Uint32);
typedef _CallNtPowerD =
    int Function(int, Pointer<Void>, int, Pointer<Void>, int);

abstract final class _Windows {
  static final _k32 = DynamicLibrary.open('kernel32.dll');
  static final _getSystemTimes = _k32
      .lookupFunction<_GetSystemTimesC, _GetSystemTimesD>('GetSystemTimes');
  static final _getProcessTimes = _k32
      .lookupFunction<_GetProcessTimesC, _GetProcessTimesD>('GetProcessTimes');
  static final _getCurrentProcess = _k32
      .lookupFunction<_GetCurrentProcessC, _GetCurrentProcessD>(
        'GetCurrentProcess',
      );
  static final _getPowerStatus = _k32
      .lookupFunction<_GetPowerStatusC, _GetPowerStatusD>(
        'GetSystemPowerStatus',
      );
  static _CallNtPowerD? _callNtPower;
  static bool _triedPowrProf = false;

  static int _ft(_FileTime t) => (t.high << 32) | t.low;

  static Future<ProbeReading> read() async {
    final idle = calloc<_FileTime>();
    final kernel = calloc<_FileTime>();
    final user = calloc<_FileTime>();
    final pCreate = calloc<_FileTime>();
    final pExit = calloc<_FileTime>();
    final pKernel = calloc<_FileTime>();
    final pUser = calloc<_FileTime>();
    final power = calloc<_PowerStatus>();
    final battery = calloc<_BatteryState>();
    try {
      int? busy, total, app;
      if (_getSystemTimes(idle, kernel, user) != 0) {
        // Kernel time includes idle time.
        total = _ft(kernel.ref) + _ft(user.ref);
        busy = total - _ft(idle.ref);
      }
      if (_getProcessTimes(
            _getCurrentProcess(),
            pCreate,
            pExit,
            pKernel,
            pUser,
          ) !=
          0) {
        app = _ft(pKernel.ref) + _ft(pUser.ref);
      }

      int? percent;
      bool? onBattery;
      if (_getPowerStatus(power) != 0) {
        final p = power.ref.batteryLifePercent;
        final hasBattery = (power.ref.batteryFlag & 128) == 0 && p <= 100;
        if (hasBattery) {
          percent = p;
          onBattery = power.ref.acLineStatus == 0;
        }
      }

      double? watts;
      final ntPower = _ntPower();
      if (ntPower != null && percent != null) {
        // 5 = SystemBatteryState.
        final status = ntPower(
          5,
          nullptr,
          0,
          battery.cast(),
          sizeOf<_BatteryState>(),
        );
        if (status == 0 &&
            battery.ref.discharging != 0 &&
            battery.ref.rate < 0) {
          watts = -battery.ref.rate / 1000.0;
        }
      }

      final memory = await readDesktopMemory();
      return ProbeReading(
        at: DateTime.now(),
        systemBusy: busy,
        systemTotal: total,
        appCpu: app,
        ramTotal: memory?.total,
        ramAvailable: memory?.available,
        appRss: ProcessInfo.currentRss,
        batteryPercent: percent,
        onBattery: onBattery,
        batteryWatts: watts,
      );
    } finally {
      for (final p in [idle, kernel, user, pCreate, pExit, pKernel, pUser]) {
        calloc.free(p);
      }
      calloc.free(power);
      calloc.free(battery);
    }
  }

  static _CallNtPowerD? _ntPower() {
    if (_triedPowrProf) return _callNtPower;
    _triedPowrProf = true;
    try {
      _callNtPower = DynamicLibrary.open(
        'PowrProf.dll',
      ).lookupFunction<_CallNtPowerC, _CallNtPowerD>('CallNtPowerInformation');
    } on Object {
      _callNtPower = null;
    }
    return _callNtPower;
  }
}

// ─── macOS (developer harness) ──────────────────────────────────────────────

abstract final class _Mac {
  static Future<ProbeReading> read() async {
    double? system;
    double? app;
    int? percent;
    bool? onBattery;
    try {
      final ps = await Process.run('ps', ['-A', '-o', '%cpu=']);
      final sum = '${ps.stdout}'
          .split('\n')
          .map((l) => double.tryParse(l.trim()) ?? 0)
          .fold<double>(0, (a, b) => a + b);
      system = (sum / 100 / Platform.numberOfProcessors).clamp(0.0, 1.0);
      final me = await Process.run('ps', ['-o', '%cpu=', '-p', '$pid']);
      app =
          ((double.tryParse('${me.stdout}'.trim()) ?? 0) /
                  100 /
                  Platform.numberOfProcessors)
              .clamp(0.0, 1.0);
      final batt = await Process.run('pmset', ['-g', 'batt']);
      final text = '${batt.stdout}';
      final m = RegExp(r'(\d+)%').firstMatch(text);
      if (m != null) {
        percent = int.parse(m.group(1)!);
        onBattery = text.contains('Battery Power');
      }
    } on Object {
      // Readings stay null; the monitor shows what it has.
    }
    final memory = await readDesktopMemory();
    return ProbeReading(
      at: DateTime.now(),
      ramTotal: memory?.total,
      ramAvailable: memory?.available,
      appRss: ProcessInfo.currentRss,
      batteryPercent: percent,
      onBattery: onBattery,
      systemCpuNow: system,
      appCpuNow: app,
    );
  }
}
