import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MahfelOnsApp());
}

class MahfelOnsApp extends StatelessWidget {
  const MahfelOnsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محفل اُنس',
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
      ],
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
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  late final WebViewController _booksController;
  late final WebViewController _articlesController;

  @override
  void initState() {
    super.initState();
    _booksController = _createController('https://eitaa.com/ketab_shiravi');
    _articlesController = _createController('https://eitaa.com/maghaleh_shiravi');
  }

  WebViewController _createController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B2B3A))
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String currentUrl) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String currentUrl) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final targetUrl = request.url;

            // باز کردن PDF خوان داخلی در صورت کلیک روی فایل PDF
            if (targetUrl.toLowerCase().contains('.pdf')) {
              _openPdfViewer(targetUrl);
              return NavigationDecision.prevent;
            }

            // لینک‌های نرم‌افزار ایتا
            if (targetUrl.startsWith('et://') || targetUrl.startsWith('eitaa://')) {
              _launchExternal(targetUrl);
              return NavigationDecision.prevent;
            }

            // خروج از صفحات کانال جهت دانلود یا بازکردن در مرورگر
            final isInternal = targetUrl.contains('eitaa.com/ketab_shiravi') ||
                targetUrl.contains('eitaa.com/maghaleh_shiravi') ||
                targetUrl.contains('eitaa.com/m/');

            if (!isInternal && (targetUrl.startsWith('http://') || targetUrl.startsWith('https://'))) {
              _launchExternal(targetUrl);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  // موتور دانلود و باز کردن کتاب در PDF خوان اختصاصی داخلی
  Future<void> _openPdfViewer(String pdfUrl) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          color: Color(0xFF133B4F),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF1ABC9C)),
                SizedBox(height: 16),
                Text(
                  'در حال دریافت و بازگشایی کتاب...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final request = await HttpClient().getUrl(Uri.parse(pdfUrl));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp_book_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes, flush: true);

      if (mounted) {
        Navigator.of(context).pop(); // بستن لودینگ
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InternalPdfReader(filePath: file.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در دریافت فایل کتاب. اتصال اینترنت را بررسی فرمایید.')),
        );
      }
    }
  }

  // عملکرد جستجو درون کانال جاری
  void _showSearchDialog() {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF133B4F),
        title: const Text('جستجو در آثار و مقالات', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'عنوان کتاب یا موضوع مقاله را بنویسید...',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1ABC9C))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1ABC9C), width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('انصراف', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1ABC9C)),
            onPressed: () {
              final query = searchController.text.trim();
              Navigator.of(ctx).pop();
              if (query.isNotEmpty) {
                final targetUrl = _selectedIndex == 0
                    ? 'https://eitaa.com/ketab_shiravi?q=${Uri.encodeComponent(query)}'
                    : 'https://eitaa.com/maghaleh_shiravi?q=${Uri.encodeComponent(query)}';
                if (_selectedIndex == 0) {
                  _booksController.loadRequest(Uri.parse(targetUrl));
                } else {
                  _articlesController.loadRequest(Uri.parse(targetUrl));
                }
              }
            },
            child: const Text('جستجو', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // نمایش پنجره ارتباط با ما
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
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
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
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                _launchExternal('https://eitaa.com/shiravi_ir');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // نمایش پنجره جامع درباره ما (زندگینامه و کارنامه علمی استاد)
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
                    'درباره استاد و محفل اُنس',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''استاد "محمدمهدی شیروی خوزانی" مفسّر قرآن کریم، استاد اخلاق و معارف الهی

در نهم فروردین‌ماه سال ۱۳۳۸، در شهرستان خمینی‌شهر (سده) از توابع استان اصفهان، دیده به جهان گشودند. از چهار سالگی، سه سال را در مکتب‌های سنتی محل گذراندند و سپس دوره ششم ابتدایی را در «مدرسه ملی شهر» به پایان رساندند.

فضای اجتماعی آن دوران سبب شد که از همان کودکی به کار و تلاش روی آورند. از جمله فعالیت‌های ایشان می‌توان به شاگردی در خیاطی، کارگری در کارخانه ریسندگی، همکاری در مغازه، کشاورزی در کنار پدر، و نیز کارگری در کارخانه سنگ‌بری و نصب سنگ نما اشاره کرد.

در سال‌های اشتغال به کار سنگ، علاقه‌مندی به علوم دینی در ایشان پدید آمد. سرانجام در سال ۱۳۵۷، به مدرسه علمیه مشکاة در زادگاه خود راه یافتند و به تحصیل جامع‌المقدمات پرداختند. روحیه جست‌وجوگر و عطش دانایی، ایشان را بر آن داشت تا در مدت کوتاهی، کتاب‌های متعددی را مطالعه کنند و به‌طور خودآموخته با شاخه‌های گوناگون علمی آشنا شوند.

با پیروزی انقلاب اسلامی و آغاز جنگ تحمیلی در سال ۱۳۵۹، وظیفه دفاع از میهن را بر خود لازم دانستند و به عضویت سپاه پاسداران انقلاب اسلامی درآمدند. در این دوران، مسئولیت‌هایی همچون عملیات، اعزام نیرو، و مربیگری عقیدتی ـ سیاسی را بر عهده داشتند.

شوق یادگیری علوم و معارف الهی سبب شد که پس از چهار سال خدمت در سپاه، در سال ۱۳۶۳ برای ادامه تحصیل رسمی دروس حوزوی، عازم شهر قم شوند. به‌واسطه آمادگی علمی پیشین، استعداد خدادادی و پشتکار مثال‌زدنی، در سال ۱۳۶۷ دوره سطح حوزه را به پایان رساندند و مدتی نیز از محضر درس خارج استادان برجسته حوزه علمیه قم بهره بردند.

با پایان یافتن جنگ و تحصیلات حوزوی، تصمیم گرفتند در عرصه تعلیم و تربیت نقش‌آفرینی کنند. بر اساس نیاز و دعوت برخی دلسوزان، در سال ۱۳۶۸ به تهران هجرت کردند و تا سال ۱۳۸۰ به‌عنوان استاد دروس عمومی در دانشگاه علوم پزشکی ایران به تدریس پرداختند. هم‌زمان، در دفتر نمایندگی ولی‌فقیه و سپس به‌عنوان رابط فرهنگی دفتر نهاد مقام معظم رهبری در دانشگاه، و نیز به‌عنوان امام جماعت مساجد مختلف فعالیت داشتند. از آن زمان تاکنون، در کسوت روحانیت، به هدایت، تربیت دینی و خدمت به مردم اشتغال دارند.

در سال ۱۳۷۸، بی‌آنکه پیش‌تر تجربه یا آموزشی در عرصه شعر داشته باشند، قریحه شعری ایشان شکوفا شد و با عنایتی خاص، جرقه تفسیر منظوم سوره یوسف زده شد؛ آغازی برای تألیف مجموعه گرانسنگ «تفسیر معنوی» که تاکنون ۲۸ سوره از قرآن کریم را در قالب مثنوی و با شیوه‌ای نوین به نظم کشیده‌اند. از این مجموعه، سه جلد منتشر شده و سایر مجلدات آماده چاپ است.

سوره‌های مبارکه یوسف، نور، ابراهیم، مریم، کوثر، یٰس، فرقان، حجرات، کهف، انبیاء، الرحمن، شمس، نوح، جمعه، حمد، عادیات، عصر، نمل، ناس، عنکبوت، قلم، حج، زلزال، انسان، توحید، اسراء، نحل و بقره از جمله این آثارند. در خلال تفسیر سوره توحید، شرح و تفسیر دعای شریف جوشن کبیر نیز ارائه شده است. حاصل این تلاش‌ها تاکنون بیش از ۱۵۰هزار بیت شعر در قالب «تفسیر معنوی قرآن» است.

این مجموعه، آمیزه‌ای است از واژگان قرآنی، تأملات فلسفی ـ عرفانی، و پیوند آن با معارف اهل‌بیت علیهم‌السلام و «قرآن صاعد» که در عین زیبایی و لطافت، از استحکام علمی و معنوی برخوردار است. ویژگی ممتاز این آثار، آن است که هر خواننده با مطالعه چند آیه نخست، شیفته آن می‌شود.

از دیگر آثار ایشان، مجموعه کتاب‌های «هزاران فکر عمیق» است که تاکنون بیش از هفت هزار نکته حکیمانه در آن گرد آمده و پنج جلد آن منتشر شده است. همچنین، کانال‌های «فکر عمیق» و «محفل انس» در پیام‌رسان‌های تلگرام، بله، ایتا و سروش فعال‌اند و مجموعه‌ای از سخنان حکیمانه، عکس‌نوشته‌ها و بیش از دوهزار فایل صوتی در موضوعات گوناگون را در بر دارند.

مجموعه «پرسمان» نیز حاصل سال‌ها پرسش و پاسخ میان اقشار مختلف مردم و ایشان در پیام‌رسان‌هایی چون تلگرام، واتساپ، بله و ایتا است که همچنان ادامه دارد.

دیگر آثار منظوم ایشان شامل:
- شرح و تفسیر نامه مبارک امیرالمؤمنین علیه‌السلام به مالک اشتر در قالب مثنوی (حدود ۲۰۰۰ بیت)
- شرح دعای هفتم صحیفه سجادیه (بیش از ۱۰۰۰ بیت، آماده چاپ)
- شرح برخی از مناجات‌های خمس عشر به شیوه شعری
- سرودن بیش از ۲۰۰۰ بیت دوبیتی و حدود ۱۰۰۰ بیت غزل

مجموعه مکتوب جلسات «محفل انس» و سخنرانی‌های بیش از بیست سال گذشته، که کتاب‌هایی چون «شب‌های رمضان»، «روح»، «نماز» و «توحید» از آن جمله‌اند و در دست آماده‌سازی برای چاپ می‌باشند.

از خداوند متعال، طول عمر با عزت و توفیقات روزافزون برای این عالم ربانی و بهره‌مندی هرچه بیشتر دوستداران معارف الهی از محضر این گنجینه گران‌بها را خواستاریم.

«این قلم را آل یاسین داده است
شکر حق، از بای تا سین داده است»''',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1ABC9C)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'محفل اُنس',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'جستجو',
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF133B4F),
            onSelected: (value) {
              if (value == 'about') _showAboutUsDialog();
              if (value == 'contact') _showContactUsModal();
              if (value == 'reload') {
                if (_selectedIndex == 0) {
                  _booksController.reload();
                } else {
                  _articlesController.reload();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF1ABC9C), size: 20),
                    SizedBox(width: 10),
                    Text('درباره ما', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(Icons.contact_support_outlined, color: Color(0xFF1ABC9C), size: 20),
                    SizedBox(width: 10),
                    Text('ارتباط با ما', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reload',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Color(0xFF1ABC9C), size: 20),
                    SizedBox(width: 10),
                    Text('بارگذاری مجدد', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              WebViewWidget(controller: _booksController),
              WebViewWidget(controller: _articlesController),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1ABC9C)),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
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

// صفحه PDF خوان داخلی با امکان ورق زدن، بزرگ‌نمایی و نمایش شماره صفحه
class InternalPdfReader extends StatefulWidget {
  final String filePath;
  const InternalPdfReader({super.key, required this.filePath});

  @override
  State<InternalPdfReader> createState() => _InternalPdfReaderState();
}

class _InternalPdfReaderState extends State<InternalPdfReader> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2B3A),
      appBar: AppBar(
        title: Text(
          _isReady ? 'صفحه ${_currentPage + 1} از $_totalPages' : 'نمایشگر کتاب',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B2B3A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PDFView(
        filePath: widget.filePath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        nightMode: false,
        onRender: (pages) {
          setState(() {
            _totalPages = pages ?? 0;
            _isReady = true;
          });
        },
        onPageChanged: (page, total) {
          setState(() {
            _currentPage = page ?? 0;
          });
        },
      ),
    );
  }
}
