import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MahfelOnsApp());
}

class MahfelOnsApp extends StatelessWidget {
  const MahfelOnsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محفل انس',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Tahoma',
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final WebViewController _controller;
  int _currentIndex = 0;
  bool _isLoading = true;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  String _downloadStatus = '';

  final List<String> _urls = [
    'https://eitaa.com/Ketab_shiravi',
    'https://eitaa.com/Maghaleh_shiravi',
    'https://eitaa.com/shiravi_ir',
  ];

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final NavigationDelegate delegate = NavigationDelegate(
      onProgress: (int progress) {
        if (progress == 100) {
          setState(() => _isLoading = false);
        }
      },
      onPageStarted: (String url) {
        setState(() => _isLoading = true);
      },
      onPageFinished: (String url) {
        setState(() => _isLoading = false);
        _injectCustomCssAndJs();
      },
      onWebResourceError: (WebResourceError error) {
        debugPrint('WebResourceError: ${error.description}');
      },
      onNavigationRequest: (NavigationRequest request) {
        final url = request.url;
        if (_isDownloadableUrl(url)) {
          _downloadAndOpen(url);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(delegate);

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _controller.platform as AndroidWebViewController;
      android.setOnDownloadStart((url) {
        _downloadAndOpen(url);
      });
      android.setOnPlatformPermissionRequest((request) {
        request.grant();
      });
    }

    _controller.loadRequest(Uri.parse(_urls[_currentIndex]));
  }

  bool _isDownloadableUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('/file/') ||
        lower.contains('/api/v1/download') ||
        lower.contains('/download') ||
        lower.contains('?dl=1') ||
        lower.endsWith('.pdf') ||
        lower.endsWith('.apk') ||
        lower.endsWith('.zip') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.mp3')) {
      return true;
    }
    return false;
  }

  void _injectCustomCssAndJs() {
    const css = '''
      var style = document.createElement('style');
      style.innerHTML = `
        .tgme_widget_message_document_title, 
        .eitaa_message_document_title,
        .document-title {
          white-space: normal !important;
          text-overflow: unset !important;
          overflow: visible !important;
          line-height: 1.5 !important;
        }
      `;
      document.head.appendChild(style);
    ''';
    _controller.runJavaScript(css);
  }

  Future<void> _downloadAndOpen(String url) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'در حال آماده‌سازی دانلود...';
    });

    try {
      final uri = Uri.parse(url);
      final client = http.Client();
      final request = http.Request('GET', uri);
      request.headers['Referer'] = 'https://eitaa.com/';
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

      final response = await client.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String fileName = 'file_${DateTime.now().millisecondsSinceEpoch}';
        final disposition = response.headers['content-disposition'];
        if (disposition != null && disposition.contains('filename=')) {
          final match = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
          if (match != null && match.group(1) != null) {
            fileName = Uri.decodeFull(match.group(1)!);
          }
        } else {
          final segments = uri.pathSegments;
          if (segments.isNotEmpty && segments.last.isNotEmpty) {
            fileName = Uri.decodeFull(segments.last);
          }
        }

        if (!fileName.contains('.')) {
          final contentType = response.headers['content-type'] ?? '';
          if (contentType.contains('pdf')) {
            fileName += '.pdf';
          } else if (contentType.contains('zip')) {
            fileName += '.zip';
          } else if (contentType.contains('audio')) {
            fileName += '.mp3';
          }
        }

        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);

        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        final sink = file.openWrite();

        await response.stream.listen((chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            setState(() {
              _downloadProgress = receivedBytes / totalBytes;
              _downloadStatus =
                  'در حال دریافت: ${(receivedBytes / (1024 * 1024)).toStringAsFixed(1)} از ${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} مگابایت';
            });
          } else {
            setState(() {
              _downloadStatus =
                  'در حال دریافت: ${(receivedBytes / (1024 * 1024)).toStringAsFixed(1)} مگابایت';
            });
          }
        }).asFuture();

        await sink.flush();
        await sink.close();

        setState(() {
          _downloadStatus = 'دانلود کامل شد. در حال باز کردن...';
        });

        final openResult = await OpenFilex.open(filePath);
        if (openResult.type != ResultType.done) {
          await Share.shareXFiles([XFile(filePath)], text: fileName);
        }
      } else {
        _showErrorSnackBar('خطا در دانلود فایل (کد خطا: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorSnackBar('خطا در فرآیند دریافت: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _isLoading = true;
    });
    _controller.loadRequest(Uri.parse(_urls[index]));
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('درباره محفل انس', textDirection: TextDirection.rtl),
        content: const SingleChildScrollView(
          child: Text(
            'اپلیکیشن محفل انس\nدرگاه رسمی دسترسی به آثار، کتب، مقالات و پژوهش‌های علمی استاد محمد شیروی خوزانی.\n\nطراحی شده جهت دسترسی آسان، دانلود و مطالعه بومی آثار بدون نیاز به فیلترشکن.',
            textDirection: TextDirection.rtl,
            style: TextStyle(height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('محفل انس'),
          centerTitle: true,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'درباره ما',
              onPressed: _showAboutDialog,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'بازخوانی',
              onPressed: () => _controller.reload(),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.transparent,
              ),
            if (_isDownloading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            _downloadStatus,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_downloadProgress > 0.0) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: _downloadProgress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onBottomNavTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'کتاب‌ها',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'مقالات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign),
              label: 'کانال اصلی',
            ),
          ],
        ),
      ),
    );
  }
}
