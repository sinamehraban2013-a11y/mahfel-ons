
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

// ==========================================
// تنظیمات گوگل درایو و اسکریپت
// ==========================================
const String scriptApiUrl =
    'https://script.google.com/macros/s/AKfycbwBLyDbJu78M_nxaZtfcfFtd6DSMp6yl3Lu2lPOPwimuDynqGN8cTvZr4JpN3eJhxGA/exec';
const String ketabFolderId = '1R2iM-PbRDY9gp7LPBGcKFBO9B5rsPt71';
const String maghalehFolderId = '1SJ1dS0XAnXwr4WGQPwlcpUJCFDy_T2Ir';
// ==========================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MahfelOnsApp());
}

class DriveItem {
  final String id;
  final String name;

  DriveItem({required this.id, required this.name});

  factory DriveItem.fromJson(Map<String, dynamic> json) {
    return DriveItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class MahfelOnsApp extends StatelessWidget {
  const MahfelOnsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محفل اُنس',
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B2B3A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B2B3A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2B3A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/mahfel_ons_animation.gif',
              width: 220,
              height: 220,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.menu_book_rounded,
                size: 100,
                color: Color(0xFF1ABC9C),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'محفلِ اُنس',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'تلاقیِ آگاهی و آرامش',
              style: TextStyle(
                color: Color(0xFF1ABC9C),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final File file;
  final String title;

  const PdfViewerScreen({super.key, required this.file, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SfPdfViewer.file(
        file,
        canShowScrollHead: true,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  List<DriveItem> _books = [];
  List<DriveItem> _articles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDriveFiles();
  }

  Future<void> _fetchDriveFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // استفاده از متد استاندارد Uri برای ساخت آدرس با پارامتر
      final booksUri = Uri.parse(scriptApiUrl).replace(queryParameters: {'folderId': ketabFolderId});
      final articlesUri = Uri.parse(scriptApiUrl).replace(queryParameters: {'folderId': maghalehFolderId});

      final booksRes = await http.get(booksUri);
      final articlesRes = await http.get(articlesUri);

      if (booksRes.statusCode == 200 && articlesRes.statusCode == 200) {
        final List<dynamic> booksJson = json.decode(booksRes.body);
        final List<dynamic> articlesJson = json.decode(articlesRes.body);

        setState(() {
          _books = booksJson.map((e) => DriveItem.fromJson(e)).toList();
          _articles = articlesJson.map((e) => DriveItem.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'خطا در ارتباط با سرور ابری (کد: ${booksRes.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطای اتصال به اینترنت';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAndOpen(DriveItem doc) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color(0xFF133B4F),
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF1ABC9C)),
            SizedBox(width: 20),
            Expanded(
              child: Text('در حال دریافت کتاب...', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );

    final String downloadUrl = 'https://drive.google.com/uc?export=download&id=${doc.id}';

    try {
      final response = await http.get(Uri.parse(downloadUrl));
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${doc.id}.pdf');
        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfViewerScreen(file: file, title: doc.name)),
        );
      } else {
        await _launchExternal(downloadUrl);
      }
    } catch (_) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      await _launchExternal(downloadUrl);
    }
  }

  Future<void> _launchExternal(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F3244),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1ABC9C)),
                  SizedBox(width: 8),
                  Text(
                    'درباره ما',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'محفلِ اُنس؛ تلاقیِ آگاهی و آرامش\n\n'
                    'در هیاهوی جهانِ مدرن، «محفلِ اُنس» دعوتی است به بازگشت؛ بازگشتی آگاهانه به سرچشمه‌های وحیانی و اصیل. ما در این مجموعه برآنیم تا با نگاهی برآمده از پژوهش‌های دقیقِ متن‌شناختی و هرمنوتیکی، پلی میانِ میراثِ غنیِ دینی و نیازهای مخاطبِ امروز برقرار کنیم.\n\n'
                    'دغدغه‌ی ما در «محفلِ اُنس»، فراتر از انتقالِ صرفِ داده‌هاست. ما با رویکردی متمرکز بر «رحمانیت»، تلاش کرده‌ایم بستری را فراهم آوریم که در آن، مفاهیم عمیقِ عاشورایی و کلامِ وحی، نه به عنوانِ متونی دور، بلکه به مثابه راهکارهایی زنده و کاربردی برای تعالیِ فردی و اجتماعی درک شوند.\n\n'
                    'این اپلیکیشن، حاصلِ تلاشی مستمر برای ساختارمند کردنِ فرآیندِ «اُنس» با کلام است؛ جایی که دقتِ علمی با لطافتِ معنوی گره می‌خورد تا تجربه‌ای متفاوت از تعامل با متونِ قدسی را برای شما رقم بزند. امیدواریم «محفلِ اُنس»، چراغِ راهی در مسیرِ جستجویِ معنا و آرامشِ پایدار باشد.\n\n'
                    'با احترام،\nتیمِ توسعه و پژوهشِ محفلِ اُنس',
                    style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.8),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('بستن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F3244),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ارسال نظر و انتقاد',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: feedbackController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'متن نظر خود را بنویسید...',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1ABC9C))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1ABC9C)),
            onPressed: () async {
              final String text = feedbackController.text.trim();
              if (text.isNotEmpty) {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'm_khozani@yahoo.com',
                  query: 'subject=${Uri.encodeComponent('نظر کاربر اپلیکیشن محفل اُنس')}&body=${Uri.encodeComponent(text)}',
                );
                Navigator.pop(ctx);
                await launchUrl(emailLaunchUri);
              }
            },
            child: const Text('ارسال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showContactUsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF133B4F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ارتباط با ما',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.language, color: Color(0xFF1ABC9C), size: 28),
              title: const Text('پایگاه اینترنتی رسمی', style: TextStyle(color: Colors.white)),
              subtitle: const Text('www.shiravi.org', style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                _launchExternal('https://www.shiravi.org');
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.send_rounded, color: Color(0xFF1ABC9C), size: 28),
              title: const Text('کانال رسمی در پیام‌رسان ایتا', style: TextStyle(color: Colors.white)),
              subtitle: const Text('@shiravi_ir', style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                _launchExternal('https://eitaa.com/shiravi_ir');
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.psychology_alt_rounded, color: Color(0xFF1ABC9C), size: 28),
              title: const Text('پاسخ به پرسش‌های سخت', style: TextStyle(color: Colors.white)),
              subtitle: const Text('گروه پرسش و پاسخ در پیام‌رسان بله', style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                _launchExternal('https://ble.ir/join/NGMyZGI5OT');
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.email_rounded, color: Color(0xFF1ABC9C), size: 28),
              title: const Text('ارسال نظر و انتقاد', style: TextStyle(color: Colors.white)),
              subtitle: const Text('پیام شما مستقیماً به استاد می‌رسد', style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(ctx);
                _showFeedbackDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if (_selectedIndex == 0) return 'کتب در محفل انس';
    if (_selectedIndex == 1) return 'مقالات در محفل انس';
    return 'تست خودارزیابی MBTI';
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _selectedIndex == 0 ? _books : _articles;
    final filteredList = currentList.where((doc) {
      return doc.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: (_isSearching && _selectedIndex != 2)
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'جستجو در عناوین...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
              )
            : Text(
                _getAppBarTitle(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
        centerTitle: true,
        actions: [
          if (_selectedIndex != 2)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF133B4F),
            onSelected: (val) {
              if (val == 'about') _showAboutUsDialog();
              if (val == 'contact') _showContactUsModal();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF1ABC9C), size: 20),
                    SizedBox(width: 10),
                    Text('درباره ما', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(Icons.contact_support_outlined, color: Color(0xFF1ABC9C), size: 20),
                    SizedBox(width: 10),
                    Text('ارتباط با ما', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _selectedIndex == 2
          ? const MbtiQuizScreen()
          : _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF1ABC9C)),
                      SizedBox(height: 16),
                      Text('در حال بارگذاری لیست از فضای ابری...',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 64),
                          const SizedBox(height: 16),
                          Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1ABC9C)),
                            onPressed: _fetchDriveFiles,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text('تلاش مجدد', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF1ABC9C),
                      backgroundColor: const Color(0xFF133B4F),
                      onRefresh: _fetchDriveFiles,
                      child: filteredList.isEmpty
                          ? const Center(
                              child: Text('موردی یافت نشد.',
                                  style: TextStyle(color: Colors.white54, fontSize: 16)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final doc = filteredList[index];
                                return Card(
                                  color: const Color(0xFF133B4F),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1ABC9C).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _selectedIndex == 0 ? Icons.menu_book_rounded : Icons.article_rounded,
                                        color: const Color(0xFF1ABC9C),
                                        size: 26,
                                      ),
                                    ),
                                    title: Text(
                                      doc.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chrome_reader_mode_outlined,
                                      color: Color(0xFF1ABC9C),
                                      size: 24,
                                    ),
                                    onTap: () => _downloadAndOpen(doc),
                                  ),
                                );
                              },
                            ),
                    ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              _searchQuery = '';
              _isSearching = false;
              _searchController.clear();
            });
          },
          backgroundColor: const Color(0xFF0B2B3A),
          selectedItemColor: const Color(0xFF1ABC9C),
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'کتاب‌ها',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_rounded),
              label: 'مقالات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_rounded),
              label: 'تست خودارزیابی',
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// صفحه و منطق تست شخصیت‌شناسی MBTI
// ==========================================

class MbtiQuestion {
  final String title;
  final String optA;
  final String optB;
  final String typeA;
  final String typeB;

  const MbtiQuestion({
    required this.title,
    required this.optA,
    required this.optB,
    required this.typeA,
    required this.typeB,
  });
}

class MbtiQuizScreen extends StatefulWidget {
  const MbtiQuizScreen({super.key});

  @override
  State<MbtiQuizScreen> createState() => _MbtiQuizScreenState();
}

class _MbtiQuizScreenState extends State<MbtiQuizScreen> {
  final Map<int, String> _answers = {};
  bool _showResult = false;
  String _calculatedType = '';

  static const List<MbtiQuestion> questions = [
    // بخش اول: E یا I
    MbtiQuestion(title: 'بخش اول: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۱', optA: 'بعد از یک مهمانی شلوغ، احساس سرزندگی می‌کنم', optB: 'بعد از یک مهمانی شلوغ، احساس خستگی می‌کنم', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش اول: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۲', optA: 'ترجیح می‌دهم در گروه فکر کنم و حرف بزنم', optB: 'ترجیح می‌دهم اول تنها فکر کنم، بعد بگویم', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش اول: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۳', optA: 'دوستان زیادی دارم و راحت آشنا می‌شوم', optB: 'دوستان کمی دارم اما روابطم عمیق است', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش اول: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۴', optA: 'سکوت در جمع برایم ناراحت‌کننده است', optB: 'سکوت در جمع برایم طبیعی و راحت است', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش اول: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۵', optA: 'وقتی تنها هستم، دنبال کاری برای انجام دادن می‌گردم', optB: 'وقتی تنها هستم، از آن لذت می‌برم', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش اول: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۶', optA: 'در جمع انرژی می‌گیرم', optB: 'در خلوت انرژی می‌گیرم', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش اول: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۷', optA: 'ترجیح می‌دهم با تلفن صحبت کنم', optB: 'ترجیح می‌دهم پیام بدهم', typeA: 'E', typeB: 'I'),
    MbtiQuestion(title: 'بخش اول: برون‌گرایی (E) یا درون‌گرایی (I) - سوال ۸', optA: 'اغلب قبل از فکر کردن حرف می‌زنم', optB: 'اغلب قبل از حرف زدن فکر می‌کنم', typeA: 'E', typeB: 'I'),

    // بخش دوم: S یا N
    MbtiQuestion(title: 'بخش دوم: حسی (S) یا شهودی (N) - سوال ۱', optA: 'به جزئیات و واقعیت‌های ملموس توجه می‌کنم', optB: 'به الگوها و معناهای پنهان توجه می‌کنم', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش دوم: حسی (S) یا شهودی (N) - سوال ۲', optA: 'ترجیح می‌دهم دستورالعمل گام‌به‌گام داشته باشم', optB: 'ترجیح می‌دهم کلیت کار را بفهمم و خودم جزئیات را پر کنم', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش دوم: حسی (S) یا شهودی (N) - سوال ۳', optA: 'به تجربه‌ی عملی بیشتر از نظریه اعتماد دارم', optB: 'ایده‌های جدید و نظریه‌ها برایم جذاب‌اند', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش دوم: حسی (S) یا شهودی (N) - سوال ۴', optA: '«واقع‌بین» بودن برایم مهم است', optB: '«خلاق» بودن برایم مهم است', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش دوم: حسی (S) یا شهودی (N) - سوال ۵', optA: 'از روش‌های آزموده‌شده استفاده می‌کنم', optB: 'دنبال راه‌های جدید می‌گردم', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش دوم: حسی (S) یا شهودی (N) - سوال ۶', optA: 'حال حاضر برایم مهم‌تر از آینده است', optB: 'آینده و امکانات برایم جذاب‌تر از حال است', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش دوم: حسی (S) یا شهودی (N) - سوال ۷', optA: 'وقتی چیزی می‌خوانم، به کلمات دقیق توجه می‌کنم', optB: 'وقتی چیزی می‌خوانم، دنبال معنای کلی می‌گردم', typeA: 'S', typeB: 'N'),
    MbtiQuestion(title: 'بخش دوم: حسی (S) یا شهودی (N) - سوال ۸', optA: 'از کارهای دقیق و تکراری خسته نمی‌شوم', optB: 'کارهای تکراری زود خسته‌ام می‌کنند', typeA: 'S', typeB: 'N'),

    // بخش سوم: T یا F
    MbtiQuestion(title: 'بخش سوم: تفکری (T) یا احساسی (F) - سوال ۱', optA: 'در تصمیم‌گیری، منطق و داده برایم اولویت دارد', optB: 'در تصمیم‌گیری، احساسات و ارزش‌ها برایم اولویت دارد', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش سوم: تفکری (T) یا احساسی (F) - سوال ۲', optA: 'انتقاد صادقانه را به تعریف مؤدبانه ترجیح می‌دهم', optB: 'انتقاد، حتی اگر درست باشد، اگر بی‌ملاحظه باشد آزارم می‌دهد', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش سوم: تفکری (T) یا احساسی (F) - سوال ۳', optA: 'در تعارض، دنبال راه‌حل منطقی می‌گردم', optB: 'در تعارض، اول می‌خواهم احساسم شنیده شود', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش سوم: تفکری (T) یا احساسی (F) - سوال ۴', optA: '«عادلانه» بودن برایم مهم‌تر از «مهربانانه» بودن است', optB: '«مهربانانه» بودن برایم مهم‌تر از «عادلانه» بودن است', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش سوم: تفکری (T) یا احساسی (F) - سوال ۵', optA: 'می‌توانم تصمیم سختی بگیرم بدون اینکه احساساتم مانع شود', optB: 'تصمیم‌های سخت که به کسی آسیب می‌زند برایم دشوار است', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش سوم: تفکری (T) یا احساسی (F) - سوال ۶', optA: 'وقتی کسی مشکل دارد، اول راه‌حل پیشنهاد می‌دهم', optB: 'وقتی کسی مشکل دارد، اول گوش می‌دهم و همدلی می‌کنم', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش سوم: تفکری (T) یا احساسی (F) - سوال ۷', optA: 'از بحث‌های منطقی لذت می‌برم', optB: 'از بحث‌های پرتنش ناراحت می‌شوم', typeA: 'T', typeB: 'F'),
    MbtiQuestion(title: 'بخش سوم: تفکری (T) یا احساسی (F) - سوال ۸', optA: '«درست» بودن برایم مهم‌تر از «محبوب» بودن است', optB: 'هماهنگی در گروه برایم مهم است', typeA: 'T', typeB: 'F'),

    // بخش چهارم: J یا P
    MbtiQuestion(title: 'بخش چهارم: قضاوتی (J) یا ادراکی (P) - سوال ۱', optA: 'برنامه‌ریزی قبلی به من آرامش می‌دهد', optB: 'برنامه‌ریزی سفت‌وسخت احساس محدودیت می‌دهد', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش چهارم: قضاوتی (J) یا ادراکی (P) - سوال ۲', optA: 'کارها را زودتر از موعد تمام می‌کنم', optB: 'اغلب در آخرین لحظه کارها را تمام می‌کنم', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش چهارم: قضاوتی (J) یا ادراکی (P) - سوال ۳', optA: 'تغییر برنامه در لحظه آخر آزارم می‌دهد', optB: 'تغییر برنامه در لحظه آخر هیجان‌انگیز است', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش چهارم: قضاوتی (J) یا ادراکی (P) - سوال ۴', optA: 'دوست دارم تصمیم‌ها گرفته شوند و کار تمام شود', optB: 'دوست دارم گزینه‌ها باز بمانند', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش چهارم: قضاوتی (J) یا ادراکی (P) - سوال ۵', optA: 'فهرست کارها و برنامه روزانه دارم', optB: 'فهرست کارها برایم محدودکننده است', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش چهارم: قضاوتی (J) یا ادراکی (P) - سوال ۶', optA: 'محیط نامرتب حواسم را پرت می‌کند', optB: 'می‌توانم در محیط نامرتب هم کار کنم', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش چهارم: قضاوتی (J) یا ادراکی (P) - سوال ۷', optA: 'ترجیح می‌دهم همه چیز مشخص و قطعی باشد', optB: 'با ابهام و عدم قطعیت راحتم', typeA: 'J', typeB: 'P'),
    MbtiQuestion(title: 'بخش چهارم: قضاوتی (J) یا ادراکی (P) - سوال ۸', optA: 'وقتی کاری نیمه‌تمام است، ذهنم درگیر است', optB: 'می‌توانم چند کار نیمه‌تمام داشته باشم بدون استرس', typeA: 'J', typeB: 'P'),
  ];

  static const Map<String, Map<String, String>> personalityDetails = {
    'INFJ': {
      'title': 'حامی و مشاور معنوی (The Advocate)',
      'desc': 'شما فردی با بصیرت عمیق، آرمان‌گرا و سرشار از بینش معنوی هستید. ارتباط میان معانی پنهان عالم را به خوبی درک می‌کنید و همواره به دنبال هدایت، رشد و کمال دیگران می‌باشید. وجدان بیدار، سکوت پرمعنا و نگاه تعالی‌بخش از ویژگی‌های بارز شماست.'
    },
    'INTJ': {
      'title': 'معمار و استراتژیست (The Architect)',
      'desc': 'فکری نظام‌مند، نوآور و دوراندیش دارید. ساختارهای فکری پیچیده را به سادگی تحلیل می‌کنید و همواره در پی کمال‌بخشی به سیستم‌ها، برنامه‌ها و نظریه‌ها هستید. تصمیم‌گیری‌های شما مبتنی بر منطق محض و دوراندیشی عمیق است.'
    },
    'INFP': {
      'title': 'میانجی و سالک آرمان‌گرا (The Mediator)',
      'desc': 'شخصیتی لطیف، متفکر و پایبند به ارزش‌های عمیق درونی دارید. به دنبال اصالت، خلوص نیت و زیبایی‌های معنوی هستید. زبان هنر، شعر و تفکر عمیق را به نیکی می‌فهمید و همواره با مهربانی و درک بالا با دیگران تعامل می‌کنید.'
    },
    'INTP': {
      'title': 'متفکر و پژوهشگر حقیقت (The Logician)',
      'desc': 'عاشق کاوش در نظریه‌ها، کشف قوانین حاکم بر هستی و حل مسائل فلسفی و منطقی هستید. ذهنی تحلیل‌گر، مستقل و نقاد دارید و از کشف ارتباط میان مفاهیم نوظهور و ناشناخته عمیقاً لذت می‌برید.'
    },
    'ENFJ': {
      'title': 'راهنما و مربی الهام‌بخش (The Protagonist)',
      'desc': 'رهبری پرجاذبه، دلسوز و آرمان‌خواه هستید. استعداد شگرفی در برانگیختن انگیزه‌های معنوی و انسانی در دیگران دارید و با شور و اشتیاق وافر برای ساختن جامعه‌ای بهتر و رشددهنده‌تر تلاش می‌کنید.'
    },
    'ENTJ': {
      'title': 'فرمانده و مدیر راهبردی (The Commander)',
      'desc': 'شخصیتی قاطع، مقتدر و سازمان‌دهنده دارید. نگاه کلان، توانایی در ترسیم اهداف بلندمدت و بسیج امکانات برای دستیابی به مقاصد بزرگ از صفات متمایز شماست. با صلابت بر موانع غلبه می‌کنید.'
    },
    'ENFP': {
      'title': 'پیک الهام و مشتاق اندیشه (The Campaigner)',
      'desc': 'پر از شور و شوق، خلاقیت و دیدگاه‌های بدیع هستید. روابط انسانی گرم و پرمحبتی برقرار می‌کنید و در هر موقعیتی، امکانات نو و افق‌های امیدبخش را مشاهده و به اطرافیان منتقل می‌نمایید.'
    },
    'ENTP': {
      'title': 'مناظره‌گر و نوآور پویا (The Debater)',
      'desc': 'فکری پویا، چابک و سرشار از شوخ‌طبعی و نبوغ دارید. از به چالش کشیدن باورهای سنتی و رسیدن به افق‌های جدید لذت می‌برید و در بحث‌های منطقی و اقناعی بسیار توانمندید.'
    },
    'ISFJ': {
      'title': 'مدافع و خادم فداکار (The Protector)',
      'desc': 'بسیار صبور، باوفا، خدمت‌گزار و مبادی آداب هستید. با آرامش و اخلاص کامل، بدون هیچ چشم‌داشتی به یاری اطرافیان می‌شتابید و در صیانت از ارزش‌ها و سنت‌های نیکو ثبات قدم دارید.'
    },
    'ISTJ': {
      'title': 'بازرس و امین وظیفه‌شناس (The Inspector)',
      'desc': 'شخصیتی منظم، واقع‌بین، مسئولیت‌پذیر و پایبند به انضباط هستید. دقت بالا در انجام تکالیف، رعایت امانت و اهتمام به جزئیات و حقایق ملموس، شما را به تکیه‌گاهی مطمئن تبدیل کرده است.'
    },
    'ESFJ': {
      'title': 'سفیر مهر و حامی جامعه (The Caregiver)',
      'desc': 'کانون گرمی، محبت و هماهنگی در جمع هستید. خدمت به اهل منزل و یاران، حفظ پیوندهای اجتماعی و مراقبت از سلامت روحی دیگران، اولویت نخست زندگی شما به شمار می‌رود.'
    },
    'ESTJ': {
      'title': 'ناظر و مدیر نظم‌آفرین (The Executive)',
      'desc': 'منظم، واقع‌گرا، صریح و سخت‌کوش هستید. در مدیریت منابع، ساماندهی امور روزمره و برقراری رویه‌های عادلانه و ساختاریافته استادی تمام‌عیار به شمار می‌روید.'
    },
    'ISFP': {
      'title': 'هنرمند و کاوشگر زیبایی (The Adventurer)',
      'desc': 'روحی لطیف، متواضع و سرشار از درک زیبایی‌ها دارید. بی سر و صدا در پی کسب تجارب اصیل و ارزشمند در زندگی هستید و آرامش و صفای درون را بر هر تعارض و هیاهویی ترجیح می‌دهید.'
    },
    'ISTP': {
      'title': 'صنعتگر و چیره‌دست کاردان (The Virtuoso)',
      'desc': 'فردی عمل‌گرا، تحلیل‌گر، ماهر و خونسرد در بحران‌ها هستید. با ابزارها و سازوکارهای عینی به خوبی ارتباط برقرار می‌کنید و مسائل را با راه‌حل‌های عملی و منطقی رفع می‌نمایید.'
    },
    'ESFP': {
      'title': 'شادی‌آفرین و پیام‌آور سرزندگی (The Entertainer)',
      'desc': 'پر از نشاط، شادابی، ذوق زیستن و بخشش هستید. با حضور خود صفا و تحرک به مجالس می‌بخشید و از لحظه لحظه زندگی و نعمت‌های موجود در آن شکرگزارانه بهره می‌برید.'
    },
    'ESTP': {
      'title': 'کارآفرین و پیشگام باصلابت (The Entrepreneur)',
      'desc': 'شجاع، واقع‌گرا، اهل اقدام صریح و تصمیم‌گیری سریع هستید. از پذیرش چالش‌ها و مواجهه مستقیم با واقعیت‌های متغیر هراسی ندارید و با هوشمندی فرصت‌ها را شکار می‌کنید.'
    },
  };

  void _calculateResult() {
    int countE = 0, countI = 0;
    int countS = 0, countN = 0;
    int countT = 0, countF = 0;
    int countJ = 0, countP = 0;

    for (int i = 0; i < 8; i++) {
      if (_answers[i] == 'E') countE++;
      if (_answers[i] == 'I') countI++;
    }
    for (int i = 8; i < 16; i++) {
      if (_answers[i] == 'S') countS++;
      if (_answers[i] == 'N') countN++;
    }
    for (int i = 16; i < 24; i++) {
      if (_answers[i] == 'T') countT++;
      if (_answers[i] == 'F') countF++;
    }
    for (int i = 24; i < 32; i++) {
      if (_answers[i] == 'J') countJ++;
      if (_answers[i] == 'P') countP++;
    }

    final String res = (countE >= countI ? 'E' : 'I') +
        (countS >= countN ? 'S' : 'N') +
        (countT >= countF ? 'T' : 'F') +
        (countJ >= countP ? 'J' : 'P');

    setState(() {
      _calculatedType = res;
      _showResult = true;
    });
  }

  void _resetQuiz() {
    setState(() {
      _answers.clear();
      _showResult = false;
      _calculatedType = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      final details = personalityDetails[_calculatedType] ?? {
        'title': 'تیپ شخصیتی $_calculatedType',
        'desc': 'توضیحات تکمیلی برای این تیپ ثبت شده است.'
      };

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF133B4F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1ABC9C), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFF1ABC9C), size: 60),
                  const SizedBox(height: 12),
                  const Text('نتیجه ارزیابی شخصیت شما',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    _calculatedType,
                    style: const TextStyle(
                        color: Color(0xFF1ABC9C),
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    details['title']!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(color: Colors.white24, height: 28),
                  Text(
                    details['desc']!,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14.5, height: 1.8),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _resetQuiz,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('آزمون مجدد',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    final int answeredCount = _answers.length;
    final double progress = answeredCount / questions.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: const Color(0xFF0F3244),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'آزمون خودارزیابی MBTI (نسخه فارسی)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '$answeredCount از ۳۲ پاسخ داده شده',
                    style: const TextStyle(color: Color(0xFF1ABC9C), fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: Colors.white12,
                  color: const Color(0xFF1ABC9C),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              final currentAns = _answers[index];

              return Card(
                color: const Color(0xFF133B4F),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: currentAns != null ? const Color(0xFF1ABC9C).withOpacity(0.5) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.title,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _answers[index] = q.typeA;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: currentAns == q.typeA ? const Color(0xFF1ABC9C).withOpacity(0.2) : Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: currentAns == q.typeA ? const Color(0xFF1ABC9C) : Colors.white10,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                currentAns == q.typeA ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: currentAns == q.typeA ? const Color(0xFF1ABC9C) : Colors.white38,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q.optA,
                                  style: TextStyle(
                                    color: currentAns == q.typeA ? Colors.white : Colors.white70,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _answers[index] = q.typeB;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: currentAns == q.typeB ? const Color(0xFF1ABC9C).withOpacity(0.2) : Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: currentAns == q.typeB ? const Color(0xFF1ABC9C) : Colors.white10,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                currentAns == q.typeB ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: currentAns == q.typeB ? const Color(0xFF1ABC9C) : Colors.white38,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q.optB,
                                  style: TextStyle(
                                    color: currentAns == q.typeB ? Colors.white : Colors.white70,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF0F3244),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: answeredCount == 32 ? const Color(0xFF1ABC9C) : Colors.grey.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: answeredCount == 32 ? _calculateResult : null,
              child: Text(
                answeredCount == 32 ? 'مشاهده نتیجه تیپ شخصیتی' : 'پاسخ به همه سوالات (${32 - answeredCount} مانده)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
