import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/animated_glass_background.dart'; 
import 'login_screen.dart'; 
import 'interactive_exam_screen.dart';
import 'student_results_screen.dart'; // 👈 استيراد شاشة النتائج الجديدة

class TeacherStudentsPage extends StatefulWidget {
  final String supervisorId;
  final String supervisorName;
  const TeacherStudentsPage({super.key, required this.supervisorId, required this.supervisorName});

  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<TeacherStudentsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentGold = Color(0xffd4af37);
    const primaryBlue = Color(0xff425c75);

    final textColor = isDark ? Colors.white : primaryBlue;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox(), 
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4)),
              ),
              child: Text(
                "المشرف: ${widget.supervisorName} 👨‍🏫", 
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.4),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
            ),
          )
        ],
      ),
      body: AnimatedGlassBackground(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('settings').doc('global_config').snapshots(),
          builder: (context, settingsSnapshot) {
            bool isExamOpen = true;
            
            double penaltyHifzSelf = 0.25;
            double penaltyHifzCorrected = 1.0;
            double penaltyTashkeelSelf = 0.25;
            double penaltyTashkeelCorrected = 0.5;
            double penaltyTajweedMain = 0.5;
            double penaltyTajweedSub = 0.25;
            double penaltyWaqfWrong = 0.5;
            double penaltyWaqfUgly = 1.0;

            if (settingsSnapshot.hasData && settingsSnapshot.data!.exists) {
              var data = settingsSnapshot.data!.data() as Map<String, dynamic>?;
              if (data != null) {
                isExamOpen = data['is_exam_open'] ?? true;
                penaltyHifzSelf = (data['penalty_hifz_self'] ?? 0.25).toDouble();
                penaltyHifzCorrected = (data['penalty_hifz_corrected'] ?? 1.0).toDouble();
                penaltyTashkeelSelf = (data['penalty_tashkeel_self'] ?? 0.25).toDouble();
                penaltyTashkeelCorrected = (data['penalty_tashkeel_corrected'] ?? 0.5).toDouble();
                penaltyTajweedMain = (data['penalty_tajweed_main'] ?? 0.5).toDouble();
                penaltyTajweedSub = (data['penalty_tajweed_sub'] ?? 0.25).toDouble();
                penaltyWaqfWrong = (data['penalty_waqf_wrong'] ?? 0.5).toDouble();
                penaltyWaqfUgly = (data['penalty_waqf_ugly'] ?? 1.0).toDouble();
              }
            }

            final statusColor = isExamOpen ? Colors.teal : Colors.redAccent;

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? statusColor.withOpacity(0.05) : statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
                            boxShadow: [BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 20, spreadRadius: -5)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(isExamOpen ? Icons.lock_open_rounded : Icons.lock_rounded, color: statusColor, size: 28)
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isExamOpen ? "حالة النظام: مفتوح حالياً ✅" : "حالة النظام: مغلق الآن ❌",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 16),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isExamOpen ? "يمكنك بدء التسميع للطلاب المسندين إليك." : "تم إغلاق الرصد بواسطة الإدارة.",
                                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : statusColor.withOpacity(0.8)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      "قائمة طلاب حلقتك 📖:", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor, letterSpacing: 0.5),
                    ),
                  ),
                  
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('students')
                          .where('supervisorId', isEqualTo: widget.supervisorId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: isDark ? accentGold : primaryBlue));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              "لا يوجد طلاب مسندين لحلقتك حالياً.", 
                              style: TextStyle(color: subTextColor, fontSize: 15, fontWeight: FontWeight.w500),
                            )
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            var studentDoc = docs[index];
                            var studentData = studentDoc.data() as Map<String, dynamic>;
                            
                            String studentName = studentData['name'] ?? 'طالب غير مسمى';
                            var serialData = studentData['serial'] ?? '0000';
                            String schoolGrade = studentData['schoolGrade'] ?? 'غير محدد';
                            String imageUrl = studentData['imageUrl'] ?? ''; 
                            String studentId = studentDoc.id; 
                            
                            String requiredExam = studentData['required_exam'] ?? 'لم يتم تحديد تكليف بعد';
                            int startPage = studentData['start_page'] ?? 1;
                            int endPage = studentData['end_page'] ?? 604;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.3), width: 1.2),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: (isDark ? accentGold : primaryBlue).withOpacity(0.2), width: 2),
                                          ),
                                          child: CircleAvatar(
                                            radius: 30,
                                            backgroundColor: (isDark ? accentGold : primaryBlue).withOpacity(0.1),
                                            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                                            child: imageUrl.isEmpty 
                                                ? Icon(Icons.person, color: isDark ? accentGold : primaryBlue, size: 28) 
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(studentName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                              const SizedBox(height: 3),
                                              Text("الرقم: $serialData  •  للصف: $schoolGrade", style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isDark ? accentGold.withOpacity(0.1) : primaryBlue.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: (isDark ? accentGold : primaryBlue).withOpacity(0.2)),
                                                ),
                                                child: Text(
                                                  "المطلوب: $requiredExam\n(صـ $startPage إلى صـ $endPage)",
                                                  style: TextStyle(color: isDark ? accentGold : primaryBlue, fontSize: 12, fontWeight: FontWeight.bold, height: 1.4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          height: 90,
                                          child: VerticalDivider(color: (isDark ? accentGold : primaryBlue).withOpacity(0.2), thickness: 1, indent: 10, endIndent: 10),
                                        ),
                                        const SizedBox(width: 5),
                                        
                                        // 💡 تم التعديل هنا: إضافة زرين (النتائج وبدء)
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // 📊 زر النتائج
                                            InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => StudentResultsScreen(
                                                      studentId: studentId,
                                                      studentName: studentName,
                                                    ),
                                                  ),
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blueAccent.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                                                ),
                                                child: const Column(
                                                  children: [
                                                    Icon(Icons.analytics_rounded, size: 22, color: Colors.blueAccent),
                                                    SizedBox(height: 3),
                                                    Text("النتائج", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // 🚀 زر البدء
                                            InkWell(
                                              onTap: isExamOpen ? () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => InteractiveExamPage(
                                                      studentName: studentName,
                                                      studentId: studentId,
                                                      penaltyHifzSelf: penaltyHifzSelf,
                                                      penaltyHifzCorrected: penaltyHifzCorrected,
                                                      penaltyTashkeelSelf: penaltyTashkeelSelf,
                                                      penaltyTashkeelCorrected: penaltyTashkeelCorrected,
                                                      penaltyTajweedMain: penaltyTajweedMain,
                                                      penaltyTajweedSub: penaltyTajweedSub,
                                                      penaltyWaqfWrong: penaltyWaqfWrong,
                                                      penaltyWaqfUgly: penaltyWaqfUgly,
                                                      startPage: startPage,
                                                      endPage: endPage,
                                                    ),
                                                  ),
                                                );
                                              } : () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    backgroundColor: Colors.redAccent,
                                                    content: Text('نظام الاختبارات مغلق حالياً ولا يسمح بالرصد! 🔒', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: isExamOpen ? (isDark ? accentGold.withOpacity(0.2) : primaryBlue.withOpacity(0.1)) : Colors.grey.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: isExamOpen ? (isDark ? accentGold : primaryBlue).withOpacity(0.4) : Colors.grey),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Icon(Icons.play_circle_fill_rounded, size: 22, color: isExamOpen ? (isDark ? accentGold : primaryBlue) : Colors.grey),
                                                    const SizedBox(height: 3),
                                                    Text("بدء", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isExamOpen ? (isDark ? accentGold : primaryBlue) : Colors.grey)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}