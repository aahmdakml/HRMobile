import 'package:flutter/material.dart';

/// Global navigator key to allow navigation without context
/// Used for redirection from services (e.g. ApiClient on 401)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
