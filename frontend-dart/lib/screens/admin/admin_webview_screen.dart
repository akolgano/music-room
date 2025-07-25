import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme_utils.dart';

class AdminWebViewScreen extends StatefulWidget {
  final String routePath;
  final String title;
  
  const AdminWebViewScreen({
    super.key,
    required this.routePath,
    required this.title,
  });

  @override
  State<AdminWebViewScreen> createState() => _AdminWebViewScreenState();
}

class _AdminWebViewScreenState extends State<AdminWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    String baseUrl;
    if (kIsWeb) {
      // For web, we need to handle CORS and iframe restrictions
      baseUrl = 'http://localhost:8000';
    } else {
      baseUrl = dotenv.env['API_BASE_URL']?.replaceAll(RegExp(r'/$'), '') ?? 'http://localhost:8000';
    }
    final fullUrl = '$baseUrl${widget.routePath}';
    
    print('WebView attempting to load: $fullUrl'); // Debug log
    
    _controller = WebViewController();
    
    if (!kIsWeb) {
      _controller!.setJavaScriptMode(JavaScriptMode.unrestricted);
      _controller!.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('WebView page started: $url'); // Debug log
            if (mounted) {
              setState(() {
                _isLoading = true;
                _currentUrl = url;
              });
            }
          },
          onPageFinished: (String url) {
            print('WebView page finished: $url'); // Debug log
            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('WebView navigation request: ${request.url}'); // Debug log
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}'); // Debug log
          },
        ),
      );
    } else {
      // For web platform, add basic navigation handling
      _controller!.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _currentUrl = url;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView web error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      );
    }
    
    _controller!.loadRequest(Uri.parse(fullUrl));
  }

  void _reload() {
    if (_controller != null && mounted) {
      setState(() {
        _isLoading = true;
      });
      _controller!.reload();
    }
  }

  void _goBack() {
    _controller?.goBack();
  }

  void _goForward() {
    _controller?.goForward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
              child: SafeArea(
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: _goBack,
                      tooltip: 'Go Back',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: _goForward,
                      tooltip: 'Go Forward',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _reload,
                      tooltip: 'Reload',
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  if (_isLoading)
                    Container(
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  if (_currentUrl != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
                      child: Text(
                        _currentUrl!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Expanded(
                    child: _controller != null 
                        ? WebViewWidget(controller: _controller!)
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}