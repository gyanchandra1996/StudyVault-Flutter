import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileRepo {
  static const _key = 'user_local_profile_aarna_v1';

  static UserProfile? _cachedProfile;

  Future<UserProfile> getProfile() async {
    if (_cachedProfile != null) return _cachedProfile!;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _cachedProfile = UserProfile.fromMap(map);
        return _cachedProfile!;
      } catch (_) {}
    }
    // Return default profile
    _cachedProfile = UserProfile();
    return _cachedProfile!;
  }

  Future<bool> saveProfile(UserProfile profile) async {
    _cachedProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_key, jsonEncode(profile.toMap()));
  }

  void clearCache() {
    _cachedProfile = null;
  }
}
