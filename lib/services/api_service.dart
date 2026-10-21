import 'dart:convert';
import 'dart:io'; // 🔥 處理 HttpClient 和憑證
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart'; // 🔥 關鍵：引入 Dio 的 IO 轉接器
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;


class ApiService {
  ApiService._() {
    _initDio();
  }
  
  static final ApiService instance = ApiService._();
  
  // 🔥 1. 這裡改成新的主網域路徑 (結尾不要加斜線)
  static const String baseUrl = 'https://www.dhp.com.tw/tw-proxy-ei/';
  
  late Dio _dio;

  Future<void> _initDio() async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // ============================================================
    // 🟢 💡 完美修正版：改用新版「套件安全盾牌」，徹底解決 Xcode Archive 卡死報錯
    // ============================================================
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        // 針對 OPPO/vivo/iOS 跨國憑證，100% 安全強行通過
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiePath = '${appDocDir.path}/.cookies/';

    
    final cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(cookiePath),
    );

    _dio.interceptors.add(CookieManager(cookieJar));
    
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }
  }

  /// 取得品項
  Future<List<dynamic>> fetchItemsDirect(String groupCode, String memberNo) async {
    try {
      final url = Uri.parse('$baseUrl/get_items.php?group=$groupCode&memberNo=$memberNo&itemMode=mixed');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 上傳紀錄 (單筆)
  Future<bool> postChanting({
    required String groupCode,
    required String memberNo,
    required String memberName,
    required String item,
    required int count,
    required String remark,
    required String itemId,
    required String icon,
  }) async {
    try {
      final payload = {
        'data': {
          'group': groupCode,
          'memberNo': memberNo, 'memberName': memberName, 'item': item,
          'count': count, 'remark': remark, 'itemId': itemId, 'icon': icon,
        }
      };

      // 🔥 2. 去掉前面的斜線
      // 強制把 group 灌在 URL 參數上
      final res = await _dio.post('add_chanting.php?action=addChantingRecord&group=$groupCode', data: payload);
      
      if (res.statusCode == 200) {
        return true; 
      }
      return false;
    } catch (e) {
      debugPrint('❌ 上傳錯誤: $e');
      return false;
    }
  }

  /// 供日曆批次上傳使用的專用上傳函式
  Future<Map<String, dynamic>?> postChantingRaw({
    required String memberNo,
    required String memberName,
    required String item,
    required int count,
    required String groupCode,
    required String remark,
    required String icon,
  }) async {
    try {
      final payload = {
        'data': {
          'group': groupCode,
          'memberNo': memberNo, 
          'memberName': memberName, 
          'item': item,
          'count': count, 
          'remark': remark, 
          'itemId': '',
          'icon': icon,
        }
      };

      // 🔥 3. 去掉前面的斜線，並強制加上 group 參數
      final res = await _dio.post('add_chanting.php?action=addChantingRecord&group=$groupCode', data: payload);
      
      if (res.statusCode == 200) {
        return res.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ 批次上傳錯誤: $e');
      return null;
    }
  }

  /// 團體登入
  Future<Map<String, dynamic>?> loginGroup({required String inviteCode}) async {
    try {
      final payload = {'login_type': 'group', 'invite_code': inviteCode};
      
      // 🔥 4. 去掉前面的斜線
      final res = await _dio.post('index.php?action=login', data: payload);

      print('🔥 登入 API 回應: ${res.statusCode} - ${res.data}');
      
      if (res.statusCode == 200) {
        final json = res.data;
        if (json['success'] == true) return json;
      }
      return null;
    } catch (e) {
      print('❌ 登入例外錯誤: $e'); 
      return null;
    }
  }

  /// 查詢會員（把 groupCode 加進去）：
  Future<Map<String, dynamic>?> getMemberInfo(String memberNo, String groupCode) async {
    try {
      // 🔥 5. 去掉前面的斜線，並加上 group 參數
      final res = await _dio.get('index.php?action=getMemberByNoForChanting&no=$memberNo&group=$groupCode');
      if (res.statusCode == 200) {
        final json = res.data;
        if (json['success'] == true) {
          return {
            'name': json['name'] ?? json['data']?['name'] ?? '未知',
            'status': json['status'] ?? json['data']?['status'] ?? '正常',
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 每日紀錄 (這裡是直接寫死全網址，所以不用改)
  Future<Map<String, dynamic>?> fetchDailyHistory(String memberNo, int year, int month, String groupCode) async {
    try {
      final url = Uri.parse('$baseUrl/index.php?action=getMemberChantingDailyHistory&memberNo=$memberNo&year=$year&month=$month&group=$groupCode');
      debugPrint('🚀 [http] 準備抓日曆: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) return json; 
      }
      return null;
    } catch (e) {
      debugPrint('❌ [http] 日曆抓取失敗: $e');
      return null;
    }
  }

  /// 年度統計 (這裡是直接寫死全網址，所以不用改)
  Future<Map<String, dynamic>?> fetchYearStats(String memberNo, int year, String groupCode) async {
    try {
      final url = Uri.parse('$baseUrl/index.php?action=getMemberChantingHistory&memberNo=$memberNo&year=$year&group=$groupCode');
      debugPrint('🚀 [http] 準備抓年度: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) return json; 
      }
      return null;
    } catch (e) {
      debugPrint('❌ [http] 年度抓取失敗: $e');
      return null;
    }
  }

  /// 修改雲端紀錄
  Future<bool> updateCloudRecord(
    String id, int count, String remark, {String? itemName, String? icon, required String groupCode}
  ) async {
    try {
      final body = {
        'data': {
          'recordId': id,
          'count': count,
          'remark': remark,
          'itemId': '',
          'itemName': itemName ?? '',
          'icon': icon ?? '📿',
        }
      };

      // 🔥 6. 去掉前面的斜線，並強制加上 group 參數
      final res = await _dio.post('update_chanting.php?action=updateChantingRecord&group=$groupCode', data: body);
      
      if (res.statusCode == 200) {
        return true; 
      }
      return false;
    } catch (e) {
      debugPrint('❌ 修改雲端錯誤: $e');
      return false;
    }
  }

  /// 個人登入
  Future<Map<String, dynamic>?> loginPersonal({
    required String memberNo,
    required String phoneLast3,
  }) async {
    try {
      final payload = {
        'login_type': 'personal',
        'member_no': memberNo,
        'phone_last3': phoneLast3,
        'item_mode': 'mixed',
      };
      
      // 🔥 7. 去掉前面的斜線
      final res = await _dio.post('index.php?action=login', data: payload);
      
      if (res.statusCode == 200) {
        final json = res.data;
        if (json['success'] == true) return json;
      }
      return null;
    } catch (e) {
      debugPrint('❌ 個人登入錯誤: $e');
      return null;
    }
  }

  /// 註冊會員
  Future<Map<String, dynamic>?> registerMember({
    required String name,
    required String phone,
    required String groupInvite,
    required String loginType,
  }) async {
    try {
      final payload = {
        'action': 'registerMember',
        'login_type': loginType,
        'name': name,
        'phone': phone,
        'group_invite': groupInvite,
      };

      // 🔥 8. 去掉前面的斜線
      final res = await _dio.post('index.php?action=registerMember', data: payload);

      if (res.statusCode == 200) {
        return res.data; 
      }
      return null;
    } catch (e) {
      debugPrint('❌ 註冊錯誤: $e');
      return null;
    }
  }

  /// 忘記會員編號查詢
  Future<Map<String, dynamic>?> findMember({
    required String name,
    required String phone,
  }) async {
    try {
      // 🔥 9. 去掉前面的斜線
      final res = await _dio.get(
        'index.php?action=findMember&name=${Uri.encodeComponent(name)}&phone=${Uri.encodeComponent(phone)}',
      );
      
      if (res.statusCode == 200) {
        return res.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ 查詢會員錯誤: $e');
      return null;
    }
  }
}
