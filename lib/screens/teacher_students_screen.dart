import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; 
import 'interactive_exam_screen.dart'; 

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
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff425c75),
        title: Text("المشرف: ${widget.supervisorName} 👨‍🏫", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بنر حالة النظام أونلاين
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isExamOpen ? Colors.teal.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isExamOpen ? Colors.teal.shade200 : Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(isExamOpen ? Icons.lock_open_rounded : Icons.lock_rounded, color: isExamOpen ? Colors.teal.shade700 : Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isExamOpen ? "حالة نظام الاختبارات: مفتوح حالياً ✅" : "حالة نظام الاختبارات: مغلق الآن ❌",
                            style: TextStyle(fontWeight: FontWeight.bold, color: isExamOpen ? Colors.teal.shade900 : Colors.red.shade900),
                          ),
                          Text(
                            isExamOpen ? "يمكنك بدء التسميع للطلاب المسندين إليك." : "لا يمكنك تشغيل الاختبار؛ تم الإغلاق بواسطة الإدارة.",
                            style: TextStyle(fontSize: 12, color: isExamOpen ? Colors.teal.shade700 : Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Text("قائمة طلاب حلقتك الموكلة إليك:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('students')
                      .where('supervisorId', isEqualTo: widget.supervisorId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xff425c75)));
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) return const Center(child: Text("لا يوجد طلاب مسندين لحلقتك حالياً."));

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var studentDoc = docs[index];
                        var studentData = studentDoc.data() as Map<String, dynamic>;
                        
                        String studentName = studentData['name'] ?? 'طالب غير مسمى';
                        var serialData = studentData['serial'] ?? '0000';
                        String schoolGrade = studentData['schoolGrade'] ?? 'غير محدد';
                        String imageUrl = studentData['imageUrl'] ?? ''; 
                        String studentId = studentDoc.id; 
                        
                        // جلب بيانات التكليف التي يحددها المدير 🎯
                        String requiredExam = studentData['required_exam'] ?? 'لم يتم تحديد تكليف بعد';
                        int startPage = studentData['start_page'] ?? 1;
                        int endPage = studentData['end_page'] ?? 604;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                          child: Row(
                            children: [
                              // صورة الطالب الدائرية
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: const Color(0xff425c75).withOpacity(0.1),
                                backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                                child: imageUrl.isEmpty 
                                    ? const Icon(Icons.person, color: Color(0xff425c75), size: 24) 
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text("الرقم: $serialData  •  الصف: $schoolGrade", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    // 📝 عرض التكليف والمطلوب للمشرف بشكل ملوّن وواضح جداً
                                    Text(
                                      "المطلوب: $requiredExam\n(من صـ $startPage إلى صـ $endPage)",
                                      style: const TextStyle(color: Color(0xff425c75), fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isExamOpen ? const Color(0xff425c75) : Colors.grey.shade400, 
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onPressed: isExamOpen ? () {
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
                                    const SnackBar(content: Text('نظام الاختبارات مغلق حالياً من الإدارة ولا يسمح بالرصد! 🔒')),
                                  );
                                },
                                child: const Text("بدء اختبار", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}