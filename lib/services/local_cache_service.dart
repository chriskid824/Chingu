import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  SharedPreferences? _prefs;

  factory LocalCacheService() {
    return _instance;
  }

  LocalCacheService._internal();

  /// Initialize the SharedPreferences instance
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if the service is initialized
  bool get isInitialized => _prefs != null;

  // Keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguageCode = 'language_code';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyLastLogin = 'last_login';
  static const String _keyUserId = 'user_id';

  // --- Generic Methods ---

  Future<bool> setString(String key, String value) async {
    if (_prefs == null) return false;
    return await _prefs!.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    if (_prefs == null) return false;
    return await _prefs!.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  Future<bool> setInt(String key, int value) async {
    if (_prefs == null) return false;
    return await _prefs!.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<bool> setDouble(String key, double value) async {
    if (_prefs == null) return false;
    return await _prefs!.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    if (_prefs == null) return false;
    return await _prefs!.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  Future<bool> remove(String key) async {
    if (_prefs == null) return false;
    return await _prefs!.remove(key);
  }

  Future<bool> clear() async {
    if (_prefs == null) return false;
    return await _prefs!.clear();
  }

  // --- User Preferences ---

  /// Save the user's preferred theme mode (e.g., 'light', 'dark', 'system')
  Future<bool> setThemeMode(String themeMode) async {
    return await setString(_keyThemeMode, themeMode);
  }

  /// Get the user's preferred theme mode
  String? getThemeMode() {
    return getString(_keyThemeMode);
  }

  /// Save the user's preferred language code (e.g., 'en', 'zh_TW')
  Future<bool> setLanguage(String languageCode) async {
    return await setString(_keyLanguageCode, languageCode);
  }

  /// Get the user's preferred language code
  String? getLanguage() {
    return getString(_keyLanguageCode);
  }

  // --- Common Data ---

  /// Set the onboarding completion status
  Future<bool> setOnboardingComplete(bool isComplete) async {
    return await setBool(_keyOnboardingComplete, isComplete);
  }

  /// Check if onboarding is complete
  bool isOnboardingComplete() {
    return getBool(_keyOnboardingComplete) ?? false;
  }

  /// Save the timestamp of the last login (in milliseconds since epoch)
  Future<bool> setLastLogin(int timestamp) async {
    return await setInt(_keyLastLogin, timestamp);
  }

  /// Get the timestamp of the last login
  int? getLastLogin() {
    return getInt(_keyLastLogin);
  }

  /// Save the user ID (useful for session persistence)
  Future<bool> setUserId(String userId) async {
    return await setString(_keyUserId, userId);
  }

  /// Get the stored user ID
  String? getUserId() {
    return getString(_keyUserId);
  }
}
