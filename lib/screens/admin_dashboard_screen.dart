import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isExamOpen = true;
  
  double hifzSelf = 0.25;
  double hifzCorrected = 1.0;
  double tashkeelSelf = 0.25;
  double tashkeelCorrected = 0.5;
  double tajweedMain = 0.5;
  double tajweedSub = 0.25;
  double waqfWrong = 0.5;
  double waqfUgly = 1.0;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    var doc = await FirebaseFirestore.instance.collection('settings').doc('global_config').get();
    if (doc.exists) {
      setState(() {
        isExamOpen = doc.data()?['is_exam_open'] ?? true;
        hifzSelf = (doc.data()?['penalty_hifz_self'] ?? 0.25).toDouble();
        hifzCorrected = (doc.data()?['penalty_hifz_corrected'] ?? 1.0).toDouble();
        tashkeelSelf = (doc.data()?['penalty_tashkeel_self'] ?? 0.25).toDouble();
        tashkeelCorrected = (doc.data()?['penalty_tashkeel_corrected'] ?? 0.5).toDouble();
        tajweedMain = (doc.data()?['penalty_tajweed_main'] ?? 0.5).toDouble();
        tajweedSub = (doc.data()?['penalty_tajweed_sub'] ?? 0.25).toDouble();
        waqfWrong = (doc.data()?['penalty_waqf_wrong'] ?? 0.5).toDouble();
        waqfUgly = (doc.data()?['penalty_waqf_ugly'] ?? 1.0).toDouble();
      });
    }
  }

  void _saveSettings() async {
    setState(() => _isSaving = true);
    await FirebaseFirestore.instance.collection('settings').doc('global_config').set({
      'is_exam_open': isExamOpen,
      'penalty_hifz_self': hifzSelf,
      'penalty_hifz_corrected': hifzCorrected,
      'penalty_tashkeel_self': tashkeelSelf,
      'penalty_tashkeel_corrected': tashkeelCorrected,
      'penalty_tajweed_main': tajweedMain,
      'penalty_tajweed_sub': tajweedSub,
      'penalty_waqf_wrong': waqfWrong,
      'penalty_waqf_ugly': waqfUgly,
    });
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ وتعميم المعايير بنجاح! 🎉')));
  }

  void _showAssignExamDialog(String studentId, String studentName, int currentStart, int currentEnd, String currentText) {
    TextEditingController textController = TextEditingController(text: currentText);
    TextEditingController startController = TextEditingController(text: currentStart == 0 ? '1' : currentStart.toString());
    TextEditingController endController = TextEditingController(text: currentEnd == 0 ? '604' : currentEnd.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("تحديد اختبار لـ $studentName", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: textController, decoration: const InputDecoration(labelText: "التكليف (مثال: البقرة ونصف آل عمران)")),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: startController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "صفحة البداية"))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: endController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "صفحة النهاية"))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff425c75)),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('students').doc(studentId).update({
                'required_exam': textController.text.trim(),
                'start_page': int.tryParse(startController.text) ?? 1,
                'end_page': int.tryParse(endController.text) ?? 604,
              });
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ التكليف بنجاح! 🎯")));
            },
            child: const Text("حفظ", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _deleteExamResult(String docId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد أنك تريد حذف نتيجة اختبار "$studentName" نهائياً؟\nلا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); 
              try {
                await FirebaseFirestore.instance.collection('exams_results').doc(docId).delete();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف النتيجة بنجاح! 🗑️'), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء الحذف: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('حذف النتيجة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard(String title, double value, Function(double) onChanged) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Slider(value: value, min: 0, max: 5, divisions: 20, label: value.toStringAsFixed(2), onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff425c75),
        title: const Text("لوحة تحكم المدير 👑", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.teal,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: "المعايير وقفل النظام"),
            Tab(icon: Icon(Icons.assignment_ind), text: "تحديد الاختبارات"),
            Tab(icon: Icon(Icons.bar_chart), text: "كل النتائج والأخطاء 📊"),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()))),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // التبويب الأول
          ListView(
            padding: const EdgeInsets.all(15),
            children: [
              Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: SwitchListTile(activeColor: Colors.teal, title: const Text("تفعيل نظام الاختبارات اليوم", style: TextStyle(fontWeight: FontWeight.bold)), value: isExamOpen, onChanged: (val) => setState(() => isExamOpen = val))),
              _buildSliderCard("1. خطأ حفظ صحح لنفسه", hifzSelf, (v) => setState(() => hifzSelf = v)),
              _buildSliderCard("2. خطأ حفظ صحح له", hifzCorrected, (v) => setState(() => hifzCorrected = v)),
              _buildSliderCard("3. خطأ تشكيل صحح بنفسه", tashkeelSelf, (v) => setState(() => tashkeelSelf = v)),
              _buildSliderCard("4. خطأ تشكيل صحح له", tashkeelCorrected, (v) => setState(() => tashkeelCorrected = v)),
              _buildSliderCard("5. التجويد الرئيسي", tajweedMain, (v) => setState(() => tajweedMain = v)),
              _buildSliderCard("6. التجويد الفرعي", tajweedSub, (v) => setState(() => tajweedSub = v)),
              _buildSliderCard("7. الوقف والابتداء خطأ", waqfWrong, (v) => setState(() => waqfWrong = v)),
              _buildSliderCard("8. الوقف والابتداء خطأ قبيح", waqfUgly, (v) => setState(() => waqfUgly = v)),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff425c75)), 
                onPressed: _isSaving ? null : _saveSettings,
                child: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("حفظ المعايير السحابية", style: TextStyle(color: Colors.white))
              )
            ],
          ),

          // التبويب الثاني
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('students').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String name = data['name'] ?? 'طالب';
                  String currentExam = data['required_exam'] ?? 'لم يتم التحديد';
                  String supervisorName = data['supervisorName'] ?? 'غير مسند لمشرف';
                  String imageUrl = data['imageUrl'] ?? '';
                  int startP = data['start_page'] ?? 1;
                  int endP = data['end_page'] ?? 604;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xff425c75).withOpacity(0.1),
                        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty 
                            ? const Icon(Icons.person, color: Color(0xff425c75), size: 26) 
                            : null,
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "المشرف: $supervisorName\nالمطلوب: $currentExam (من صـ $startP لـ صـ $endP)",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xff425c75)), 
                        onPressed: () => _showAssignExamDialog(docs[index].id, name, startP, endP, currentExam)
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // 📈 التبويب الثالث المطور: عرض النتائج بالتاريخ والوقت والكلمة المخطأ فيها بالظبط! ✅
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('exams_results').orderBy('exam_date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("لا توجد اختبارات مسجلة حالياً."));

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String docId = docs[index].id; 
                  String name = data['student_name'] ?? 'طالب';
                  double score = (data['score'] ?? 0.0).toDouble();
                  List<dynamic> errorsDetails = data['errors_details'] ?? [];
                  String durationText = data['duration_text'] ?? '--:--';

                  String dateString = "غير محدد";
                  if (data['exam_date'] != null) {
                    DateTime date = (data['exam_date'] as Timestamp).toDate();
                    dateString = "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                  }

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: score >= 90 ? Colors.green.shade50 : (score >= 80 ? Colors.amber.shade50 : Colors.red.shade50),
                        child: Text(
                          score.toStringAsFixed(1), 
                          style: TextStyle(
                            color: score >= 90 ? Colors.green.shade900 : (score >= 80 ? Colors.amber.shade900 : Colors.red.shade900), 
                            fontWeight: FontWeight.bold, 
                            fontSize: 13
                          )
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text("الوقت: $dateString", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                const SizedBox(width: 12),
                                Icon(Icons.timer_outlined, size: 13, color: Colors.amber.shade800),
                                const SizedBox(width: 4),
                                Text("المدة: $durationText", style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              errorsDetails.isEmpty ? "التسميع ممتاز وبدون أخطاء! 🎉" : "عدد مواضع الخربطة: ${errorsDetails.length} مواضع 🔽", 
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: errorsDetails.isEmpty ? Colors.green.shade700 : Colors.red.shade700)
                            ),
                          ],
                        ),
                      ),
                      children: [
                        if (errorsDetails.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.grey.shade50,
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("تفاصيل مواضع الأخطاء من المصحف:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff425c75))),
                                const SizedBox(height: 6),
                                // 🎯 التعديل الجوهري: طباعة عناصر الأخطاء كـ نصوص صريحة ومقروءة لتظهر الكلمات والنوع معاً مية بالمية
                                ...errorsDetails.map((err) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.label_important_outline, size: 15, color: Colors.purple),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            err.toString(), 
                                            textDirection: TextDirection.rtl, // لضمان قراءة الكلمة العربية قبل نوع الخطأ بشكل منسق
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        Container(
                          width: double.infinity,
                          color: Colors.grey.shade50,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _deleteExamResult(docId, name),
                              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                              label: const Text("حذف هذه النتيجة", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}