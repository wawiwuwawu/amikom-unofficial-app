import 'package:flutter/material.dart';

/// Kunci navigator global — dipasang di `MaterialApp` (main.dart) agar
/// interceptor Dio (api_client) dan PushService bisa redirect ke /login atau
/// membuka halaman dari luar konteks widget.
class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();
}
