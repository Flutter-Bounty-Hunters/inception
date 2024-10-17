import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  static final UserSettings _instance = UserSettings._internal();

  factory UserSettings() {
    return _instance;
  }

  UserSettings._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _contentDirectoryKey = 'contentDirectory';

  /// The location the IDE should open as its workspace.
  ///
  /// Uses the CONTENT_DIRECTORY environment variable if it's set, otherwise
  /// checks for a stored value.
  String? get contentDirectory {
    const path = String.fromEnvironment("CONTENT_DIRECTORY");
    if (path.isNotEmpty) {
      return path;
    }
    return _prefs.getString(_contentDirectoryKey);
  }

  Future<void> setContentDirectory(String value) async {
    await _prefs.setString(_contentDirectoryKey, value);
  }
}
