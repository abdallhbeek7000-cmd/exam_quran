import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import '../widgets/animated_glass_background.dart';
import 'read_only_mushaf_screen.dart';

class StudentResultsScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentResultsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentGold = Color(0xffd4af37);
    const primaryBlue = Color(0xff425c75);
    final textColor = isDark ? Colors.white : primaryBlue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          "سجل اختبارات: $studentName",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: AnimatedGlassBackground(
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            // قمنا بإزالة الـ where مؤقتاً لنضمن جلب البيانات، وسنقوم بالفلترة داخل الكود
            stream: FirebaseFirestore.instance.collection('exams_results').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: accentGold));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("لا توجد بيانات في قاعدة البيانات.", style: TextStyle(color: textColor)));
              }

              // عملية الفلترة الذكية
              final results = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String dbId = data['student_id']?.toString().trim() ?? "";
                return dbId == studentId.trim();
              }).toList()
              ..sort((a, b) {
                Timestamp t1 = (a.data() as Map<String, dynamic>)['exam_date'] ?? Timestamp.now();
                Timestamp t2 = (b.data() as Map<String, dynamic>)['exam_date'] ?? Timestamp.now();
                return t2.compareTo(t1); // ترتيب تنازلي
              });

              if (results.isEmpty) {
                return Center(child: Text("لم يتم العثور على نتائج لهذا الطالب.", style: TextStyle(color: textColor)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  var data = results[index].data() as Map<String, dynamic>;
                  double finalScore = (data['score'] ?? 0).toDouble();
                  Timestamp? timestamp = data['exam_date'] as Timestamp?;
                  String dateStr = timestamp != null 
                      ? intl.DateFormat('yyyy-MM-dd / hh:mm a').format(timestamp.toDate()) 
                      : 'تاريخ غير معروف';
                  
                  String duration = data['duration_text'] ?? '00:00';
                  List<dynamic> errorsList = data['errors_details'] ?? [];
                  int startPage = data['start_page'] ?? 1; 
                  int endPage = data['end_page'] ?? 604;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("النتيجة: $finalScore %", style: TextStyle(fontWeight: FontWeight.bold, color: finalScore >= 90 ? Colors.green : Colors.orange, fontSize: 18)),
                            Text("⏱️ $duration", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text("التاريخ: $dateStr", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReadOnlyMushafScreen(
                                  studentName: studentName,
                                  startPage: startPage,
                                  endPage: endPage,
                                  errorsList: errorsList.cast<String>(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.menu_book_rounded),
                          label: const Text("استعراض الأخطاء على المصحف 📖"),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}