import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/w_button.dart';
import 'session_models.dart';
import 'sessions_api_service.dart';

class SessionCallPage extends ConsumerStatefulWidget {
  final CallSession session;

  const SessionCallPage({super.key, required this.session});

  @override
  ConsumerState<SessionCallPage> createState() => _SessionCallPageState();
}

class _SessionCallPageState extends ConsumerState<SessionCallPage> {
  WebViewController? _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _recordJoin();
    _initWebView();
  }

  Future<void> _recordJoin() async {
    try {
      final api = ref.read(sessionsApiServiceProvider);
      await api.joinSession(widget.session.id);
    } catch (_) {}
  }

  Future<void> _recordLeave() async {
    try {
      final api = ref.read(sessionsApiServiceProvider);
      await api.leaveSession(widget.session.id);
    } catch (_) {}
  }

  void _initWebView() {
    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.session.roomUrl));
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchExternalBrowser() async {
    final uri = Uri.parse(widget.session.roomUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Mentorship Session'),
        backgroundColor: AppColors.textDark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in browser',
            onPressed: _launchExternalBrowser,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_webViewController != null)
            WebViewWidget(controller: _webViewController!)
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not open video call in WebView.'),
                  const SizedBox(height: 12),
                  WButton(
                    label: 'Open in Browser',
                    onPressed: _launchExternalBrowser,
                  ),
                ],
              ),
            ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: WButton(
              label: 'Leave Session Call',
              backgroundColor: Colors.red,
              onPressed: () async {
                await _recordLeave();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
