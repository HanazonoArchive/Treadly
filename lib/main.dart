import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controllers/auth_controller.dart';
import 'controllers/cart/cart_controller.dart';
import 'controllers/profile/address_controller.dart';
import 'controllers/search/search_controller.dart';
import 'controllers/sync_controller.dart';
import 'core/app_theme.dart';
import 'core/backend_config.dart';
import 'core/firebase_options.dart';
import 'core/supabase_config.dart';
import 'views/auth/sign_in_view.dart';
import 'views/auth/sign_up_view.dart';
import 'views/home_view.dart';
import 'views/product_view.dart';
import 'views/search_input_view.dart';
import 'views/settings_view.dart';
import 'views/wallet_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('[Supabase] Initialization note: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Firebase] Initialized successfully.');
  } catch (e) {
    debugPrint('[Firebase] Initialization note: $e');
  }

  // Load persistent database preferences (Supabase vs Firebase)
  await BackendConfig.init();

  // Pre-register core controllers
  Get.put(SyncController(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(AddressController(), permanent: true);
  Get.put(SearchCatalogController(), permanent: true);
  Get.put(CartController(), permanent: true);

  runApp(DevicePreview(enabled: true, builder: (context) => const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Treadly',
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => HomeView()),
        GetPage(name: '/wallet', page: () => const WalletView()),
        GetPage(name: '/settings', page: () => const SettingsView()),
        GetPage(name: '/sign-in', page: () => const SignInView()),
        GetPage(name: '/sign-up', page: () => const SignUpView()),
        GetPage(name: '/product', page: () => const ProductView()),
        GetPage(name: '/search-input', page: () => const SearchInputView()),
      ],
      unknownRoute: GetPage(name: '/notfound', page: () => HomeView()),
    );
  }
}
