import 'dart:async';
import 'package:caterchain_test/screens/complaints_sales_screen.dart';
import 'package:caterchain_test/screens/sales_rep_home_screen.dart';
import 'package:caterchain_test/screens/supplier_links_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user.dart';
import 'models/complaint_adapter.dart';
import 'models/complaint.dart' hide ComplaintAdapter;
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'providers/providers.dart';
import 'providers/order_provider.dart';
import 'screens/profile_sales_screen.dart';
import 'screens/edit_catalog_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(ComplaintAdapter());
  await Hive.openBox<User>('users');
  await Hive.openBox<Complaint>('complaints');
  runZonedGuarded(() {

    FlutterError.onError = (FlutterErrorDetails details) {
      // Preserve the default behaviour (prints to console in debug).
      FlutterError.presentError(details);
      // Also print stack/exception explicitly so flutter run shows it.
      try {
        print('FlutterError caught by FlutterError.onError: ${details.exceptionAsString()}');
        print(details.stack);
      } catch (_) {}
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Ошибка приложения')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Произошла ошибка во время выполнения. Проверьте консоль/терминал для стека вызовов.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      runApp(const MyApp());
                    },
                    child: const Text('Перезапустить приложение'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    };

    runApp(const MyApp());
  }, (error, stack) {
    // Log uncaught zone errors to the terminal to make them easy to copy.
    print('Uncaught zone error: $error');
    print(stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => SupplierLinkProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CaterChain SCP',
        theme: ThemeData(
          primaryColor: const Color(0xFF6B8E23),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF6B8E23),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF6B8E23),
            unselectedItemColor: Colors.grey,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const MainApp(),
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Пытаемся загрузить сохраненного пользователя
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadSavedUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoggedIn) {
          return const MainApp();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // Загружаем данные при входе
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final role = (userProvider.currentUser?.role ?? '').toLowerCase();
    final bool isSales = role == 'sales_rep';

    // consumer screens
    final List<Widget> consumerScreens = [
      const HomeScreen(),
      const ChatScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    final List<Widget> salesScreens = [
      const SalesRepHomeScreen(),
      const ChatScreen(),
      const ComplaintsSalesScreen(),
      const EditCatalogScreen(),
      const ProfileSalesScreen(),
    ];

    final List<Widget> _screens = isSales ? salesScreens : consumerScreens;

    // Ensure currentIndex is within bounds (role switch can leave an out-of-range index)
    final int rawIndex = navigationProvider.currentIndex;
    final int safeIndex = (rawIndex < 0 || rawIndex >= _screens.length) ? 0 : rawIndex;

    return Scaffold(
      body: _screens[safeIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: safeIndex,
        onTabTapped: (index) {
          navigationProvider.navigateTo(index);
        },
        isSales: isSales, // ← pass role here
      ),
    );
  }
}