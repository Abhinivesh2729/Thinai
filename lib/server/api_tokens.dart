import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A named bearer token a client uses to reach the API over LAN or a tunnel.
class ApiToken {
  final String id;
  final String name;
  final String token;
  final DateTime createdAt;

  const ApiToken({
    required this.id,
    required this.name,
    required this.token,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'token': token,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ApiToken.fromJson(Map<String, dynamic> json) => ApiToken(
    id: json['id'] as String,
    name: json['name'] as String,
    token: json['token'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

const _kTokensKey = 'server_api_tokens';

/// The single token earlier versions kept; migrated in as "Default".
const _kLegacyTokenKey = 'server_bearer_token';

/// 32 random bytes = 256 bits of entropy.
String newTokenSecret() {
  final random = Random.secure();
  return base64UrlEncode(List<int>.generate(32, (_) => random.nextInt(256)));
}

/// Named tokens persisted in SharedPreferences, oldest first.
class ApiTokenStore {
  Future<List<ApiToken>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTokensKey);
    if (raw != null) {
      return [
        for (final t in jsonDecode(raw) as List)
          ApiToken.fromJson(t as Map<String, dynamic>),
      ];
    }

    // Keep clients that already use the old single LAN token working.
    final legacy = prefs.getString(_kLegacyTokenKey);
    final tokens = [
      if (legacy != null && legacy.isNotEmpty)
        ApiToken(
          id: 'default',
          name: 'Default',
          token: legacy,
          createdAt: DateTime.now(),
        ),
    ];
    await _save(prefs, tokens);
    await prefs.remove(_kLegacyTokenKey);
    return tokens;
  }

  Future<ApiToken> create(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final tokens = await load();
    final token = ApiToken(
      id: const Uuid().v4(),
      name: name.trim().isEmpty ? 'Token ${tokens.length + 1}' : name.trim(),
      token: newTokenSecret(),
      createdAt: DateTime.now(),
    );
    await _save(prefs, [...tokens, token]);
    return token;
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final tokens = await load();
    await _save(prefs, [
      for (final t in tokens)
        if (t.id != id) t,
    ]);
  }

  Future<void> _save(SharedPreferences prefs, List<ApiToken> tokens) => prefs
      .setString(_kTokensKey, jsonEncode([for (final t in tokens) t.toJson()]));
}
