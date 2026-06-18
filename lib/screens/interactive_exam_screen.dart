import 'dart:async';
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

  // ⚡ ذاكرة كاش لحل مشكلة التدقير في التقليب
  Map<int, Map<int, List<int>>> _cachedPagesData = {};

  Timer? _examTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = true;

  @override
  void initState() {
    super.initState();
    currentPage = widget.startPage;
    _pageController = PageController(initialPage: 0);
    _precomputePagesData(); 
    _startTimer();
  }

  @override
  void dispose() {
    _examTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _precomputePagesData() {
    for (int surah = 1; surah <= 114; surah++) {
      int totalVerses = quran.getVerseCount(surah);
      for (int verse = 1; verse <= totalVerses; verse++) {
        int p = quran.getPageNumber(surah, verse);
        if (p >= widget.startPage && p <= widget.endPage) {
          _cachedPagesData.putIfAbsent(p, () => {});
          _cachedPagesData[p]!.putIfAbsent(surah, () => []);
          _cachedPagesData[p]![surah]!.add(verse);
        }
      }
    }
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

  String _getSurahNamesInPage(int pageNum) {
    Map<int, List<int>> pageData = _cachedPagesData[pageNum] ?? {};
    return pageData.keys.map((num) => quran.getSurahNameArabic(num)).join(' - ');
  }

  void _showSurahSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("اختر السورة", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: 114,
              itemBuilder: (context, index) {
                int surahNum = index + 1;
                return ListTile(
                  title: Text("$surahNum. سورة ${quran.getSurahNameArabic(surahNum)}", textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  trailing: const Icon(Icons.menu_book, size: 18, color: Colors.grey),
                  onTap: () {
                    int targetPage = quran.getPageNumber(surahNum, 1);
                    Navigator.pop(context);
                    if (targetPage >= widget.startPage && targetPage <= widget.endPage) {
                      _pageController.jumpToPage(targetPage - widget.startPage);
                    }
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
      backgroundColor: const Color(0xffFDFDFD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("رصد الاختبار", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
            Text("الطالب: ${widget.studentName}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _finishExamAndSave,
              child: const Text("إنهاء وحفظ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // شريط التحكم العلوي
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.black54),
                    onPressed: currentPage > widget.startPage ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
                  ),
                  GestureDetector(
                    onTap: _showSurahSelectionDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        "سورة ${_getSurahNamesInPage(currentPage)} | صـ $currentPage 🔽",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _toggleTimer,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isTimerRunning ? Colors.grey.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _isTimerRunning ? Colors.grey.shade300 : Colors.red.shade200, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isTimerRunning ? Icons.timer_outlined : Icons.pause_circle_filled_rounded, size: 16, color: _isTimerRunning ? Colors.black54 : Colors.red.shade700),
                          const SizedBox(width: 5),
                          Text(
                            _formatDuration(_elapsedSeconds),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: _isTimerRunning ? Colors.black87 : Colors.red.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
                    onPressed: currentPage < widget.endPage ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
                  ),
                ],
              ),
            ),

            // عرض المصحف الشريف بسلاسة تامة
            Expanded(
              child: PageView.builder(
                physics: const BouncingScrollPhysics(),
                controller: _pageController,
                itemCount: allowedPagesCount,
                onPageChanged: (idx) => setState(() => currentPage = widget.startPage + idx),
                itemBuilder: (context, pageIndex) {
                  int pageNum = widget.startPage + pageIndex;
                  Map<int, List<int>> pageData = _cachedPagesData[pageNum] ?? {};
                  List<InlineSpan> pageTextSpans = [];

                  pageData.forEach((surahNum, verses) {
                    if (verses.isNotEmpty && verses.first == 1) {
                      if (pageTextSpans.isNotEmpty) pageTextSpans.add(const TextSpan(text: "\n\n"));

                      pageTextSpans.add(
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                            ),
                            child: Text(
                              "سُورَةُ ${quran.getSurahNameArabic(surahNum)}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontFamily: 'Uthmanic', fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87),
                            ),
                          ),
                        ),
                      );
                      pageTextSpans.add(const TextSpan(text: "\n"));

                      if (surahNum != 1 && surahNum != 9) {
                        pageTextSpans.add(
                          TextSpan(
                            text: "${quran.basmala}\n",
                            style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 24, color: Colors.black87, height: 2.0),
                          ),
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

                        bool isLafzJalalah = word.contains('اللَّه') ||
                            word.contains('اللّه') ||
                            word.contains('لِلَّه') ||
                            word.contains('ٱللَّه');

                        pageTextSpans.add(
                          TextSpan(
                            text: "$word ",
                            style: TextStyle(
                              fontFamily: 'Uthmanic',
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              height: 1.9,
                              color: hasError
                                  ? Colors.white
                                  : (isLafzJalalah ? Colors.red.shade700 : Colors.black87),
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
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Text(
                                  "\u06DD",
                                  style: TextStyle(fontFamily: 'Uthmanic', fontSize: 34, color: Colors.black45, height: 1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    _toArabicNumber(verseNum),
                                    style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87, height: 1),
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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: RichText(
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                          text: TextSpan(children: pageTextSpans),
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
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text("تحديد الخطأ للكلمة: \"$word\"", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87), textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 15),

                  if (wrongWordsLog.containsKey(wordKey))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: InkWell(
                        onTap: () { _removeError(wordKey); Navigator.pop(context); },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.refresh, color: Colors.blue.shade700), const SizedBox(width: 8), Text("حذف الخطأ الحالي وإرجاع العلامة", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 15))]),
                        ),
                      ),
                    ),

                  _buildErrorItem(context, wordKey, word, "1. خطأ حفظ صحح لنفسه", "حفظ_نفسه", widget.penaltyHifzSelf, Icons.replay_circle_filled_rounded, Colors.red, false),
                  _buildErrorItem(context, wordKey, word, "2. خطأ حفظ صحح له", "حفظ_له", widget.penaltyHifzCorrected, Icons.cancel_rounded, Colors.red, false),
                  const SizedBox(height: 8),
                  _buildErrorItem(context, wordKey, word, "3. خطأ تشكيل صحح بنفسه", "تشكيل_نفسه", widget.penaltyTashkeelSelf, Icons.text_fields_rounded, Colors.orange, false),
                  _buildErrorItem(context, wordKey, word, "4. خطأ تشكيل صحح له", "تشكيل_له", widget.penaltyTashkeelCorrected, Icons.spellcheck_rounded, Colors.orange, false),
                  const SizedBox(height: 8),
                  _buildErrorItem(context, wordKey, word, "5. التجويد الرئيسي", "تجويد_رئيسي", widget.penaltyTajweedMain, Icons.g_translate_rounded, Colors.purple, false, isTajweedMain: true),
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

  Widget _buildErrorItem(BuildContext context, String wordKey, String wordText, String title, String typeKey, double penalty, IconData icon, MaterialColor themeColor, bool isTajweedSub, {bool isTajweedMain = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: themeColor.shade50, shape: BoxShape.circle),
          child: Icon(icon, color: themeColor.shade600, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: themeColor.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text("- $penalty", style: TextStyle(color: themeColor.shade800, fontWeight: FontWeight.bold, fontSize: 14))
        ),
        onTap: () {
          if (isTajweedMain) {
            Navigator.pop(context); 
            _showTajweedMainSelectionDialog(context, wordKey, wordText, penalty); 
          } else if (isTajweedSub) {
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

  void _showTajweedMainSelectionDialog(BuildContext context, String wordKey, String wordText, double penalty) {
    final List<String> mainTajweedRules = [
      "الراء",
      "المد",
      "القلقلة",
      "الهمس",
      "الميم والنون المشددة",
      "الميم والنون الساكنة والتنوين"
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("خطأ تجويد رئيسي في: \"$wordText\"", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mainTajweedRules.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    title: Text(mainTajweedRules[index], textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () {
                      _addError(wordKey, wordText, "تجويد رئيسي: ${mainTajweedRules[index]}", penalty);
                      Navigator.pop(ctx);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showTajweedSubInputDialog(BuildContext context, String wordKey, String wordText, double penalty) {
    TextEditingController customRuleController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("تحديد حكم التجويد: \"$wordText\"", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                    fillColor: Colors.grey.shade100,
                    hintText: "مثال: مد متصل...",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.purple.shade300, width: 1))
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
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      
      wrongWordsWithText[wordKey] = {
        "key": wordKey,
        "word": wordText,
        "type": typeName,
        "page": currentPage,
      }.toString(); 
      
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
    if (type != null && type.startsWith("تجويد رئيسي")) penalty = widget.penaltyTajweedMain;
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
    if (type == "خطأ حفظ صحح لنفسه" || type == "خطأ حفظ صحح له") return Colors.red.shade600;
    if (type == "خطأ تشكيل صحح بنفسه" || type == "خطأ تشكيل صحح له") return Colors.orange.shade600;
    if (type != null && type.startsWith("تجويد رئيسي")) return Colors.purple.shade600;
    if (type != null && type.startsWith("تجويد فرعي")) return Colors.purple.shade800;
    return Colors.blue.shade600;
  }

  void _finishExamAndSave() async {
    _isTimerRunning = false;
    _examTimer?.cancel();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.teal)
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
        // 🚀 إضافة الحقول المخصصة لتكليف الاختبار ليقرأها المصحف الخاص بالنتائج لاحقاً
        'start_page': widget.startPage,
        'end_page': widget.endPage,
      });
      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("تم الانتهاء وحفظ الاختبار 🎉", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("بارك الله بجهدك يا بطل، علامة الطالب ${widget.studentName} النهائية هي:", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200)
                ),
                child: Text(
                    "${studentScore.toStringAsFixed(2)} / 100",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal.shade700)
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("العودة للرئيسية"),
            )
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء الحفظ: $e")));
    }
  }
}