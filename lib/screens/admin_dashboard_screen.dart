import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
// 🚀 استدعاء صفحة عرض المصحف الجديدة
import 'read_only_mushaf_screen.dart'; 

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
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

  // --- الألوان الأساسية للتطبيق ---
  final Color primaryDark = const Color(0xff2b3a4a);
  final Color primaryColor = const Color(0xff425c75);
  final Color primaryLight = const Color(0xff5b7d9c);
  final Color accentColor = Colors.teal;
  final Color backgroundColor = const Color(0xfff5f8fd);

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
    var doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('global_config')
        .get();
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
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('global_config')
        .set({
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
    _showFloatingSnackBar('تم حفظ وتعميم المعايير بنجاح! 🎉', Colors.green.shade700);
  }

  void _showFloatingSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        elevation: 6,
      ),
    );
  }

  void _showAssignExamDialog(String studentId, String studentName, int currentStart, int currentEnd, String currentText) {
    TextEditingController textController = TextEditingController(text: currentText);
    TextEditingController startController = TextEditingController(text: currentStart == 0 ? '1' : currentStart.toString());
    TextEditingController endController = TextEditingController(text: currentEnd == 0 ? '604' : currentEnd.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.assignment_add, color: accentColor, size: 30),
            ),
            const SizedBox(height: 10),
            Text("تحديد اختبار لـ $studentName", 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), 
                textAlign: TextAlign.center),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController, 
                decoration: InputDecoration(
                  labelText: "التكليف (مثال: البقرة ونصف آل عمران)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                )
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: TextField(
                    controller: startController, 
                    keyboardType: TextInputType.number, 
                    decoration: InputDecoration(labelText: "من صـ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: endController, 
                    keyboardType: TextInputType.number, 
                    decoration: InputDecoration(labelText: "إلى صـ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
                  )),
                ],
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('students').doc(studentId).update({
                'required_exam': textController.text.trim(),
                'start_page': int.tryParse(startController.text) ?? 1,
                'end_page': int.tryParse(endController.text) ?? 604,
              });
              if (!mounted) return;
              Navigator.pop(context);
              _showFloatingSnackBar("تم حفظ التكليف بنجاح! 🎯", accentColor);
            },
            child: const Text("حفظ التكليف", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _deleteExamResult(String docId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 35),
            ),
            const SizedBox(height: 10),
            const Text('تأكيد الحذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'هل أنت متأكد أنك تريد حذف نتيجة اختبار "$studentName" نهائياً؟\nلا يمكن التراجع عن هذا الإجراء.',
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance.collection('exams_results').doc(docId).delete();
                if (!mounted) return;
                _showFloatingSnackBar('تم حذف النتيجة بنجاح! 🗑️', Colors.red.shade700);
              } catch (e) {
                if (!mounted) return;
                _showFloatingSnackBar('حدث خطأ أثناء الحذف: $e', Colors.red.shade900);
              }
            },
            child: const Text('نعم، احذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard(String title, double value, Function(double) onChanged, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(value.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: iconColor.withOpacity(0.7),
                inactiveTrackColor: iconColor.withOpacity(0.2),
                thumbColor: iconColor,
                overlayColor: iconColor.withOpacity(0.2),
                trackHeight: 6.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
              ),
              child: Slider(value: value, min: 0, max: 5, divisions: 20, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDark, primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text("لوحة تحكم المدير 👑", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18, letterSpacing: 0.5)),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withOpacity(0.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          tabs: const [
            Tab(icon: Icon(Icons.settings_suggest, size: 22), text: "المعايير"),
            Tab(icon: Icon(Icons.assignment_ind_rounded, size: 22), text: "التكاليف"),
            Tab(icon: Icon(Icons.analytics_rounded, size: 22), text: "النتائج 📊"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white), 
            tooltip: 'تسجيل الخروج',
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()))
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ---------------- التبويب الأول: المعايير وقفل النظام ----------------
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: SwitchListTile(
                  activeColor: Colors.white,
                  activeTrackColor: Colors.teal.shade200,
                  inactiveThumbColor: Colors.grey.shade300,
                  inactiveTrackColor: Colors.black26,
                  title: const Text("تفعيل نظام الاختبارات اليوم", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  subtitle: Text(isExamOpen ? "النظام مفتوح الآن لاستقبال التسميع" : "النظام مغلق حالياً", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  value: isExamOpen,
                  onChanged: (val) => setState(() => isExamOpen = val),
                  secondary: const Icon(Icons.sensor_door_rounded, color: Colors.white, size: 30),
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text("معايير خصم الدرجات:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              
              _buildSliderCard("1. خطأ حفظ صحح لنفسه", hifzSelf, (v) => setState(() => hifzSelf = v), Icons.menu_book, Colors.blue),
              _buildSliderCard("2. خطأ حفظ صحح له", hifzCorrected, (v) => setState(() => hifzCorrected = v), Icons.import_contacts, Colors.orange),
              _buildSliderCard("3. خطأ تشكيل صحح بنفسه", tashkeelSelf, (v) => setState(() => tashkeelSelf = v), Icons.spellcheck, Colors.blueGrey),
              _buildSliderCard("4. خطأ تشكيل صحح له", tashkeelCorrected, (v) => setState(() => tashkeelCorrected = v), Icons.format_color_text, Colors.deepOrange),
              _buildSliderCard("5. التجويد الرئيسي", tajweedMain, (v) => setState(() => tajweedMain = v), Icons.record_voice_over, Colors.purple),
              _buildSliderCard("6. التجويد الفرعي", tajweedSub, (v) => setState(() => tajweedSub = v), Icons.voice_chat, Colors.deepPurpleAccent),
              _buildSliderCard("7. الوقف والابتداء خطأ", waqfWrong, (v) => setState(() => waqfWrong = v), Icons.pause_circle_outline, Colors.brown),
              _buildSliderCard("8. الوقف والابتداء خطأ قبيح", waqfUgly, (v) => setState(() => waqfUgly = v), Icons.do_not_disturb_alt, Colors.red),
              
              const SizedBox(height: 10),
              Container(
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _saveSettings,
                  child: _isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, color: Colors.white),
                            SizedBox(width: 10),
                            Text("حفظ وتحديث المعايير", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        )
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),

          // ---------------- التبويب الثاني: تحديد الاختبارات ----------------
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('students').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("لا يوجد طلاب مسجلين."));
              
              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String name = data['name'] ?? 'طالب';
                  String currentExam = data['required_exam'] ?? 'لم يتم التحديد';
                  String supervisorName = data['supervisorName'] ?? 'غير مسند لمشرف';
                  String imageUrl = data['imageUrl'] ?? '';
                  int startP = data['start_page'] ?? 1;
                  int endP = data['end_page'] ?? 604;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryLight.withOpacity(0.3), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: primaryColor.withOpacity(0.05),
                          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                          child: imageUrl.isEmpty ? Icon(Icons.person, color: primaryColor, size: 28) : null,
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.co_present_rounded, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(supervisorName, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                "المطلوب: $currentExam (صـ $startP - صـ $endP)",
                                style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Material(
                        color: accentColor.withOpacity(0.1),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _showAssignExamDialog(docs[index].id, name, startP, endP, currentExam),
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(Icons.edit_document, color: Colors.teal),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ---------------- التبويب الثالث: كل النتائج والأخطاء ----------------
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('exams_results').orderBy('exam_date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 15),
                      Text("لا توجد اختبارات مسجلة حالياً.", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                    ],
                  )
                );
              }
              
              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String docId = docs[index].id; 
                  String name = data['student_name'] ?? 'طالب';
                  double score = (data['score'] ?? 0.0).toDouble();
                  List<dynamic> errorsDetails = data['errors_details'] ?? [];
                  String durationText = data['duration_text'] ?? '--:--';
                  
                  // 🚀 جلب أرقام صفحات هذا الاختبار تحديداً
                  int examStartPage = data['start_page'] ?? 1;
                  int examEndPage = data['end_page'] ?? 604;

                  String dateString = "غير محدد";
                  if (data['exam_date'] != null) {
                    DateTime date = (data['exam_date'] as Timestamp).toDate();
                    dateString = "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                  }

                  // تحديد لون التقييم
                  Color scoreColor = score >= 90 ? Colors.green : (score >= 80 ? Colors.amber.shade700 : Colors.red);
                  Color scoreBgColor = score >= 90 ? Colors.green.shade50 : (score >= 80 ? Colors.amber.shade50 : Colors.red.shade50);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        iconColor: primaryColor,
                        collapsedIconColor: Colors.grey,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: scoreBgColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: scoreColor.withOpacity(0.5), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              score.toStringAsFixed(1), 
                              style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 13)
                            ),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(dateString, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 14, color: Colors.blue.shade700),
                                  const SizedBox(width: 4),
                                  Text("المدة: $durationText", style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: errorsDetails.isEmpty ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4)
                                    ),
                                    child: Text(
                                      errorsDetails.isEmpty ? "بدون أخطاء 🎉" : "${errorsDetails.length} أخطاء 🔽", 
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: errorsDetails.isEmpty ? Colors.green.shade700 : Colors.red.shade700)
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        children: [
                          // 🚀 إزالة قسم النصوص، والإبقاء فقط على أزرار التحكم
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                              border: Border(top: BorderSide(color: Colors.grey.shade200))
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // زر حذف النتيجة
                                TextButton.icon(
                                  onPressed: () => _deleteExamResult(docId, name),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  label: const Text("حذف النتيجة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                                ),
                                // 🚀 الزر لفتح المصحف بالصفحات المخصصة
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReadOnlyMushafScreen(
                                          studentName: name,
                                          startPage: examStartPage,
                                          endPage: examEndPage,
                                          errorsList: errorsDetails,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                                  label: const Text("عرض المصحف 📖", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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