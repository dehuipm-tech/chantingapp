import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'cloud_calendar_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isUploading = false;
  bool _isLoggingIn = false;
  bool _isRegistering = false;

  // ================= 上傳表單 =================
  final _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _countCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  // ================= 登入/註冊表單 =================
  int _authTab = 0; // 0=登入 1=加入團體
  
  final _loginInviteCtrl = TextEditingController();
  final _loginMemberNoCtrl = TextEditingController();
  
  final _groupRegInviteCtrl = TextEditingController();
  final _groupRegNameCtrl = TextEditingController();
  final _groupRegCodeCtrl = TextEditingController();

  // ================= 品項資料 =================
  List<dynamic> _activeItems = [];
  String? _selectedItemName;
  String? _selectedItemId;
  String? _selectedItemIcon;
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.loggedIn) {
        _loadItems(auth);
      }
    });
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _countCtrl.dispose();
    _remarkCtrl.dispose();
    _loginInviteCtrl.dispose();
    _loginMemberNoCtrl.dispose();
    _groupRegInviteCtrl.dispose();
    _groupRegNameCtrl.dispose();
    _groupRegCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loggedIn && _activeItems.isEmpty && !_isLoadingItems) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadItems(auth);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F5), // 🔥 極淺的米白色背景
      appBar: AppBar(
        title: Text(auth.loggedIn ? '⚙️ 設定' : '⚙️ 設定與登入'),
        backgroundColor: const Color(0xFF5A3A7A), // 配合截圖的深紫色
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: auth.loggedIn ? _buildLoggedInView(auth) : _buildLoginView(auth),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF4E8),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: Colors.orange.shade400, width: 5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ℹ️ 本 App 個人與團體皆適用', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7B3F00))),
          SizedBox(height: 8),
          Text('☁️ 雲端同步：提供個人查詢團體共修功課紀錄，如念佛、拜佛等。', style: TextStyle(fontSize: 13, color: Color(0xFF4A2E1A), height: 1.5)),
          SizedBox(height: 4),
          Text('🔒 隱私保護：健康數據與個人隱私資訊，皆僅儲存於您的本機裝置，絕對不會被上傳或分享。', style: TextStyle(fontSize: 13, color: Color(0xFF4A2E1A), height: 1.5)),
        ],
      ),
    );
  }

  // ============================================================
  // 未登入畫面
  // ============================================================
  Widget _buildLoginView(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      physics: const AlwaysScrollableScrollPhysics(), // 加上這個確保滑動順暢
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSoft),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildAuthTab(0, '🏷️ 團體登入'),
                _buildAuthTab(1, '🏛️ 加入團體'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_authTab == 0) _buildLoginForm(),
          if (_authTab == 1) _buildGroupRegisterForm(),

          const SizedBox(height: 24),
          
          const Center(
            child: Text(
              '📩 想建立專屬共修群組，請來信申請邀請碼\namtbw@icloud.com',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF8B7355), height: 1.5),
            ),
          ),

          const SizedBox(height: 20),
          const Center(
            child: Text('© 昇鍀英商行 | 聯絡：amtbw@icloud.com', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          ),
          
        ],
      ),
    );
  }

  Widget _buildAuthTab(int index, String text) {
    final isActive = _authTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _authTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF5A3A7A) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Colors.black38),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // 🔥 把這裡的 border 顏色改為極淡的灰色，不要用主色
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      // 只有聚焦時才顯示深紫色
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF5A3A7A), width: 2)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('🏷️ 邀請碼 / 群組代碼', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A3A7A), fontSize: 15)),
        const SizedBox(height: 6),
        TextField(
          controller: _loginInviteCtrl,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          decoration: inputDecoration.copyWith(hintText: '請輸入群組代碼（例：G01）'),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 16),

        const Text('🔢 會員編號', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A3A7A), fontSize: 15)),
        const SizedBox(height: 6),
        TextField(
          controller: _loginMemberNoCtrl,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          decoration: inputDecoration.copyWith(hintText: '請輸入您的會員編號（例：01101）'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 6),
        const Text('💡 登入後系統會記住您的編號，上傳時不需再輸入。', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _isLoggingIn ? null : () => _doLogin(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5A3A7A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: _isLoggingIn
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('🔑 登入', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        
        Center(
          child: TextButton(
            onPressed: _showForgotInviteDialog,
            child: const Text('🔐 忘記邀請碼？', style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupRegisterForm() {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Colors.black38),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: AppColors.borderSoft)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: AppColors.borderSoft)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF5A3A7A), width: 2)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('🏷️ 邀請碼 ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A3A7A))),
            Text('*', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _groupRegInviteCtrl,
          style: const TextStyle(color: Colors.black87),
          decoration: inputDecoration.copyWith(hintText: '請輸入您要加入的群組代碼'),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 6),
        const Text('💡 請向群組負責人索取邀請碼', style: TextStyle(fontSize: 12, color: Color(0xFF8B7355))),
        const SizedBox(height: 16),

        Row(
          children: [
            const Text('👤 姓名 ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A3A7A))),
            Text('*', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _groupRegNameCtrl,
          style: const TextStyle(color: Colors.black87),
          decoration: inputDecoration.copyWith(hintText: '請輸入姓名'),
        ),
        const SizedBox(height: 6),
        const Text('💡 請填寫您方便稱呼的名字即可', style: TextStyle(fontSize: 12, color: Color(0xFF8B7355))),
        const SizedBox(height: 16),

        Row(
          children: [
            const Text('🔑 登入碼 ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A3A7A))),
            Text('*', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _groupRegCodeCtrl,
          style: const TextStyle(color: Colors.black87),
          decoration: inputDecoration.copyWith(hintText: '請輸入登入碼（最多10個字）'),
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 10,
        ),
        const SizedBox(height: 4),
        const Text('💡 作為登入識別使用，請妥善保存', style: TextStyle(fontSize: 12, color: Color(0xFF8B7355))),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _isRegistering ? null : () => _doGroupRegister(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5A3A7A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: _isRegistering
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('🏛️ 加入團體', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Future<void> _doLogin() async {
    final invite = _loginInviteCtrl.text.trim().toUpperCase();
    final memberNo = _loginMemberNoCtrl.text.trim();

    if (invite.isEmpty) { _showErrorDialog('輸入錯誤', '請輸入群組代碼'); return; }
    if (memberNo.isEmpty) { _showErrorDialog('輸入錯誤', '請輸入會員編號'); return; }

    setState(() => _isLoggingIn = true);
    final auth = context.read<AuthProvider>();

    // 1. 驗證邀請碼 (取得組別資訊)
    final loginData = await ApiService.instance.loginGroup(inviteCode: invite);

    if (loginData == null || loginData['success'] != true) {
      if (mounted) setState(() => _isLoggingIn = false);
      _showErrorDialog('登入失敗', '請確認群組代碼是否正確，或聯繫您的組長。');
      return;
    }

    final groupName = loginData['group_name'] ?? '未知群組';
    final serverGroupCode = loginData['group_code']?.toString() ?? invite;
    
    // 2. 查詢會員資訊
    // 請確保你在這個檔案裡有拿到 groupCode 這個變數
    final memberInfo = await ApiService.instance.getMemberInfo(memberNo, serverGroupCode);
    
    // 🔥 如果抓不到資料，代表沒有這個會員
    if (memberInfo == null) {
      if (mounted) setState(() => _isLoggingIn = false);
      _showErrorDialog('驗證失敗', '查無此會員編號「$memberNo」。\n請確認是否已加入群組，或向組長確認編號是否正確。');
      return;
    }

    // 🔥 3. 判斷會員狀態是否停用
    if (memberInfo['status'] == '停用') {
      if (mounted) setState(() => _isLoggingIn = false);
      _showErrorDialog('會員已停用', '該會員已被停用，無法進行誦經登記。', isLocked: true);
      return; // 中斷登入流程
    }

    // 4. 驗證通過且未停用
    await auth.login(
      memberNo: memberNo, 
      memberName: memberInfo['name'],
      groupName: groupName,
      inviteCode: invite,
      groupCode: serverGroupCode,
      loginType: 'group',
    );
    
    // 🔥 改為呼叫成功彈窗
    _showSuccessDialog(memberInfo['name'], groupName, memberNo);
    
    if (mounted) _loadItems(auth);
    if (mounted) setState(() => _isLoggingIn = false);
  }

  // ============================================================
  // 🔥 共用的錯誤彈窗 (完美復刻您的截圖)
  // ============================================================
  void _showErrorDialog(String title, String message, {bool isLocked = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 鎖頭圖示 (如果停用就顯示鎖頭，一般錯誤顯示警示)
            Text(isLocked ? '🔒' : '⚠️', style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            
            // 標題
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC62828), // 深紅色
              ),
            ),
            const SizedBox(height: 20),
            
            // 內容提示框 (淺米色底)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF9F5), // 極淺米色
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 24),
            
            // 按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828), // 紅色按鈕
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('我知道了', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 驗證成功彈窗 (復刻截圖樣式)
  // ============================================================
  void _showSuccessDialog(String name, String groupName, String memberNo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, // 移除 Material 3 預設的色調
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 大綠色打勾圖示
              const Text('✅', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              
              // 標題
              const Text(
                '驗證成功',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E7D32), // 深綠色
                ),
              ),
              const SizedBox(height: 24),
              
              // 淺色資訊框
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB), // 截圖中的淺米黃色
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text('會員驗證成功！', style: TextStyle(fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Text('姓名：$name', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text('組別：$groupName', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // 確認按鈕 (橘色)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD68C45), // 截圖中的橘色
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: const Text('我知道了', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doGroupRegister() async {
    final invite = _groupRegInviteCtrl.text.trim().toUpperCase();
    final name = _groupRegNameCtrl.text.trim();
    final code = _groupRegCodeCtrl.text.trim();

    if (invite.isEmpty) { _showSnack('⚠️ 請輸入邀請碼'); return; }
    if (name.isEmpty) { _showSnack('⚠️ 請輸入姓名'); return; }
    if (code.length < 3 || code.length > 10 || int.tryParse(code) == null) { _showSnack('⚠️ 登入碼需為 3~10 位數字'); return; }

    setState(() => _isRegistering = true);

    final data = await ApiService.instance.registerMember(
      name: name,
      phone: code,
      groupInvite: invite,
      loginType: 'group',
    );

    if (data != null && data['success'] == true) {
      _showRegisterSuccessDialog(
        name: name,
        groupName: data['group_name'] ?? '',
        memberNo: data['memberNo'] ?? '',
        loginCode: code,
      );
    } else {
      _showSnack('❌ ${data?['message'] ?? '加入失敗'}');
    }
    if (mounted) setState(() => _isRegistering = false);
  }

  void _showRegisterSuccessDialog({required String name, required String groupName, required String memberNo, required String loginCode}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 28), SizedBox(width: 8), Text('加入成功', style: TextStyle(fontWeight: FontWeight.bold))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSuccessRow('👤 姓名', name),
            _buildSuccessRow('🏷️ 群組', groupName),
            _buildSuccessRow('🔢 會員編號', memberNo),
            _buildSuccessRow('🔑 登入碼', loginCode),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFEF4E8), borderRadius: BorderRadius.circular(8)),
              child: const Text('💡 請記下會員編號和登入碼，用於日後登入', style: TextStyle(fontSize: 12, color: Color(0xFF7B3F00))),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); setState(() => _authTab = 0); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A3A7A), foregroundColor: Colors.white),
            child: const Text('前往登入'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showForgotInviteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔐', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 12),
            const Text('忘記邀請碼？', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD68C45))),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF5F0EB), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 ', style: TextStyle(fontSize: 18)),
                  Expanded(child: Text('請向您所屬的組長索取團體邀請碼。', style: TextStyle(fontSize: 15, height: 1.4, color: Colors.black87))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD68C45), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('我知道了', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 已登入畫面 (復刻截圖樣式)
  // ============================================================
  Widget _buildLoggedInView(AuthProvider auth) {
    return SingleChildScrollView(
      // 🔥 修改這裡：加入 bottom: 100，保留底部給導覽列的空間
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💜 會員卡片 (深紫漸層)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B4B8B), Color(0xFF4A2A6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF4A2A6A).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.state.memberName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text('🏷️ ${auth.state.groupName} · ${auth.state.memberNo}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout, color: Colors.white70, size: 24),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 📤 標題與表單 (完全復刻截圖)
          _buildManualUploadForm(auth),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 自訂輸入框裝飾 (深紫色圓角)
  InputDecoration _buildPurpleInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
      filled: true,
      fillColor: const Color(0xFF5A3A7A), // 深紫色底
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildManualUploadForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📅 日期
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF5A3A7A), size: 20),
            const SizedBox(width: 8),
            Text('日期', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5A3A7A).withOpacity(0.8))),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _dateCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: _buildPurpleInputDecoration('2026-10-19'),
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.done, // 👈 鍵盤顯示完成
          onSubmitted: (_) => FocusScope.of(context).unfocus(), // 👈 點擊完成時收鍵盤
        ),
        
        const SizedBox(height: 24),
        
        // 📿 品項
        Row(
          children: [
            const Icon(Icons.spa_outlined, color: Color(0xFF5A3A7A), size: 20),
            const SizedBox(width: 8),
            Text('請選擇共修品項', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5A3A7A).withOpacity(0.8))),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingItems)
          const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator()))
        else if (_activeItems.isEmpty)
          const Text('⚠️ 目前無啟用的品項', style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _activeItems.map((item) {
              final name = item['name']?.toString() ?? '未命名';
              final icon = item['icon']?.toString() ?? '📿';
              final isSelected = _selectedItemName == name;
              
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedItemName = name;
                  _selectedItemId = item['id']?.toString() ?? '';
                  _selectedItemIcon = icon;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF5A3A7A) : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF5A3A7A) : const Color(0xFFE1D4F0), 
                      width: 1.5
                    ),
                    boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF5A3A7A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                  ),
                  child: Text(
                    '$icon $name',
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF5A3A7A),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        
        const SizedBox(height: 24),

        // 🔢 數量
        Row(
          children: [
            const Icon(Icons.tag, color: Color(0xFF5A3A7A), size: 20),
            const SizedBox(width: 8),
            Text('數量', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5A3A7A).withOpacity(0.8))),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _countCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: _buildPurpleInputDecoration('請輸入數量'),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done, // 👈 鍵盤顯示完成
          onSubmitted: (_) => FocusScope.of(context).unfocus(), // 👈 點擊完成時收鍵盤
        ),
        
        const SizedBox(height: 24),

        // 📝 備註
        Row(
          children: [
            const Icon(Icons.notes, color: Color(0xFF5A3A7A), size: 20),
            const SizedBox(width: 8),
            Text('備註 (選填)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5A3A7A).withOpacity(0.8))),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _remarkCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: _buildPurpleInputDecoration('輸入備註...'),
          textInputAction: TextInputAction.done, // 👈 鍵盤顯示完成
          onSubmitted: (_) => FocusScope.of(context).unfocus(), // 👈 點擊完成時收鍵盤
        ),
        
        const SizedBox(height: 32),

        // 📤 上傳按鈕
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : () {
              FocusScope.of(context).unfocus(); // 👈 點擊上傳時，強制收起鍵盤
              _uploadManualData(auth);
            },
            icon: _isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF5A3A7A), strokeWidth: 2))
                : const Icon(Icons.cloud_upload, size: 24, color: Color(0xFF5A3A7A)),
            label: Text(_isUploading ? '上傳中...' : '確認上傳', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5A3A7A))),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD1C4E9), // 截圖中的淺紫色
              foregroundColor: const Color(0xFF5A3A7A),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ),
        
        const SizedBox(height: 16),

        // ☁️ 查看雲端
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CloudCalendarScreen()));
            },
            icon: const Icon(Icons.cloud_outlined, color: Color(0xFF5A3A7A), size: 24),
            label: const Text('查看雲端共修紀錄', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A3A7A))),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: const BorderSide(color: Color(0xFFE8DDD0), width: 1.5),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadItems(AuthProvider auth) async {
    if (_isLoadingItems) return;
    setState(() => _isLoadingItems = true);

    try {
      String groupCode = auth.state.groupCode.isNotEmpty ? auth.state.groupCode : auth.state.inviteCode;
      if (groupCode.isEmpty) groupCode = 'G01';

      final items = await ApiService.instance.fetchItemsDirect(groupCode, auth.state.memberNo);

      if (mounted) setState(() => _activeItems = items);
    } catch (e) {
      debugPrint('❌ 抓取品項失敗: $e');
    } finally {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _uploadManualData(AuthProvider auth) async {
    final dateStr = _dateCtrl.text.trim();
    final count = int.tryParse(_countCtrl.text) ?? 0;
    final remark = _remarkCtrl.text.trim();

    if (_selectedItemName == null) { _showSnack('⚠️ 請先選擇一個品項'); return; }
    if (count <= 0) { _showSnack('⚠️ 請輸入正確的數量'); return; }

    setState(() => _isUploading = true);
    String groupCode = auth.state.groupCode.isNotEmpty ? auth.state.groupCode : '01';

    final ok = await ApiService.instance.postChanting(
      groupCode: groupCode,
      memberNo: auth.state.memberNo,
      memberName: auth.state.memberName,
      item: _selectedItemName!,
      count: count,
      remark: remark.isEmpty ? '手動輸入 ($dateStr)' : remark,
      itemId: _selectedItemId ?? '',
      icon: _selectedItemIcon ?? '📿',
    );

    if (mounted) {
      if (ok) {
        // 🔥 上傳成功！清空表單欄位
        _countCtrl.clear();
        _remarkCtrl.clear();
        
        final successItem = _selectedItemName!;
        final successIcon = _selectedItemIcon ?? '📿';
        
        setState(() {
          _selectedItemName = null;
          _selectedItemId = null;
          _selectedItemIcon = null;
        });

        // 🔥 呼叫成功彈窗 (把 remark 傳進去)
        _showUploadSuccessDialog(successIcon, successItem, count, remark); // 👈 這裡加上 remark
        
      } else {
        _showSnack('❌ 上傳失敗，請確認網路連線');
      }
      setState(() => _isUploading = false);
    }
  }

    // ============================================================
  // 🔥 上傳成功彈窗 (解決溢出問題 + 補上備註)
  // ============================================================
  void _showUploadSuccessDialog(String icon, String itemName, int count, String remark) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        // 🔥 解決溢出：加入 SingleChildScrollView，這樣就算橫拿手機也能滑動
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20), // 稍微縮小邊距
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 稍微縮小圖示，節省高度
                const Text('✅', style: TextStyle(fontSize: 54)),
                const SizedBox(height: 12),
                
                const Text(
                  '誦經記錄新增成功！',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                
                // 明細清單
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📿 ', style: TextStyle(fontSize: 18)),
                          const Text('品項：', style: TextStyle(fontSize: 15, color: Colors.black87)),
                          Expanded(
                            child: Text('$icon $itemName', style: TextStyle(fontSize: 15, color: Colors.black87)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔢 ', style: TextStyle(fontSize: 18)),
                          const Text('遍數：', style: TextStyle(fontSize: 15, color: Colors.black87)),
                          Expanded(
                            child: Text('$count', style: TextStyle(fontSize: 15, color: Colors.black87)),
                          ),
                        ],
                      ),
                      if (remark.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📝 ', style: TextStyle(fontSize: 18)),
                            const Text('備註：', style: TextStyle(fontSize: 15, color: Colors.black87)),
                            Expanded(
                              child: Text(remark, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // 按鈕
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: const Text('我知道了', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}