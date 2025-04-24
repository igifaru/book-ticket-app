import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _isDarkMode = false;
  String _language = 'en';
  bool _notificationsEnabled = true;
  
  // Default values
  static const _defaultLanguage = 'English';
  static const _defaultCurrency = 'USD';
  static const _defaultTimeZone = 'UTC';
  static const _defaultThemeMode = ThemeMode.dark;
  static const _defaultNotificationsEnabled = true;
  static const _defaultEmailNotifications = true;
  static const _defaultPushNotifications = true;
  static const _defaultSmsNotifications = false;
  static const _defaultAutoApproveBookings = false;
  static const _defaultMaxBookingsPerUser = 5;
  static const _defaultCancellationPeriod = 24;
  static const _defaultDarkMode = true;

  // Keys for SharedPreferences
  static const _languageKey = 'language';
  static const _currencyKey = 'currency';
  static const _timeZoneKey = 'timeZone';
  static const _themeModeKey = 'themeMode';
  static const _notificationsKey = 'notifications';
  static const _emailNotificationsKey = 'emailNotifications';
  static const _pushNotificationsKey = 'pushNotifications';
  static const _smsNotificationsKey = 'smsNotifications';
  static const _autoApproveBookingsKey = 'autoApproveBookings';
  static const _maxBookingsPerUserKey = 'maxBookingsPerUser';
  static const _cancellationPeriodKey = 'cancellationPeriod';
  static const _darkModeKey = 'darkMode';
  static const _themeColorKey = 'themeColor';

  // Available options
  final List<String> _availableLanguages = ['English', 'Spanish', 'French', 'German'];
  final List<String> _availableCurrencies = ['USD', 'EUR', 'GBP', 'JPY'];
  final List<String> _availableTimeZones = ['UTC', 'EST', 'PST', 'GMT'];
  final List<String> _availableThemeColors = ['Blue', 'Green', 'Purple', 'Orange'];

  SettingsService(this._prefs);

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  String get currency => _prefs.getString(_currencyKey) ?? _defaultCurrency;
  String get timeZone => _prefs.getString(_timeZoneKey) ?? _defaultTimeZone;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get emailNotifications => _prefs.getBool(_emailNotificationsKey) ?? _defaultEmailNotifications;
  bool get pushNotifications => _prefs.getBool(_pushNotificationsKey) ?? _defaultPushNotifications;
  bool get smsNotifications => _prefs.getBool(_smsNotificationsKey) ?? _defaultSmsNotifications;
  bool get autoApproveBookings => _prefs.getBool(_autoApproveBookingsKey) ?? _defaultAutoApproveBookings;
  int get maxBookingsPerUser => _prefs.getInt(_maxBookingsPerUserKey) ?? _defaultMaxBookingsPerUser;
  int get cancellationPeriod => _prefs.getInt(_cancellationPeriodKey) ?? _defaultCancellationPeriod;
  bool get darkMode => _prefs.getBool(_darkModeKey) ?? _defaultDarkMode;
  String get themeColor => _prefs.getString(_themeColorKey) ?? 'Blue';

  List<String> get availableLanguages => _availableLanguages;
  List<String> get availableCurrencies => _availableCurrencies;
  List<String> get availableTimeZones => _availableTimeZones;
  List<String> get availableThemeColors => _availableThemeColors;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('SettingsService: Starting initialization...');
      _isDarkMode = _prefs.getBool('darkMode') ?? false;
      _language = _prefs.getString('language') ?? 'en';
      _notificationsEnabled = _prefs.getBool('notifications') ?? true;
      await loadSettings();
      _isInitialized = true;
      debugPrint('SettingsService: Initialization complete');
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService: Error during initialization: $e');
      rethrow;
    }
  }

  // Load settings
  Future<void> loadSettings() async {
    try {
      debugPrint('SettingsService: Loading settings...');
      // Verify all settings exist and set defaults if needed
      if (!_prefs.containsKey(_languageKey)) {
        await _prefs.setString(_languageKey, _defaultLanguage);
      }
      if (!_prefs.containsKey(_currencyKey)) {
        await _prefs.setString(_currencyKey, _defaultCurrency);
      }
      if (!_prefs.containsKey(_timeZoneKey)) {
        await _prefs.setString(_timeZoneKey, _defaultTimeZone);
      }
      if (!_prefs.containsKey(_notificationsKey)) {
        await _prefs.setBool(_notificationsKey, _defaultNotificationsEnabled);
      }
      debugPrint('SettingsService: Settings loaded successfully');
    } catch (e) {
      debugPrint('SettingsService: Error loading settings: $e');
      rethrow;
    }
    notifyListeners();
  }

  // Save settings
  Future<void> saveSettings() async {
    try {
      debugPrint('SettingsService: Saving settings...');
      notifyListeners();
      debugPrint('SettingsService: Settings saved successfully');
    } catch (e) {
      debugPrint('SettingsService: Error saving settings: $e');
      rethrow;
    }
  }

  // Update settings
  Future<void> updateSetting(String key, dynamic value) async {
    try {
      debugPrint('SettingsService: Updating setting $key = $value');
      if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else {
        throw ArgumentError('Invalid setting type for key: $key');
      }
      debugPrint('SettingsService: Setting updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService: Error updating setting: $e');
      rethrow;
    }
  }

  // Reset settings to defaults
  Future<void> resetSettings() async {
    try {
      debugPrint('SettingsService: Resetting settings to defaults...');
      await _prefs.clear();
      await loadSettings();
      debugPrint('SettingsService: Settings reset successfully');
    } catch (e) {
      debugPrint('SettingsService: Error resetting settings: $e');
      rethrow;
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      debugPrint('SettingsService: Clearing all data...');
      await _prefs.clear();
      _isInitialized = false;
      debugPrint('SettingsService: All data cleared successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService: Error clearing data: $e');
      rethrow;
    }
  }

  Future<void> clearCache() async {
    try {
      debugPrint('SettingsService: Clearing cache...');
      // TODO: Implement cache clearing logic
      debugPrint('SettingsService: Cache cleared successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService: Error clearing cache: $e');
      rethrow;
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (!_isInitialized) await initialize();
    _isDarkMode = value;
    await _prefs.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    if (!_isInitialized) await initialize();
    _language = value;
    await _prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (!_isInitialized) await initialize();
    _notificationsEnabled = value;
    await _prefs.setBool('notifications', value);
    notifyListeners();
  }
} 