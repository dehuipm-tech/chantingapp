class AuthState {
  final bool loggedIn;
  final String loginType;   // 'group' | 'personal'
  final String memberNo;
  final String memberName;
  final String groupName;
  final String inviteCode;
  final String groupCode; // 🔥 新增：組別代碼 (例如 '01', '21')

  const AuthState({
    this.loggedIn = false,
    this.loginType = '',
    this.memberNo = '',
    this.memberName = '',
    this.groupName = '',
    this.inviteCode = '',
    this.groupCode = '', // 🔥 預設為空
  });

  Map<String, dynamic> toJson() => {
    'loggedIn': loggedIn,
    'loginType': loginType,
    'memberNo': memberNo,
    'memberName': memberName,
    'groupName': groupName,
    'inviteCode': inviteCode,
    'groupCode': groupCode,
  };

  factory AuthState.fromJson(Map<String, dynamic> json) => AuthState(
    loggedIn: json['loggedIn'] ?? false,
    loginType: json['loginType'] ?? '',
    memberNo: json['memberNo'] ?? '',
    memberName: json['memberName'] ?? '',
    groupName: json['groupName'] ?? '',
    inviteCode: json['inviteCode'] ?? '',
    groupCode: json['groupCode'] ?? '',
  );

  AuthState copyWith({
    bool? loggedIn,
    String? loginType,
    String? memberNo,
    String? memberName,
    String? groupName,
    String? inviteCode,
    String? groupCode, // 🔥 加入 copyWith
  }) => AuthState(
    loggedIn: loggedIn ?? this.loggedIn,
    loginType: loginType ?? this.loginType,
    memberNo: memberNo ?? this.memberNo,
    memberName: memberName ?? this.memberName,
    groupName: groupName ?? this.groupName,
    inviteCode: inviteCode ?? this.inviteCode,
    groupCode: groupCode ?? this.groupCode,
  );
}