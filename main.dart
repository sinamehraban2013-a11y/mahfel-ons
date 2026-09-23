import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

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

  final String _fixFileTitlesCss = '''
    const oldStyle = document.getElementById('mahfel-file-title-style');
    if (oldStyle) {
      oldStyle.remove();
    }

    const style = document.createElement('style');
    style.id = 'mahfel-file-title-style';
    style.innerHTML = `
      .tgme_widget_message_document_title,
      .document_title,
      .media_document_title,
      .tgme_widget_message_text {
        white-space: normal !important;
        text-overflow: unset !important;
        overflow: visible !important;
        word-break: break-word !important;
        display: block !important;
      }
    `;
    document.head.appendChild(style);
  ''';

  @override
  void initState() {
    super.initState();

    _booksController = _createController(
      'https://eitaa.com/ketab_shiravi',
    );

    _articlesController = _createController(
      'https://eitaa.com/maghaleh_shiravi',
    );
  }

  WebViewController _createController(String url) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B2B3A))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Mobile) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String currentUrl) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String currentUrl) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }

            _injectFileTitleStyle();
          },
          onNavigationRequest: (NavigationRequest request) {
            final targetUrl = request.url;

            if (targetUrl.startsWith('et://') ||
                targetUrl.startsWith('eitaa://')) {
              _launchExternal(targetUrl);
              return NavigationDecision.prevent;
            }

            final lower = targetUrl.toLowerCase();

            if (lower.endsWith('.pdf') ||
                lower.endsWith('.doc') ||
                lower.endsWith('.docx') ||
                lower.endsWith('.zip') ||
                lower.endsWith('.rar') ||
                lower.contains('download=true') ||
                lower.contains('/download/')) {
              _downloadAndOpen(targetUrl);
              return NavigationDecision.prevent;
            }

            final isInternal =
                targetUrl.contains('eitaa.com/ketab_shiravi') ||
                targetUrl.contains('eitaa.com/maghaleh_shiravi') ||
                targetUrl.contains('eitaa.com/m/');

            if (!isInternal &&
                (targetUrl.startsWith('http://') ||
                    targetUrl.startsWith('https://'))) {
              _launchExternal(targetUrl);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final androidController =
          controller.platform as AndroidWebViewController;

      androidController.setOnDownloadStart(
        (String url, String userAgent, String contentDisposition, String mimetype, int contentLength) {
          _downloadAndOpen(
            url,
            suggestedFileName: _extractFileName(contentDisposition, url),
          );
        },
      );
    }

    controller.loadRequest(Uri.parse(url));

    return controller;
  }

  void _injectFileTitleStyle() {
    final controller = _selectedIndex == 0
        ? _booksController
        : _articlesController;

    controller.runJavaScript(_fixFileTitlesCss);
  }

  String _extractFileName(String? disposition, String url) {
    if (disposition != null && disposition.isNotEmpty) {
      try {
        final utf8Match = RegExp(
          r"filename\*=UTF-8''([^;]+)",
          caseSensitive: false,
        ).firstMatch(disposition);

        if (utf8Match != null && utf8Match.group(1) != null) {
          return Uri.decodeComponent(
            utf8Match.group(1)!.trim().replaceAll('"', ''),
          );
        }

        final normalMatch = RegExp(
          r'filename[^;=\n]*=((["\']).*?\2|[^;\n]*)',
          caseSensitive: false,
        ).firstMatch(disposition);

        if (normalMatch != null && normalMatch.group(1) != null) {
          return normalMatch
              .group(1)!
              .replaceAll('"', '')
              .replaceAll("'", "")
              .trim();
        }
      } catch (_) {}
    }

    final uri = Uri.tryParse(url);

    if (uri != null && uri.pathSegments.isNotEmpty) {
      final lastSegment = uri.pathSegments.last.trim();

      if (lastSegment.isNotEmpty && lastSegment.contains('.')) {
        return Uri.decodeComponent(lastSegment);
      }
    }

    return 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }

  Future<void> _downloadAndOpen(
    String fileUrl, {
    String? suggestedFileName,
  }) async {
    if (!mounted) return;

    bool dialogIsOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return const AlertDialog(
          backgroundColor: Color(0xFF133B4F),
          content: Row(
            children: [
              CircularProgressIndicator(
                color: Color(0xFF1ABC9C),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  'در حال دریافت و بازگشایی فایل...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final uri = Uri.tryParse(fileUrl);

      if (uri == null) {
        throw Exception('نشانی فایل معتبر نیست');
      }

      final response = await http.get(uri);

      if (mounted && dialogIsOpen) {
        dialogIsOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();

        var fileName = suggestedFileName;

        if (fileName == null || fileName.trim().isEmpty) {
          fileName = _extractFileName(null, fileUrl);
        }

        fileName = fileName.replaceAll('/', '_');
        fileName = fileName.replaceAll('\\', '_');

        final file = File('${dir.path}/$fileName');

        await file.writeAsBytes(
          response.bodyBytes,
          flush: true,
        );

        final result = await OpenFilex.open(file.path);

        if (result.type != ResultType.done) {
          await _launchExternal(fileUrl);
        }
      } else {
        await _launchExternal(fileUrl);
      }
    } catch (_) {
      if (mounted && dialogIsOpen) {
        dialogIsOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }

      await _launchExternal(fileUrl);
    }
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) return;

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF133B4F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'جستجو در محتوا',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          content: TextField(
            controller: searchController,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              hintText: 'عنوان کتاب یا کلمه کلیدی را بنویسید...',
              hintStyle: TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF1ABC9C),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF1ABC9C),
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'انصراف',
                style: TextStyle(
                  color: Colors.white60,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1ABC9C),
              ),
              onPressed: () {
                final query = searchController.text.trim();

                Navigator.of(ctx).pop();

                if (query.isEmpty) return;

                final targetUrl = _selectedIndex == 0
                    ? 'https://eitaa.com/ketab_shiravi?q=${Uri.encodeComponent(query)}'
                    : 'https://eitaa.com/maghaleh_shiravi?q=${Uri.encodeComponent(query)}';

                if (_selectedIndex == 0) {
                  _booksController.loadRequest(
                    Uri.parse(targetUrl),
                  );
                } else {
                  _articlesController.loadRequest(
                    Uri.parse(targetUrl),
                  );
                }
              },
              child: const Text(
                'جستجو',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showContactUsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF133B4F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ارتباط با ما',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.language,
                  color: Color(0xFF1ABC9C),
                  size: 28,
                ),
                title: const Text(
                  'پایگاه اینترنتی رسمی',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                subtitle: const Text(
                  'www.shiravi.org',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchExternal('https://www.shiravi.org');
                },
              ),
              const Divider(
                color: Colors.white12,
              ),
              ListTile(
                leading: const Icon(
                  Icons.send_rounded,
                  color: Color(0xFF1ABC9C),
                  size: 28,
                ),
                title: const Text(
                  'کانال رسمی در پیام‌رسان ایتا',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                subtitle: const Text(
                  '@shiravi_ir',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchExternal('https://eitaa.com/shiravi_ir');
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF0F3244),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(
              maxHeight: 560,
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF1ABC9C),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'درباره استاد و محفل اُنس',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(
                  color: Colors.white24,
                  height: 24,
                ),
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
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.8,
                      ),
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
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text(
                      'بستن',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'محفل اُنس',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            tooltip: 'جستجو',
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            color: const Color(0xFF133B4F),
            onSelected: (value) {
              if (value == 'about') {
                _showAboutUsDialog();
              }

              if (value == 'contact') {
                _showContactUsModal();
              }

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
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF1ABC9C),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'درباره ما',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(
                      Icons.contact_support_outlined,
                      color: Color(0xFF1ABC9C),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'ارتباط با ما',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reload',
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      color: Color(0xFF1ABC9C),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'بارگذاری مجدد',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
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
              WebViewWidget(
                controller: _booksController,
              ),
              WebViewWidget(
                controller: _articlesController,
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF1ABC9C),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white10,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });

            _injectFileTitleStyle();
          },
          backgroundColor: const Color(0xFF0B2B3A),
          selectedItemColor: const Color(0xFF1ABC9C),
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.menu_book_rounded,
              ),
              label: 'کتاب‌ها',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.article_rounded,
              ),
              label: 'مقالات',
            ),
          ],
        ),
      ),
    );
  }
}
