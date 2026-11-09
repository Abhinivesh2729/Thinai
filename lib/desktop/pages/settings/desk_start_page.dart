/// The page the desktop app opens on.
///
/// Separate from the phone's `startPageProvider`: that one stores a tab index
/// (0 to 3, no Lab), and reusing the key would make index 2 mean Server on
/// one build and Lab on the other.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shell/desk_nav.dart';

class DeskStartPageController extends StateNotifier<DeskPage> {
  DeskStartPageController() : super(DeskPage.chat) {
    readSaved().then((page) {
      if (mounted) state = page;
    });
  }

  static const key = 'desk_start_page';

  /// For the shell at launch, which needs the value before this provider has
  /// finished its own load.
  static Future<DeskPage> readSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return DeskPage.values.asNameMap()[prefs.getString(key)] ?? DeskPage.chat;
  }

  Future<void> set(DeskPage page) async {
    state = page;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, page.name);
  }
}

final deskStartPageProvider =
    StateNotifierProvider<DeskStartPageController, DeskPage>(
      (ref) => DeskStartPageController(),
    );
