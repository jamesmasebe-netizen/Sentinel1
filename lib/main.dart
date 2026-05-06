import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'core/providers/app_providers.dart';
import 'core/services/session_manager.dart';
import 'scripts/seed_dummy_data.dart';

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
    ),
  );
  debugPrint('📩 Background FCM: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // ─── Firebase Initialization ───
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
    ),
  );

  // ─── Register FCM background handler ───
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ─── Use emulators in debug mode ───
  // Uncomment the lines below when running `firebase emulators:start`
  // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

  // ─── Configure Firestore for custom database ID + offline persistence ───
  final firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ai-studio-4bb0fb1c-c6d6-4397-a015-156f3ff9dfb5',
  );
  firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // --- DEV ONLY: SEED DUMMY DATA ON STARTUP ---
  if (kDebugMode) {
    try {
      debugPrint('Seeding dummy data...');
      await seedAllDummyData(firestore);
      debugPrint('Successfully seeded dummy data.');
    } catch (e) {
      debugPrint('Error seeding dummy data: $e');
    }
  }

  // ─── Initialize Hive for offline queue ───
  await Hive.initFlutter();

  // ─── Lock orientation ───
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // ─── Set system UI style ───
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // ─── Global Screen Protection ───
  if (!kIsWeb) {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageWithBlur();
    } catch (_) {}
  }

  runApp(
    ProviderScope(
      overrides: [
        firestoreProvider.overrideWithValue(firestore),
      ],
      child: const XMSystemApp(),
    ),
  );
}

/// Root application widget
class XMSystemApp extends ConsumerWidget {
  const XMSystemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Listener(
      onPointerDown: (_) => ref.read(sessionManagerProvider).userInteracted(),
      behavior: HitTestBehavior.translucent,
      child: MaterialApp.router(
        title: 'XM System',
        debugShowCheckedModeBanner: false,
        theme: XMTheme.lightTheme,
        darkTheme: XMTheme.darkTheme,
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        routerConfig: router,
      ),
    );
  }
}
