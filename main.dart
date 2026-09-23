
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MahfelOnsApp());
}

class DocumentItem {
  final String title;
  final String driveFileId;
  final String category;

  DocumentItem({
    required this.title,
    required this.driveFileId,
    required this.category,
  });
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
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0B2B3A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B2B3A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
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

  // فهرست مقالات بر اساس پوشه maghaleh در گوگل درایو شما
  final List<DocumentItem> _articles = [
    DocumentItem(title: 'آرمان‌شهر ۱', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'آرمان‌شهر ۲', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'آرمان‌شهر اسلامی', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'آینده و هوش مصنوعی', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'اتمسفر تعامل؛ نظریه‌ای میدانی درباره پویایی اجتماعی از منظر قرآن کریم', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'احسن‌القصص به مثابه نقشه سلوک انسان با تفسیر معنوی', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'ارزش میدان', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'از پرتگاه پوچی تا افق معنا', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'از هجرت تا حرم حضرت معصومه (س)', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'الگوی تربیت استقلال ۵ گانه', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'انسان کشدار', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'ایمان یا منفعت؟ دو نوع چسب اجتماعی و سرنوشت دو تمدن', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'بت‌واره‌ی «من»', driveFileId: '', category: 'maghaleh'),
    DocumentItem(title: 'بت‌واره‌ی «من» خلاصه', driveFileId: '', category: 'maghaleh'),
  ];

  // فهرست کتاب‌ها بر اساس پوشه ketab در گوگل درایو شما
  final List<DocumentItem> _books = [
    DocumentItem(title: 'از هجرت تا حرم حضرت معصومه (س)', driveFileId: '', category: 'ketab'),
    DocumentItem(title: 'انسان جهانی ناشناخته', driveFileId: '', category: 'ketab'),
    DocumentItem(title: 'تصمیمات یک درصدی (مدیریت بحران)', driveFileId: '', category: 'ketab'),
    DocumentItem(title: 'داستان حرکت', driveFileId: '', category: 'ketab'),
    DocumentItem(title: 'داستان حضرت معصومه (س)', driveFileId: '', category: 'ketab'),
    DocumentItem(title: 'راهنمای جامع طراحی و تدوین قراردادهای حفاری در صنعت نفت ایران', driveFileId: '', category: 'ketab'),
    DocumentItem(title: 'ساختارشناسی تعالی و افول تمدنی', driveFileId: '', category: 'ketab'),
    DocumentItem(title: 'شرح و بسط تئوری لطافت', driveFileId: '', category: 'ketab'),
    DocumentItem(title: 'عاشورا؛ بازسازی تمدن در بستر شاهکار حسینی', driveFileId: '', category: 'ketab'),
    DocumentItem(title: 'مدیریت فرقان', driveFileId: '', category: 'ketab'),
    DocumentItem(title: 'هنر انتخاب و مدیریت رابطه', driveFileId: '', category: 'ketab'),
  ];

  Future<void> _downloadAndOpen(DocumentItem doc) async {
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
              child: Text(
                'در حال دریافت و آماده‌سازی فایل...',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // در صورت وجود شناسه فایل گوگل درایو، لینک مستقیم دانلود ساخته می‌شود
      final String downloadUrl = doc.driveFileId.isNotEmpty
          ? 'https://drive.google.com/uc?export=download&id=${doc.driveFileId}'
          : 'https://www.shiravi.org';

      if (doc.driveFileId.isEmpty) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        await _launchExternal('https://www.shiravi.org');
        return;
      }

      final response = await http.get(Uri.parse(downloadUrl));

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${doc.title.replaceAll(' ', '_')}.pdf');
        await file.writeAsBytes(response.bodyBytes, flush: true);

        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
          await _launchExternal(downloadUrl);
        }
      } else {
        await _launchExternal(downloadUrl);
      }
    } catch (_) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      await _launchExternal('https://www.shiravi.org');
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
          constraints: const BoxConstraints(maxHeight: 560),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1ABC9C)),
                  SizedBox(width: 8),
                  Text(
                    'درباره استاد و محفل اُنس',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''استاد "محمدمهدی شیروی خوزانی" مفسّر قرآن کریم، استاد اخلاق و معارف الهی

در نهم فروردین‌ماه سال ۱۳۳۸، در شهرستان خمینی‌شهر (سده) از توابع استان اصفهان، دیده به جهان گشودند. از چهار سالگی، سه سال را در مکتب‌های سنتی محل گذراندند و سپس دوره ششم ابتدایی را در «مدرسه ملی شهر» به پایان رساندند.

فضای اجتماعی آن دوران سبب شد که از همان کودکی به کار و تلاش روی آورند. در سال‌های اشتغال، علاقه‌مندی به علوم دینی در ایشان پدید آمد و سرانجام در سال ۱۳۵۷، به مدرسه علمیه مشکاة راه یافتند.

با آغاز جنگ تحمیلی، به عضویت سپاه پاسداران انقلاب اسلامی درآمدند و پس از چهار سال خدمت، در سال ۱۳۶۳ برای ادامه دروس حوزوی عازم قم شدند و دوره سطح حوزه و دروس خارج را با موفقیت سپری کردند.

در سال ۱۳۶۸ به تهران هجرت کرده و تا سال ۱۳۸۰ به‌عنوان استاد در دانشگاه علوم پزشکی ایران به تدریس پرداختند.

در سال ۱۳۷۸، قریحه شعری ایشان شکوفا شد و جرقه تفسیر منظوم سوره یوسف زده شد؛ آغازی برای تألیف مجموعه گرانسنگ «تفسیر معنوی» که تاکنون ۲۸ سوره قرآن در قالب مثنوی (بیش از ۱۵۰ هزار بیت) سروده شده است.

از دیگر آثار ایشان:
- مجموعه ۵ جلدی «هزاران فکر عمیق»
- کانال‌های «فکر عمیق» و «محفل انس»
- مجموعه پاسخ‌های مکتوب «پرسمان»
- شرح منظوم نامه امیرالمؤمنین (ع) به مالک اشتر
- شرح دعای هفتم صحیفه سجادیه و مناجات‌های خمس عشر
- مجموعه مکتوب جلسات «شب‌های رمضان»، «روح»، «نماز» و «توحید»

«این قلم را آل یاسین داده است
شکر حق، از بای تا سین داده است»''',
                    style: TextStyle(
                        color: Colors.white, fontSize: 13.5, height: 1.8),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('بستن',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.language,
                  color: Color(0xFF1ABC9C), size: 28),
              title: const Text('پایگاه اینترنتی رسمی',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('www.shiravi.org',
                  style: TextStyle(color: Colors.white70)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                _launchExternal('https://www.shiravi.org');
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.send_rounded,
                  color: Color(0xFF1ABC9C), size: 28),
              title: const Text('کانال رسمی در پیام‌رسان ایتا',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('@shiravi_ir',
                  style: TextStyle(color: Colors.white70)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                _launchExternal('https://eitaa.com/shiravi_ir');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _selectedIndex == 0 ? _books : _articles;
    final filteredList = currentList.where((doc) {
      return doc.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
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
                _selectedIndex == 0 ? 'کتاب‌های استاد شیروی' : 'مقالات استاد شیروی',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
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
                    Text('درباره استاد', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(Icons.contact_support_outlined,
                        color: Color(0xFF1ABC9C), size: 20),
                    SizedBox(width: 10),
                    Text('ارتباط با ما', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: filteredList.isEmpty
          ? const Center(
              child: Text(
                'موردی یافت نشد.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1ABC9C).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _selectedIndex == 0
                            ? Icons.menu_book_rounded
                            : Icons.article_rounded,
                        color: const Color(0xFF1ABC9C),
                        size: 26,
                      ),
                    ),
                    title: Text(
                      doc.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.file_download_outlined,
                      color: Color(0xFF1ABC9C),
                      size: 24,
                    ),
                    onTap: () => _downloadAndOpen(doc),
                  ),
                );
              },
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
          ],
        ),
      ),
    );
  }
}
