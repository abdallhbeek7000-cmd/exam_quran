import 'dart:ui'; // 👈 ضروري لتأثير التشويش الزجاجي (Blur)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/animated_glass_background.dart';
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
  bool _rememberMe = false;

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
      // الفحص في كوليكشن users (المدير)
      var managerQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: emailInput)
          .where('role', isEqualTo: 'manager')
          .get();

      if (managerQuery.docs.isNotEmpty) {
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

      // الفحص في كوليكشن supervisors (المشرف)
      var supervisorQuery = await FirebaseFirestore.instance
          .collection('supervisors')
          .where('email', isEqualTo: emailInput)
          .get();

      if (supervisorQuery.docs.isNotEmpty) {
        var supervisorDoc = supervisorQuery.docs.first;
        String supervisorId = supervisorDoc.id; 
        String supervisorName = supervisorDoc.data()['name'] ?? 'المشرف';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xff425c75);
    final accentGold = const Color(0xffd4af37);
    
    final textColor = isDark ? Colors.white : const Color(0xff1e293b);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedGlassBackground(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // اللوجو أو الأيقونة بتصميم ناعم
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? accentGold : primaryColor).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_book_rounded, 
                    size: 60, 
                    color: isDark ? accentGold : primaryColor
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  "نظام اختبارات الحلقات", 
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.w900, 
                    color: textColor,
                    letterSpacing: 0.5,
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  "سجل دخولك السريع لمتابعة الحلقات", 
                  style: TextStyle(fontSize: 14, color: subTextColor, fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 45),
                
                // 💎 الكرت الزجاجي الاحترافي (Glassmorphism)
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // قوة التشويش للخلفية
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // ✉️ حقل الإدخال بتصميم عصري
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'البريد الإلكتروني',
                                hintStyle: TextStyle(color: subTextColor.withOpacity(0.7)),
                                prefixIcon: Icon(Icons.email_outlined, color: isDark ? accentGold : primaryColor),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // 🔄 خانة اختيار تذكرني
                          Row(
                            children: [
                              Transform.scale(
                                scale: 1.1,
                                child: Checkbox(
                                  activeColor: isDark ? accentGold : primaryColor,
                                  checkColor: isDark ? Colors.black : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  side: BorderSide(color: isDark ? Colors.white54 : Colors.black45, width: 1.5),
                                  value: _rememberMe,
                                  onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "تذكرني على هذا الجهاز", 
                                  style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 35),
                          
                          // 🚀 زر الدخول بتدرج لوني فخم
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: isDark 
                                    ? [accentGold, const Color(0xffb5952f)]
                                    : [primaryColor, const Color(0xff2a3d4f)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? accentGold : primaryColor).withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      "دخول", 
                                      style: TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.black87 : Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}