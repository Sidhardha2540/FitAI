import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AIChatWebViewScreen extends StatefulWidget {
  const AIChatWebViewScreen({super.key});

  @override
  State<AIChatWebViewScreen> createState() => _AIChatWebViewScreenState();
}

class _AIChatWebViewScreenState extends State<AIChatWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize WebView controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            
            // If we're on the selection page, automatically select the fitai_adk agent
            if (url == 'https://fitai-agent-service-821526360592.us-central1.run.app/dev-ui') {
              _selectFitAiAgent();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://fitai-agent-service-821526360592.us-central1.run.app/dev-ui?app=fitai_adk'));
  }
  
  // Use JavaScript to automatically select the fitai_adk agent
  void _selectFitAiAgent() {
    _controller.runJavaScript('''
      (function() {
        const agentButtons = document.querySelectorAll('button');
        for (const button of agentButtons) {
          if (button.textContent && button.textContent.includes('fitai_adk')) {
            button.click();
            return;
          }
        }
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Icon(
                Icons.smart_toy,
                size: 14,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Fitness Coach',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: colorScheme.background.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Loading AI Coach...',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(),
            ),
        ],
      ),
    );
  }
} 