import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// 引入 Providers 和 Screens
import 'providers/chant_provider.dart';
import 'providers/queue_provider.dart';
import 'providers/tab_provider.dart'; 
import 'providers/auth_provider.dart'; 
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart'; 
import 'screens/calendar_screen.dart';
import 'screens/health_screen.dart'; 
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChantingApp());
}

class ChantingApp extends StatelessWidget {
  const ChantingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChantProvider()..init()),
        ChangeNotifierProvider(create: (_) => QueueProvider()..init()),
        ChangeNotifierProvider(create: (_) => TabProvider()), 
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()), 
      ],
      child: MaterialApp(
        title: '念佛計步',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.bgWarm,
          useMaterial3: true,
          
          // 🔥 底部導覽列主題設定
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF3D1F56).withOpacity(0.85),  // 深紫色背景
            indicatorColor: Colors.white.withOpacity(0.15), // 選中時的半透明膠囊
            elevation: 0, // 移除預設陰影，避免透明感被吃掉
            shadowColor: Colors.black45,
            
            // 🔥 強制文字顏色為白色
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white);
              }
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70);
            }),
            
            // 🔥 圖示顏色 (如果您在 destinations 有寫，這裡會作為預設)
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const IconThemeData(color: Colors.white);
              }
              return const IconThemeData(color: Colors.white70);
            }),
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'TW'),
          Locale('en', 'US'),
        ],
        locale: const Locale('zh', 'TW'),
        home: const MainTabScreen(),
      ),
    );
  }
}

// ==========================================
// 底部導覽列容器
// ==========================================
class MainTabScreen extends StatelessWidget {
  const MainTabScreen({super.key});

    @override
  Widget build(BuildContext context) {
    final tab = context.watch<TabProvider>();

    return Scaffold(
      // 🔥 1. 讓頁面內容延伸到導覽列下方，這樣才能透出背景漸層
      extendBody: true, 
      body: IndexedStack(
        index: tab.currentIndex,
        children: const [
          HomeScreen(),          // Index 0: 念佛
          CalendarScreen(),      // Index 1: 月曆
          HealthScreen(),        // Index 2: 健康
          SettingsScreen(),      // Index 3: 設定
        ],
      ),
      bottomNavigationBar: Container(
        // 🔥 2. 在外層加上微透明的背景與頂部極細白線
        decoration: BoxDecoration(
          color: const Color(0xFF3D1F56).withOpacity(0.85), // 85% 的深紫色，微透出底色
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: tab.currentIndex,
          onDestinationSelected: (index) {
            context.read<TabProvider>().setIndex(index);
          },
          // 🔥 3. 這裡必須設為透明，否則會蓋掉外層 Container 的半透明效果
          backgroundColor: Colors.transparent, 
          elevation: 0, 
          indicatorColor: Colors.white.withOpacity(0.15),
          
          destinations: const [
            // 🪷 念佛
            NavigationDestination(
              icon: Icon(Icons.local_florist, color: Colors.white70),
              selectedIcon: Icon(Icons.local_florist, color: Color(0xFFD1C4E9)),
              label: '念佛',
            ),
            // 📅 月曆
            NavigationDestination(
              icon: Icon(Icons.calendar_today, color: Colors.white70),
              selectedIcon: Icon(Icons.calendar_today, color: Color(0xFFD1C4E9)),
              label: '月曆',
            ),
            // ❤️ 健康
            NavigationDestination(
              icon: Icon(Icons.favorite, color: Colors.white70),
              selectedIcon: Icon(Icons.favorite, color: Color(0xFFFF8A80)),
              label: '健康',
            ),
            // ⚙️ 設定
            NavigationDestination(
              icon: Icon(Icons.settings, color: Colors.white70),
              selectedIcon: Icon(Icons.settings, color: Color(0xFFD1C4E9)),
              label: '設定',
            ),
          ],
        ),
      ),
    );
  }
} 