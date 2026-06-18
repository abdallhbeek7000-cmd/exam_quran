import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class ReadOnlyMushafScreen extends StatefulWidget {
  final String studentName;
  final int startPage;
  final int endPage;
  final List<dynamic> errorsList;

  const ReadOnlyMushafScreen({
    super.key,
    required this.studentName,
    required this.startPage,
    required this.endPage,
    required this.errorsList,
  });

  @override
  State<ReadOnlyMushafScreen> createState() => _ReadOnlyMushafScreenState();
}

class _ReadOnlyMushafScreenState extends State<ReadOnlyMushafScreen> {
  late PageController _pageController;
  int currentPage = 1;
  
  Map<int, Map<int, List<int>>> _cachedPagesData = {};

  @override
  void initState() {
    super.initState();
    currentPage = widget.startPage;
    _pageController = PageController(initialPage: 0);
    _precomputePagesData(); 
  }

  @override
  void dispose() {
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

  String? _matchError(String wordKey) {
    for (var err in widget.errorsList) {
      String errStr = err.toString();
      if (errStr.contains("key: $wordKey")) {
        return errStr;
      }
    }
    return null; 
  }

  Color _getErrorColor(String errorStr) {
    if (errorStr.contains("حفظ")) return Colors.red.shade600;
    if (errorStr.contains("تشكيل")) return Colors.orange.shade600;
    if (errorStr.contains("تجويد")) return Colors.purple.shade600;
    if (errorStr.contains("وقف")) return Colors.teal.shade600;
    return Colors.red.shade600; 
  }

  String _extractValue(String source, String key) {
    RegExp regExp = RegExp(key + r':\s*(.*?)(?:,|})');
    var match = regExp.firstMatch(source);
    return match?.group(1)?.trim() ?? '';
  }

  List<Map<String, String>> _getParsedErrors() {
    List<Map<String, String>> parsed = [];
    for (var err in widget.errorsList) {
      String errStr = err.toString();
      String word = _extractValue(errStr, 'word');
      String type = _extractValue(errStr, 'type');
      String page = _extractValue(errStr, 'page');
      if (word.isNotEmpty) {
        parsed.add({"word": word, "type": type, "page": page});
      }
    }
    return parsed;
  }

  void _showDetailedErrorsBottomSheet() {
    List<Map<String, String>> parsedErrors = _getParsedErrors();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75, 
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 15, left: 20, right: 20),
          child: Column(
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("التفاصيل الدقيقة للأخطاء", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87, fontFamily: 'Cairo')),
              const SizedBox(height: 5),
              Text("إجمالي الأخطاء المرصودة: ${parsedErrors.length}", style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14)),
              const SizedBox(height: 15),
              const Divider(),
              Expanded(
                child: parsedErrors.isEmpty
                    ? const Center(
                        child: Text("لا يوجد أخطاء مسجلة، قراءة ممتازة! 🎉", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.teal)),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: parsedErrors.length,
                        itemBuilder: (context, index) {
                          var error = parsedErrors[index];
                          Color errColor = _getErrorColor(error['type']!);
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: errColor.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: errColor.withOpacity(0.2)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: errColor.withOpacity(0.15), shape: BoxShape.circle),
                                child: Icon(Icons.error_outline_rounded, color: errColor, size: 22),
                              ),
                              title: Text(error['word']!, style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 24, fontWeight: FontWeight.bold)),
                              subtitle: Text(error['type']!, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("الصفحة", style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                  Text(error['page']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                ],
                              ),
                              onTap: () {
                                int targetPage = int.tryParse(error['page']!) ?? currentPage;
                                if (targetPage >= widget.startPage && targetPage <= widget.endPage) {
                                  Navigator.pop(context); 
                                  _pageController.jumpToPage(targetPage - widget.startPage);
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
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
            const Text("مراجعة أخطاء الاختبار", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500, fontFamily: 'Cairo')),
            Text("الطالب: ${widget.studentName}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Cairo')),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade50,
                foregroundColor: Colors.teal.shade800,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: Colors.teal.shade200), // 🎯 تم إصلاح الإطار هنا
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text("تفاصيل الأخطاء", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
              onPressed: _showDetailedErrorsBottomSheet,
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Text(
                      "سورة ${_getSurahNamesInPage(currentPage)} | صـ $currentPage",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800, fontSize: 13, fontFamily: 'Cairo'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
                    onPressed: currentPage < widget.endPage ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
                  ),
                ],
              ),
            ),

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
                        
                        String? matchedError = _matchError(wordKey);
                        bool hasError = matchedError != null;

                        bool isLafzJalalah = word.contains('اللَّه') || word.contains('اللّه') || word.contains('لِلَّه') || word.contains('ٱللَّه');

                        pageTextSpans.add(
                          TextSpan(
                            text: "$word ",
                            style: TextStyle(
                              fontFamily: 'Uthmanic',
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              height: 1.9,
                              color: hasError ? Colors.white : (isLafzJalalah ? Colors.red.shade700 : Colors.black87),
                              backgroundColor: hasError ? _getErrorColor(matchedError) : Colors.transparent,
                            ),
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
            
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(Colors.red.shade600, "حفظ"),
          _legendItem(Colors.orange.shade600, "تشكيل"),
          _legendItem(Colors.purple.shade600, "تجويد"),
          _legendItem(Colors.teal.shade600, "وقف"),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Cairo')),
      ],
    );
  }
}