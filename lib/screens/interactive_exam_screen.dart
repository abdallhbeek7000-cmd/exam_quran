import 'dart:async';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; 
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
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  String _toArabicNumber(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String numStr = number.toString();
    for (int i = 0; i < english.length; i++) {
      numStr = numStr.replaceAll(english[i], arabic[i]);
    }
    return numStr;
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
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text("اختر السورة", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff425c75))),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, 
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: 114,
              itemBuilder: (context, index) {
                int surahNum = index + 1;
                return ListTile(
                  title: Text("$surahNum. سورة ${quran.getSurahNameArabic(surahNum)}", textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff425c75))),
                  trailing: const Icon(Icons.menu_book, size: 18, color: Color(0xffd4af37)),
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
      extendBodyBehindAppBar: true, // 💎 دمج الشريط العلوي مع الخلفية
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // شريط علوي زجاجي
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xff425c75).withOpacity(0.7),
                    const Color(0xff2a3d4f).withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1)),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("رصد الاختبار", style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
            Text("الطالب: ${widget.studentName}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade500, 
                  foregroundColor: Colors.white, 
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.teal.shade200, width: 1)),
                ),
                onPressed: _finishExamAndSave, 
                child: const Text("إنهاء وحفظ", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        // 💎 خلفية سائلة فخمة متدرجة
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [Color(0xffe8e1d5), Color(0xffc5b79e), Color(0xff9e8d71)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 💎 شريط التحكم الزجاجي (السورة، الصفحات، المؤقت)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xff425c75)), onPressed: currentPage > widget.startPage ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null),
                    
                    GestureDetector(
                      onTap: _showSurahSelectionDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.8))),
                        child: Text("سورة ${_getSurahNamesInPage(currentPage)} | صـ $currentPage 🔽", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff425c75), fontSize: 13)),
                      ),
                    ),

                    InkWell(
                      onTap: _toggleTimer,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isTimerRunning ? Colors.white.withOpacity(0.6) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: _isTimerRunning ? Colors.amber.shade300 : Colors.red.shade300, width: 1.5)
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isTimerRunning ? Icons.timer_outlined : Icons.pause_circle_filled_rounded, size: 16, color: _isTimerRunning ? Colors.amber.shade900 : Colors.red.shade700),
                            const SizedBox(width: 5),
                            Text(_formatDuration(_elapsedSeconds), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: _isTimerRunning ? Colors.amber.shade900 : Colors.red.shade800)),
                          ],
                        ),
                      ),
                    ),

                    IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xff425c75)), onPressed: currentPage < widget.endPage ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null),
                  ],
                ),
              ),

              // 💎 بطاقة المصحف الزجاجية الكبرى
              Expanded(
                child: PageView.builder(
                  physics: const BouncingScrollPhysics(),
                  controller: _pageController,
                  itemCount: allowedPagesCount,
                  onPageChanged: (idx) => setState(() => currentPage = widget.startPage + idx),
                  itemBuilder: (context, pageIndex) {
                    int pageNum = widget.startPage + pageIndex;
                    Map<int, List<int>> pageData = _getSurahAndVersesForPage(pageNum);
                    List<InlineSpan> pageTextSpans = [];

                    pageData.forEach((surahNum, verses) {
                      if (verses.isNotEmpty && verses.first == 1) {
                        if (pageTextSpans.isNotEmpty) pageTextSpans.add(const TextSpan(text: "\n\n"));
                        pageTextSpans.add(
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              width: 420, 
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [const Color(0xffe6d5b8).withOpacity(0.9), const Color(0xffd4af37).withOpacity(0.5)]),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                                boxShadow: [BoxShadow(color: const Color(0xffd4af37).withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
                              ),
                              child: Text(
                                "سُورَةُ ${quran.getSurahNameArabic(surahNum)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontFamily: 'Uthmanic', fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xff4a3b22)),
                              ),
                            ),
                          ),
                        );
                        pageTextSpans.add(const TextSpan(text: "\n"));
                        
                        if (surahNum != 1 && surahNum != 9) {
                          pageTextSpans.add(
                            TextSpan(
                              text: "${quran.basmala}\n",
                              style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 24, color: Color(0xff2c2212), height: 1.8),
                            )
                          );
                        }
                      }

                      for (int verseNum in verses) {
                        String verseText = quran.getVerse(surahNum, verseNum, verseEndSymbol: false);
                        List<String> words = verseText.split(' ');

                        for (int wIdx = 0; wIdx < words.length; wIdx++) {
                          String word = words[wIdx]; 
                          String wordKey = "${pageNum}_${surahNum}_${verseNum}_$wIdx";
                          bool hasError = wrongWordsLog.containsKey(wordKey);
                          String? errorType = wrongWordsLog[wordKey];

                          pageTextSpans.add(
                            TextSpan(
                              text: "$word ", 
                              style: TextStyle(
                                fontFamily: 'Uthmanic',
                                fontSize: 25, 
                                fontWeight: FontWeight.bold,
                                height: 1.8, 
                                color: hasError ? Colors.white : const Color(0xff1a140a), 
                                backgroundColor: hasError ? _getErrorColor(errorType) : Colors.transparent,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () => _showErrorMenu(context, word, wordKey),
                            ),
                          );
                        }
                        
                        pageTextSpans.add(
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Text(
                                    "\u06DD", 
                                    style: TextStyle(fontFamily: 'Uthmanic', fontSize: 34, color: Color(0xffbfa473), height: 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3), 
                                    child: Text(
                                      _toArabicNumber(verseNum),
                                      style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff5c4d37), height: 1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        pageTextSpans.add(const TextSpan(text: " ")); 
                      }
                    });

                    return Container(
                      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // 💎 تغبيش عالي لزجاج قوي
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.65), Colors.white.withOpacity(0.45)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5), 
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.contain, 
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 450, minHeight: 720),
                                  child: RichText(
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.justify, 
                                    text: TextSpan(children: pageTextSpans),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorMenu(BuildContext context, String word, String wordKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 💎 جعل الخلفية شفافة لدعم الزجاج
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // 💎 تأثير الزجاج للقائمة السفلية
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85), // لون أبيض شبه شفاف
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.9), width: 1.5)),
              ),
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(10))),
                      const SizedBox(height: 20),
                      Text("تحديد الخطأ للكلمة: \"$word\"", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xff425c75)), textAlign: TextAlign.center),
                      const SizedBox(height: 15),
                      const Divider(height: 1, color: Colors.black12),
                      const SizedBox(height: 15),

                      if (wrongWordsLog.containsKey(wordKey))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: InkWell(
                            onTap: () { _removeError(wordKey); Navigator.pop(context); },
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.refresh, color: Colors.blueAccent), SizedBox(width: 8), Text("حذف الخطأ الحالي وإرجاع العلامة", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15))]),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorItem(BuildContext context, String wordKey, String wordText, String title, String typeKey, double penalty, IconData icon, MaterialColor themeColor, bool isTajweedSub) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        border: Border.all(color: themeColor.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: themeColor.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: themeColor.shade700, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff2c3e50))),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
          decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), 
          child: Text("- $penalty", style: TextStyle(color: themeColor.shade900, fontWeight: FontWeight.w900, fontSize: 14))
        ),
        onTap: () {
          if (isTajweedSub) {
            Navigator.pop(context);
            _showTajweedSubInputDialog(context, wordKey, wordText, penalty);
          } else {
            String cleanName = title.substring(3).trim(); 
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
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("تحديد حكم التجويد: \"$wordText\"", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff425c75))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("اكتب اسم حكم التجويد المخطأ فيه:", style: TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 15),
              TextField(
                controller: customRuleController,
                autofocus: true,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.purple.withOpacity(0.05),
                  hintText: "مثال: مد متصل...", 
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), 
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.purple.shade300, width: 2))
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600, 
                foregroundColor: Colors.white, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
              ),
              onPressed: () {
                String typedRule = customRuleController.text.trim();
                if (typedRule.isEmpty) typedRule = "تجويد فرعي"; 
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
    if (type == "خطأ حفظ صحح لنفسه" || type == "خطأ حفظ صحح له") return Colors.red.shade700.withOpacity(0.9);
    if (type == "خطأ تشكيل صحح بنفسه" || type == "خطأ تشكيل صحح له") return Colors.orange.shade800.withOpacity(0.9);
    if (type != null && type.startsWith("التجويد")) return Colors.purple.shade700.withOpacity(0.9);
    if (type != null && type.startsWith("تجويد فرعي")) return Colors.purple.shade900.withOpacity(0.9); 
    return Colors.blue.shade800.withOpacity(0.9);
  }

  void _finishExamAndSave() async {
    _isTimerRunning = false;
    _examTimer?.cancel();
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.teal) // تمييز التحميل
      )
    );
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
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
          title: const Text("تم الانتهاء وحفظ الاختبار 🎉", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal, fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("بارك الله بجهدك يا بطل، علامة الطالب ${widget.studentName} النهائية هي:", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), 
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
                ), 
                child: Text("${studentScore.toStringAsFixed(2)} / 100", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: Colors.black54), 
                  const SizedBox(width: 8), 
                  Text("الوقت المستغرق: ${_formatDuration(_elapsedSeconds)}", style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold))
                ]
              )
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text("تم بإحسان", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal))
              ),
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