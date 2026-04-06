// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_coach/app.dart';
// import 'package:habit_coach/features/notifications/data/repositories/supabase_notification_repository.dart';
// import 'package:habit_coach/features/notifications/data/services/fcm_notification_service.dart';
// import 'package:habit_coach/firebase_options.dart';

/// T011 / T127: App entry point.
///
/// Initialisation order:
///   1. Flutter binding
///   2. Supabase (auth, realtime, edge functions)
///   3. Firebase (FCM) + background message handler
///   4. Isar — opened per-repository via lazy initialization in T034
///
/// Environment variables are read from the build environment (`--dart-define`).
/// Never hard-code credentials here.

/// Top-level background message handler (must be top-level, not a closure).
/// NOTE: Commented out - Firebase not yet implemented
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Background messages are handled by the OS notification tray.
//   // No additional processing needed here.
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialisation.
  // Values injected at build time via:
  //   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // Firebase initialisation (FCM push notifications).
  // NOTE: Commented out - Firebase not yet implemented
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background message handler before the app starts.
  // NOTE: Commented out - Firebase not yet implemented
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // T137: RevenueCat SDK initialization.
  // NOTE: Commented out - RevenueCat not yet implemented
  // API keys injected at build time via --dart-define.
  // final rcApiKey =
  //     const String.fromEnvironment('REVENUECAT_IOS_KEY').isNotEmpty
  //         ? const String.fromEnvironment('REVENUECAT_IOS_KEY')
  //         : const String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  // if (rcApiKey.isNotEmpty) {
  //   await rc.Purchases.configure(rc.PurchasesConfiguration(rcApiKey));
  //   rc.Purchases.setLogLevel(rc.LogLevel.info);
  // }

  // T127: FCM service is initialised per-user after auth in HabitCoachApp.
  // NOTE: Commented out - Firebase/FCM not yet implemented
  // Expose it as a singleton so the router can access the initial message.
  // final fcmService = FCMNotificationService(SupabaseNotificationRepository());

  runApp(
    const ProviderScope(overrides: [], child: HabitCoachApp()),
  );
}
