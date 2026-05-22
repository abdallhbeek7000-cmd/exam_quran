import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_dashboard_screen.dart';
import 'teacher_students_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false; // ميزة تذكرني

  void _handleLogin() async {
    String emailInput = _emailController.text.trim().toLowerCase();

    if (emailInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد الإلكتروني أولاً')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ الفحص في كوليكشن users (المدير) بناءً على الإيميل فقط 🎯
      var managerQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: emailInput)
          .where('role', isEqualTo: 'manager')
          .get();

      if (managerQuery.docs.isNotEmpty) {
        // إذا اختار تذكرني، نحفظ رول المدير محلياً بجهازه 💾
        if (_rememberMe) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', true);
          await prefs.setString('user_role', 'manager');
        }

        setState(() => _isLoading = false);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
        );
        return;
      }

      // 2️⃣ الفحص في كوليكشن supervisors (المشرف) بناءً على الإيميل فقط 🎯
      var supervisorQuery = await FirebaseFirestore.instance
          .collection('supervisors')
          .where('email', isEqualTo: emailInput)
          .get();

      if (supervisorQuery.docs.isNotEmpty) {
        var supervisorDoc = supervisorQuery.docs.first;
        String supervisorId = supervisorDoc.id; 
        String supervisorName = supervisorDoc.data()['name'] ?? 'المشرف';

        // إذا اختار تذكرني، نحفظ بيانات المشرف ليتخطى تسجيل الدخول مستقبلاً 💾
        if (_rememberMe) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', true);
          await prefs.setString('user_role', 'supervisor');
          await prefs.setString('user_id', supervisorId);
          await prefs.setString('user_name', supervisorName);
        }

        setState(() => _isLoading = false);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherStudentsPage(
              supervisorId: supervisorId,
              supervisorName: supervisorName,
            ),
          ),
        );
        return;
      }

      // البريد غير مسجل
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا البريد الإلكتروني غير مسجل في النظام!')),
      );

    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء فحص الحساب: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_rounded, size: 80, color: Color(0xff425c75)),
              const SizedBox(height: 15),
              const Text("نظام اختبارات الحلقات 📖", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff425c75))),
              const SizedBox(height: 5),
              const Text("سجل دخولك السريع باستخدام البريد الإلكتروني", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 35),
              
              // حقل البريد الإلكتروني فقط
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: const Icon(Icons.email, color: Color(0xff425c75)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 10),
              
              // خانة اختيار تذكرني
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    activeColor: const Color(0xff425c75),
                    value: _rememberMe,
                    onChanged: (val) => setState(() => _rememberMe = val ?? false),
                  ),
                  const Text("تذكر تسجيل الدخول على هذا الجهاز", style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 25),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff425c75),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("تسجيل الدخول", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}