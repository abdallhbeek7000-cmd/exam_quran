import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:cloud_firestore/cloud_firestore.dart';

class InteractiveExamPage extends StatefulWidget {
  final String studentName;
  final String studentId;
  final double penaltyHifzSelf;
  final double penaltyHifzCorrected;
  final double penaltyTashkeelSelf;
  final double penaltyTashkeelCorrected;
  final double penaltyTajweedMain;
  final double penaltyTajweedSub;
  final double penaltyWaqfWrong;
  final double penaltyWaqfUgly;
  final int startPage;
  final int endPage;

  const InteractiveExamPage({
    super.key, 
    required this.studentName, 
    required this.studentId,
    required this.penaltyHifzSelf,
    required this.penaltyHifzCorrected,
    required this.penaltyTashkeelSelf,
    required this.penaltyTashkeelCorrected,
    required this.penaltyTajweedMain,
    required this.penaltyTajweedSub,
    required this.penaltyWaqfWrong,
    required this.penaltyWaqfUgly,
    required this.startPage,
    required this.endPage,
  });

  @override
  State<InteractiveExamPage> createState() => _InteractiveExamPageState();
}

class _InteractiveExamPageState extends State<InteractiveExamPage> {
  late PageController _pageController;
  int currentPage = 1; 
  double studentScore = 100.0; 
  Map<String, String> wrongWordsLog = {}; 
  Map<String, String> wrongWordsWithText = {}; 

  Timer? _examTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = true;

  @override
  void initState() {
    super.initState();
    currentPage = widget.startPage;
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  @override
  void dispose() {
    _examTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimerRunning) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _toggleTimer() {
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });
  }

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');
    return "$minutesStr:$secondsStr";
  }

  Map<int, List<int>> _getSurahAndVersesForPage(int pageNum) {
    Map<int, List<int>> pageData = {};
    for (int surah = 1; surah <= 114; surah++) {
      int totalVerses = quran.getVerseCount(surah);
      List<int> versesInPage = [];
      for (int verse = 1; verse <= totalVerses; verse++) {
        if (quran.getPageNumber(surah, verse) == pageNum) {
          versesInPage.add(verse);
        }
      }
      if (versesInPage.isNotEmpty) pageData[surah] = versesInPage;
    }
    return pageData;
  }

  String _getSurahNamesInPage(int pageNum) {
    Map<int, List<int>> pageData = _getSurahAndVersesForPage(pageNum);
    return pageData.keys.map((num) => quran.getSurahNameArabic(num)).join(' - ');
  }

  void _showSurahSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("اختر السورة للانتقال السريع", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff425c75))),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, 
            child: ListView.builder(
              itemCount: 114,
              itemBuilder: (context, index) {
                int surahNum = index + 1;
                String surahName = quran.getSurahNameArabic(surahNum);
                return ListTile(
                  title: Text("$surahNum. سورة $surahName", textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.menu_book, size: 18, color: Color(0xff425c75)),
                  onTap: () {
                    int targetPage = quran.getPageNumber(surahNum, 1);
                    Navigator.pop(context); 
                    _pageController.jumpToPage(targetPage - 1);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int allowedPagesCount = (widget.endPage - widget.startPage) + 1;

    return Scaffold(
      backgroundColor: const Color(0xffeae6df), 
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xff425c75),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("واجهة رصد الاختبار الحماسية 🎯", style: TextStyle(fontSize: 11, color: Colors.white70)),
            Text("الطالب: ${widget.studentName}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _finishExamAndSave, 
              child: const Text("إنهاء وحفظ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xff425c75)), onPressed: currentPage > widget.startPage ? () => _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.linear) : null),
                
                GestureDetector(
                  onTap: _showSurahSelectionDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xff425c75).withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                    child: Text("سورة ${_getSurahNamesInPage(currentPage)} | صـ $currentPage 🔽", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff425c75), fontSize: 13)),
                  ),
                ),

                InkWell(
                  onTap: _toggleTimer,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isTimerRunning ? Colors.amber.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _isTimerRunning ? Colors.amber.shade400 : Colors.red.shade300, width: 1)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isTimerRunning ? Icons.timer_outlined : Icons.pause_circle_filled_rounded, 
                          size: 16, 
                          color: _isTimerRunning ? Colors.amber.shade900 : Colors.red.shade700
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatDuration(_elapsedSeconds),
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            fontFamily: 'monospace',
                            color: _isTimerRunning ? Colors.amber.shade900 : Colors.red.shade800
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xff425c75)), onPressed: currentPage < widget.endPage ? () => _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.linear) : null),
              ],
            ),
          ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: allowedPagesCount,
              onPageChanged: (idx) => setState(() => currentPage = widget.startPage + idx),
              itemBuilder: (context, pageIndex) {
                int pageNum = widget.startPage + pageIndex;
                Map<int, List<int>> pageData = _getSurahAndVersesForPage(pageNum);

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xfffbf7f0), 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffc2b091), width: 3), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffc2b091).withOpacity(0.4), width: 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ListView(
                      children: pageData.entries.map((entry) {
                        int surahNum = entry.key;
                        List<int> verses = entry.value;

                        return Column(
                          children: [
                            if (verses.isNotEmpty && verses.first == 1)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(vertical: 14),
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xfff5ebd6),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xffc2b091).withOpacity(0.7), width: 1.5),
                                ),
                                child: Text(
                                  "سُورَةُ ${quran.getSurahNameArabic(surahNum)}", 
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontFamily: 'Uthmanic', fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xff5c4d37)),
                                ),
                              ),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runAlignment: WrapAlignment.center,
                                spacing: 4, 
                                runSpacing: 12, 
                                textDirection: TextDirection.rtl,
                                children: verses.expand((verseNum) {
                                  String verseText = quran.getVerse(surahNum, verseNum, verseEndSymbol: false);
                                  List<String> words = verseText.split(' ');

                                  return [
                                    ...List.generate(words.length, (wIdx) {
                                      String word = words[wIdx]; 
                                      String wordKey = "${pageNum}_${surahNum}_${verseNum}_$wIdx";
                                      bool hasError = wrongWordsLog.containsKey(wordKey);
                                      String? errorType = wrongWordsLog[wordKey];

                                      return GestureDetector(
                                        onTap: () => _showErrorMenu(context, word, wordKey),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: hasError ? _getErrorColor(errorType) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            word, 
                                            style: TextStyle(
                                              fontFamily: 'Uthmanic',
                                              fontSize: 25, 
                                              fontWeight: FontWeight.bold,
                                              height: 1.7, 
                                              color: hasError ? Colors.white : const Color(0xff2c2212), 
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xffc2b091), width: 1.5),
                                          color: const Color(0xfff5ebd6),
                                        ),
                                        child: Text(
                                          verseNum.toString(), 
                                          style: const TextStyle(
                                            fontFamily: 'Uthmanic',
                                            fontSize: 11, 
                                            fontWeight: FontWeight.bold, 
                                            color: Color(0xff5c4d37),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ];
                                }).toList(),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorMenu(BuildContext context, String word, String wordKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xfff5f7fa),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 15),
                  
                  Text(
                    "تحديد نوع الخطأ للكلمة: \"$word\"", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff425c75)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  if (wrongWordsLog.containsKey(wordKey))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () { _removeError(wordKey); Navigator.pop(context); },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, color: Colors.blue),
                              SizedBox(width: 8),
                              Text("حذف الخطأ الحالي وإرجاع العلامة", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),

                  _buildErrorItem(context, wordKey, word, "1. خطأ حفظ صحح لنفسه", "حفظ_نفسه", widget.penaltyHifzSelf, Icons.replay_circle_filled_rounded, Colors.red, false),
                  _buildErrorItem(context, wordKey, word, "2. خطأ حفظ صحح له", "حفظ_له", widget.penaltyHifzCorrected, Icons.cancel_rounded, Colors.red, false),
                  
                  const SizedBox(height: 8),
                  
                  _buildErrorItem(context, wordKey, word, "3. خطأ تشكيل صحح بنفسه", "تشكيل_نفسه", widget.penaltyTashkeelSelf, Icons.text_fields_rounded, Colors.orange, false),
                  _buildErrorItem(context, wordKey, word, "4. خطأ تشكيل صحح له", "تشكيل_له", widget.penaltyTashkeelCorrected, Icons.spellcheck_rounded, Colors.orange, false),
                  
                  const SizedBox(height: 8),

                  _buildErrorItem(context, wordKey, word, "5. التجويد الرئيسي", "تجويد_رئيسي", widget.penaltyTajweedMain, Icons.g_translate_rounded, Colors.purple, false),
                  _buildErrorItem(context, wordKey, word, "6. التجويد الفرعي", "تجويد_فرعي", widget.penaltyTajweedSub, Icons.record_voice_over_rounded, Colors.purple, true),
                  
                  const SizedBox(height: 8),

                  _buildErrorItem(context, wordKey, word, "7. الوقف والابتداء خطأ", "وقف_خطأ", widget.penaltyWaqfWrong, Icons.pause_circle_filled_rounded, Colors.teal, false),
                  _buildErrorItem(context, wordKey, word, "8. الوقف والابتداء خطأ قبيح", "وقف_قبيح", widget.penaltyWaqfUgly, Icons.do_not_disturb_on_rounded, Colors.teal, false),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorItem(BuildContext context, String wordKey, String wordText, String title, String typeKey, double penalty, IconData icon, MaterialColor themeColor, bool isTajweedSub) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: themeColor.shade50,
          child: Icon(icon, color: themeColor.shade700, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: themeColor.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "- $penalty",
            style: TextStyle(color: themeColor.shade900, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        onTap: () {
          if (isTajweedSub) {
            Navigator.pop(context);
            _showTajweedSubInputDialog(context, wordKey, wordText, penalty);
          } else {
            String cleanName = title.substring(3).trim(); 
            // 🎯 تم الإصلاح هنا بـ شكل قطعي ومؤكد: نمرر wordText (الكلمة القرآنية الصافية) بدل الـ wordKey الأرقام!
            _addError(wordKey, wordText, cleanName, penalty);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showTajweedSubInputDialog(BuildContext context, String wordKey, String wordText, double penalty) {
    TextEditingController customRuleController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "تحديد حكم التجويد الفرعي للكلمة: \"$wordText\"",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff425c75)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("اكتب اسم حكم التجويد المخطأ فيه (مثال: مد متصل، إخفاء شفوي، إلخ):", style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 12),
              TextField(
                controller: customRuleController,
                autofocus: true,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: "اكتب الحكم هنا...",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.purple, width: 2)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                String typedRule = customRuleController.text.trim();
                if (typedRule.isEmpty) {
                  typedRule = "تجويد فرعي"; 
                }
                String finalErrorName = "تجويد فرعي: $typedRule";
                _addError(wordKey, wordText, finalErrorName, penalty);
                Navigator.pop(ctx);
              },
              child: const Text("تأكيد ورصد", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _addError(String wordKey, String wordText, String typeName, double penalty) {
    setState(() {
      if (wrongWordsLog.containsKey(wordKey)) _removeError(wordKey);
      wrongWordsLog[wordKey] = typeName;
      wrongWordsWithText[wordKey] = "$wordText -> ($typeName)"; 
      studentScore = (studentScore - penalty).clamp(0.0, 100.0);
    });
  }

  void _removeError(String wordKey) {
    String? type = wrongWordsLog[wordKey];
    double penalty = 0;
    if (type == "خطأ حفظ صحح لنفسه") penalty = widget.penaltyHifzSelf;
    if (type == "خطأ حفظ صحح له") penalty = widget.penaltyHifzCorrected;
    if (type == "خطأ تشكيل صحح بنفسه") penalty = widget.penaltyTashkeelSelf;
    if (type == "خطأ تشكيل صحح له") penalty = widget.penaltyTashkeelCorrected;
    if (type == "التجويد الرئيسي") penalty = widget.penaltyTajweedMain;
    if (type != null && type.startsWith("تجويد فرعي")) penalty = widget.penaltyTajweedSub;
    if (type == "الوقف والابتداء خطأ") penalty = widget.penaltyWaqfWrong;
    if (type == "الوقف والابتداء خطأ قبيح") penalty = widget.penaltyWaqfUgly;

    setState(() {
      wrongWordsLog.remove(wordKey);
      wrongWordsWithText.remove(wordKey);
      studentScore = (studentScore + penalty).clamp(0.0, 100.0);
    });
  }

  Color _getErrorColor(String? type) {
    if (type == "خطأ حفظ صحح لنفسه" || type == "خطأ حفظ صحح له") return Colors.red.shade700;
    if (type == "خطأ تشكيل صحح بنفسه" || type == "خطأ تشكيل صحح له") return Colors.orange.shade700;
    if (type != null && type.startsWith("التجويد")) return Colors.purple.shade700;
    if (type != null && type.startsWith("تجويد فرعي")) return Colors.purple.shade900; 
    return Colors.blue.shade800;
  }

  void _finishExamAndSave() async {
    _isTimerRunning = false;
    _examTimer?.cancel();

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.teal)));
    try {
      await FirebaseFirestore.instance.collection('exams_results').add({
        'student_id': widget.studentId,
        'student_name': widget.studentName,
        'score': double.parse(studentScore.toStringAsFixed(2)),
        'exam_date': Timestamp.now(),
        'elapsed_seconds': _elapsedSeconds,
        'duration_text': _formatDuration(_elapsedSeconds),
        'errors_details': wrongWordsWithText.values.toList(), 
      });
      if (!mounted) return;
      Navigator.pop(context); 
      Navigator.pop(context); 
      
      showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
          title: const Text("تم الانتهاء وحفظ الاختبار 🎉", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("بارك الله بجهدك يا بطل، علامة الطالب ${widget.studentName} النهائية هي:", textAlign: TextAlign.center),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "${studentScore.toStringAsFixed(2)} / 100", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.black54),
                  const SizedBox(width: 5),
                  Text("الوقت المستغرق: ${_formatDuration(_elapsedSeconds)}", style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("تم بإحسان", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ]
        )
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في الحفظ: $e")));
    }
  }
}