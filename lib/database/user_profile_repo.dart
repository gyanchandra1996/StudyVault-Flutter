import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileRepo {
  static const _key = 'user_local_profile_aarna_v1';
  static const _registeredKey = 'user_is_registered_v1';

  static UserProfile? _cachedProfile;

  Future<UserProfile> getProfile() async {
    if (_cachedProfile != null) return _cachedProfile!;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    final isReg = prefs.getBool(_registeredKey) ?? false;

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final profile = UserProfile.fromMap(map);
        _cachedProfile = isReg ? profile.copyWith(isRegistered: true) : profile;
        return _cachedProfile!;
      } catch (_) {}
    }
    // Return default profile
    _cachedProfile = UserProfile(isRegistered: isReg);
    return _cachedProfile!;
  }

  Future<bool> saveProfile(UserProfile profile) async {
    _cachedProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_registeredKey, profile.isRegistered);
    return await prefs.setString(_key, jsonEncode(profile.toMap()));
  }

  Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_registeredKey) ?? false;
  }

  void clearCache() {
    _cachedProfile = null;
  }
}
