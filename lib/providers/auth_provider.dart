import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth.dart';

class AuthProvider extends ChangeNotifier {
  AuthState _state = const AuthState();
  AuthState get state => _state;
  bool get loggedIn => _state.loggedIn;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('chanting_auth');
    if (s != null) {
      try {
        _state = AuthState.fromJson(jsonDecode(s));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> login({
    required String memberNo,
    required String memberName,
    required String groupName,
    required String inviteCode,
    String? groupCode,
    required String loginType,
  }) async {
    // 🔥 1. 先強制重置狀態，確保沒有上一個人的殘留資料
    _state = const AuthState();

    // 🔥 2. 計算正確的 groupCode (如果 groupCode 沒傳，就把 'G01' 變成 '01')
    String finalGroupCode = groupCode ?? '';
    if (finalGroupCode.isEmpty) {
      finalGroupCode = inviteCode.replaceAll(RegExp(r'[Gg]'), '');
    }
    if (finalGroupCode.isEmpty) {
      finalGroupCode = '21'; // 預設個人組
    }

    // 🔥 3. 寫入全新的登入狀態
    _state = AuthState(
      loggedIn: true,
      loginType: loginType,
      memberNo: memberNo,
      memberName: memberName,
      groupName: groupName,
      inviteCode: inviteCode,
      groupCode: finalGroupCode,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chanting_auth', jsonEncode(_state.toJson()));
    
    debugPrint('🔥 [AuthProvider] 登入成功！已重置狀態: $memberNo / 組別: $finalGroupCode');
    notifyListeners();
  }

  Future<void> logout() async {
    // 🔥 徹底清除狀態
    _state = const AuthState();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chanting_auth');
    
    debugPrint('🚪 [AuthProvider] 已登出並清除所有狀態');
    notifyListeners();
  }
}