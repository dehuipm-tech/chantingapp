import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==========================================
  // 🔮 深紫羅蘭主題 (Deep Violet)
  // ==========================================
  
  // 主色調：深紫
  static const Color primary       = Color(0xFF4A2A6A); // 主背景漸層起點
  static const Color primaryDark   = Color(0xFF3A1A5A); // AppBar 深紫
  static const Color primaryLight  = Color(0xFFF3E8FF); // 極淺紫（選中背景）
  
  // 輔助色：淺紫/粉紫
  static const Color accent        = Color(0xFFB090D0); // 按鈕、強調色
  static const Color accentLight   = Color(0xFFE0C0F0); // 淺紫文字
  
  // 卡片與背景（因為是深色主題，卡片用深紫灰）
  static const Color bgWarm        = Color(0xFF5A3A7A); // 主背景漸層終點
  static const Color bgCard        = Color(0xFF4A2A6A); // 卡片背景（深紫）
  static const Color borderSoft    = Color(0xFF6A4A8A); // 邊框
  static const Color borderLight   = Color(0xFF8A6AAA); // 🔥 補上這個淺紫邊框
  
  // 文字顏色（深色背景要用淺色字）
  static const Color textDark      = Color(0xFFE0C0F0); // 標題：淺紫
  static const Color textMid       = Color(0xFFD0B0E8); // 內文：粉紫
  static const Color textSoft      = Color(0xFFB090D0); // 副標題：暗紫
  static const Color textHint      = Color(0xFF9E7EBA); // 提示文字

  // 功能色（在深色背景下稍微調亮）
  static const Color green         = Color(0xFF66BB6A); // 開始念佛（亮綠）
  static const Color orange        = Color(0xFFFFA726); // 暫停（亮橘）
  static const Color orangeLight   = Color(0xFFFEF4E8); // 🔥 補上這行！(淺橘底)
  static const Color red           = Color(0xFFEF5350); // 結束（亮紅）
  static const Color blue          = Color(0xFF42A5F5); // 編輯

  // 舊變數保留以防報錯
  static const Color gold          = accent;
  static const Color goldLight     = accentLight;
  static const Color goldDark      = primary;
}