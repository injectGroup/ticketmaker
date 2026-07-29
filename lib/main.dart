import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean Hosting paths like /verify/<id> (no hash routing).
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stack) {
    // Never leave a blank page if Firebase init fails on web.
    debugPrint('Firebase.initializeApp failed: $error\n$stack');
  }

  runApp(const TicketMakerApp());
}
