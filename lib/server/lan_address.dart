import 'dart:io';

/// The device's primary LAN IPv4 address, or null when not on a network
/// (or only loopback is available).
///
/// Prefers a private-range address (the Wi-Fi/hotspot the phone is actually
/// on) so the URL shown to the user is the one other devices can reach.
Future<String?> lanIpv4() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
      includeLoopback: false,
    );
    String? fallback;
    for (final ni in interfaces) {
      for (final addr in ni.addresses) {
        if (addr.isLoopback) continue;
        final ip = addr.address;
        if (_isPrivate(ip)) return ip;
        fallback ??= ip;
      }
    }
    return fallback;
  } catch (_) {
    return null;
  }
}

bool _isPrivate(String ip) {
  if (ip.startsWith('192.168.') || ip.startsWith('10.')) return true;
  if (ip.startsWith('172.')) {
    final parts = ip.split('.');
    if (parts.length < 2) return false;
    final second = int.tryParse(parts[1]) ?? -1;
    return second >= 16 && second <= 31;
  }
  return false;
}
