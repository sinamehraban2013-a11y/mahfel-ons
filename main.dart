import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محفل اُنس',
      theme: ThemeData(
        primaryColor: const Color(0xFF0B2B3A),
        scaffoldBackgroundColor: const Color(0xFF0B2B3A),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isLoading = false;

  late final WebViewController _bookController;
  late final WebViewController _maghalehController;

  @override
  void initState() {
    super.initState();
    _bookController = _makeController('https://eitaa.com/ketab_shiravi');
    _maghalehController = _makeController('https://eitaa.com/maghaleh_shiravi');
  }

  WebViewController _makeController(String startUrl) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B2B3A))
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;

            // مدیریت دکمه پیوستن و لینک‌های داخلی ایتا
            if (url.startsWith('et://') || url.startsWith('eitaa://')) {
              _openExternal(url);
              return NavigationDecision.prevent;
            }

            // مدیریت لینک‌های سیستمی و غیروب
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              _openExternal(url);
              return NavigationDecision.prevent;
            }

            // باز کردن لینک‌های دانلود و صفحات جانبی در مرورگر گوشی
            final isInternalPage = url.contains('eitaa.com/ketab_shiravi') ||
                url.contains('eitaa.com/maghaleh_shiravi') ||
                url.contains('eitaa.com/m/');

            if (!isInternalPage) {
              _openExternal(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(startUrl));
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'محفل اُنس',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0B2B3A),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              WebViewWidget(controller: _bookController),
              WebViewWidget(controller: _maghalehController),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0B2B3A),
        selectedItemColor: const Color(0xFF1ABC9C),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'کتاب‌ها',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'مقالات',
          ),
        ],
      ),
    );
  }
}
