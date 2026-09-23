import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
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
      final booksRes = await http.get(Uri.parse('$scriptApiUrl?folderId=$ketabFolderId'));
      final articlesRes = await http.get(Uri.parse('$scriptApiUrl?folderId=$maghalehFolderId'));

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
          _errorMessage = 'خطا در ارتباط با سرور ابری گوگل';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطا در اتصال به اینترنت یا دریافت اطلاعات';
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
              child: Text(
                'در حال دریافت و بازگشایی فایل...',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
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

        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
          await _launchExternal(downloadUrl);
        }
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
                    'درباره استاد محمدمهدی شیروی',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'استاد "محمدمهدی شیروی خوزانی" مفسّر قرآن کریم، استاد اخلاق و معارف الهی\n\n'
                    'در نهم فروردین‌ماه سال ۱۳۳۸، در شهرستان خمینی‌شهر (سده) از توابع استان اصفهان، دیده به جهان گشودند. از چهار سالگی، سه سال را در مکتب‌های سنتی محل گذراندند و سپس دوره ششم ابتدایی را در «مدرسه ملی شهر» به پایان رساندند.\n\n'
                    'فضای اجتماعی آن دوران سبب شد که از همان کودکی به کار و تلاش روی آورند. از جمله فعالیت‌های ایشان می‌توان به شاگردی در خیاطی، کارگری در کارخانه ریسندگی، همکاری در مغازه، کشاورزی در کنار پدر، و نیز کارگری در کارخانه سنگ‌بری و نصب سنگ نما اشاره کرد.\n\n'
                    'در سال‌های اشتغال به کار سنگ، علاقه‌مندی به علوم دینی در ایشان پدید آمد. سرانجام در سال ۱۳۵۷، به مدرسه علمیه مشکاة در زادگاه خود راه یافتند و به تحصیل جامع‌المقدمات پرداختند. روحیه جست‌وجوگر و عطش دانایی، ایشان را بر آن داشت تا در مدت کوتاهی، کتاب‌های متعددی را مطالعه کنند و به‌طور خودآموخته با شاخه‌های گوناگون علمی آشنا شوند.\n\n'
                    'با پیروزی انقلاب اسلامی و آغاز جنگ تحمیلی در سال ۱۳۵۹، وظیفه دفاع از میهن را بر خود لازم دانستند و به عضویت سپاه پاسداران انقلاب اسلامی درآمدند. در این دوران، مسئولیت‌هایی همچون عملیات، اعزام نیرو، و مربیگری عقیدتی ـ سیاسی را بر عهده داشتند.\n\n'
                    'شوق یادگیری علوم و معارف الهی سبب شد که پس از چهار سال خدمت در سپاه، در سال ۱۳۶۳ برای ادامه تحصیل رسمی دروس حوزوی، عازم شهر قم شوند. به‌واسطه آمادگی علمی پیشین، استعداد خدادادی و پشتکار مثال‌زدنی، در سال ۱۳۶۷ دوره سطح حوزه را به پایان رساندند و مدتی نیز از محضر درس خارج استادان برجسته حوزه علمیه قم بهره بردند.\n\n'
                    'با پایان یافتن جنگ و تحصیلات حوزوی، تصمیم گرفتند در عرصه تعلیم و تربیت نقش‌آفرینی کنند. بر اساس نیاز و دعوت برخی دلسوزان، در سال ۱۳۶۸ به تهران هجرت کردند و تا سال ۱۳۸۰ به‌عنوان استاد دروس عمومی در دانشگاه علوم پزشکی ایران به تدریس پرداختند. هم‌زمان، در دفتر نمایندگی ولی‌فقیه و سپس به‌عنوان رابط فرهنگی دفتر نهاد مقام معظم رهبری در دانشگاه، و نیز به‌عنوان امام جماعت مساجد مختلف فعالیت داشتند. از آن زمان تاکنون، در کسوت روحانیت، به هدایت، تربیت دینی و خدمت به مردم اشتغال دارند.\n\n'
                    'در سال ۱۳۷۸، بی‌آنکه پیش‌تر تجربه یا آموزشی در عرصه شعر داشته باشند، قریحه شعری ایشان شکوفا شد و با عنایتی خاص، جرقه تفسیر منظوم سوره یوسف زده شد؛ آغازی برای تألیف مجموعه گرانسنگ «تفسیر معنوی» که تاکنون ۲۸ سوره از قرآن کریم را در قالب مثنوی و با شیوه‌ای نوین به نظم کشیده‌اند. از این مجموعه، سه جلد منتشر شده و سایر مجلدات آماده چاپ است.\n\n'
                    'سوره‌های مبارکه یوسف، نور، ابراهیم، مریم، کوثر، یٰس، فرقان، حجرات، کهف، انبیاء، الرحمن، شمس، نوح، جمعه، حمد، عادیات، عصر، نمل، ناس، عنکبوت، قلم، حج، زلزال، انسان، توحید، اسراء، نحل و بقره از جمله این آثارند. در خلال تفسیر سوره توحید، شرح و تفسیر دعای شریف جوشن کبیر نیز ارائه شده است. حاصل این تلاش‌ها تاکنون بیش از ۱۵۰هزار بیت شعر در قالب «تفسیر معنوی قرآن» است.\n\n'
                    'این مجموعه، آمیزه‌ای است از واژگان قرآنی، تأملات فلسفی ـ عرفانی، و پیوند آن با معارف اهل‌بیت علیهم‌السلام و «قرآن صاعد» که در عین زیبایی و لطافت، از استحکام علمی و معنوی برخوردار است. ویژگی ممتاز این آثار، آن است که هر خواننده با مطالعه چند آیه نخست، شیفته آن می‌شود.\n\n'
                    'از دیگر آثار ایشان، مجموعه کتاب‌های «هزاران فکر عمیق» است که تاکنون بیش از هفت هزار نکته حکیمانه در آن گرد آمده و پنج جلد آن منتشر شده است. همچنین، کانال‌های «فکر عمیق» و «محفل انس» در پیام‌رسان‌های تلگرام، بله، ایتا و سروش فعال‌اند و مجموعه‌ای از سخنان حکیمانه، عکس‌نوشته‌ها و بیش از دوهزار فایل صوتی در موضوعات گوناگون را در بر دارند.\n\n'
                    'مجموعه «پرسمان» نیز حاصل سال‌ها پرسش و پاسخ میان اقشار مختلف مردم و ایشان در پیام‌رسان‌هایی چون تلگرام، واتساپ، بله و ایتا است که همچنان ادامه دارد.\n\n'
                    'دیگر آثار منظوم ایشان شامل:\n'
                    '• شرح و تفسیر نامه مبارک امیرالمؤمنین علیه‌السلام به مالک اشتر در قالب مثنوی (حدود ۲۰۰۰ بیت)\n'
                    '• شرح دعای هفتم صحیفه سجادیه (بیش از ۱۰۰۰ بیت، آماده چاپ)\n'
                    '• شرح برخی از مناجات‌های خمس عشر به شیوه شعری\n'
                    '• سرودن بیش از ۲۰۰۰ بیت دوبیتی و حدود ۱۰۰۰ بیت غزل\n\n'
                    'مجموعه مکتوب جلسات «محفل انس» و سخنرانی‌های بیش از بیست سال گذشته، که کتاب‌هایی چون «شب‌های رمضان»، «روح»، «نماز» و «توحید» از آن جمله‌اند و در دست آماده‌سازی برای چاپ می‌باشند.\n\n'
                    'از خداوند متعال، طول عمر با عزت و توفیقات روزافزون برای این عالم ربانی و بهره‌مندی هرچه بیشتر دوستداران معارف الهی از محضر این گنجینه گران‌بها را خواستاریم.\n\n'
                    '«این قلم را آل یاسین داده است\n'
                    'شکر حق، از بای تا سین داده است»',
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _selectedIndex == 0 ? _books : _articles;
    final filteredList = currentList.where((doc) {
      return doc.name.toLowerCase().contains(_searchQuery.toLowerCase());
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
        centerTitle: true,
        actions: [
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
                    Text('درباره استاد', style: TextStyle(color: Colors.white)),
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
      body: _isLoading
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
                                  Icons.file_download_outlined,
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
          ],
        ),
      ),
    );
  }
}
