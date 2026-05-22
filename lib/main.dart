import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart'; 
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/teacher_students_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🎯 فحص ميزة تذكرني قبل إقلاع الواجهة
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool rememberMe = prefs.getBool('remember_me') ?? false;
  String savedRole = prefs.getString('user_role') ?? '';
  String savedId = prefs.getString('user_id') ?? '';
  String savedName = prefs.getString('user_name') ?? '';

  Widget initialScreen = const LoginPage();

  // إذا كان مفعّل "تذكرني" والبيانات مخزنة، طيّر به فوراً لصفحته 🚀
  if (rememberMe && savedRole.isNotEmpty) {
    if (savedRole == 'manager') {
      initialScreen = const AdminDashboardPage();
    } else if (savedRole == 'supervisor') {
      initialScreen = TeacherStudentsPage(
        supervisorId: savedId,
        supervisorName: savedName,
      );
    }
  }

  runApp(QuranExamsApp(homeScreen: initialScreen));
}

class QuranExamsApp extends StatelessWidget {
  final Widget homeScreen;
  const QuranExamsApp({super.key, required this.homeScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق اختبارات القرآن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xff425c75),
        fontFamily: 'Cairo', 
      ),
      home: homeScreen, 
    );
  }
}