// // import 'package:flutter/material.dart';

// // void main() {
// //   runApp(const MyApp());
// // }

// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});

// //   // This widget is the root of your application.
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Flutter Demo',
// //       theme: ThemeData(
// //         // This is the theme of your application.
// //         //
// //         // TRY THIS: Try running your application with "flutter run". You'll see
// //         // the application has a purple toolbar. Then, without quitting the app,
// //         // try changing the seedColor in the colorScheme below to Colors.green
// //         // and then invoke "hot reload" (save your changes or press the "hot
// //         // reload" button in a Flutter-supported IDE, or press "r" if you used
// //         // the command line to start the app).
// //         //
// //         // Notice that the counter didn't reset back to zero; the application
// //         // state is not lost during the reload. To reset the state, use hot
// //         // restart instead.
// //         //
// //         // This works for code too, not just values: Most code changes can be
// //         // tested with just a hot reload.
// //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
// //       ),
// //       home: const MyHomePage(title: 'Flutter Demo Home Page'),
// //     );
// //   }
// // }

// // class MyHomePage extends StatefulWidget {
// //   const MyHomePage({super.key, required this.title});

// //   // This widget is the home page of your application. It is stateful, meaning
// //   // that it has a State object (defined below) that contains fields that affect
// //   // how it looks.

// //   // This class is the configuration for the state. It holds the values (in this
// //   // case the title) provided by the parent (in this case the App widget) and
// //   // used by the build method of the State. Fields in a Widget subclass are
// //   // always marked "final".

// //   final String title;

// //   @override
// //   State<MyHomePage> createState() => _MyHomePageState();
// // }

// // class _MyHomePageState extends State<MyHomePage> {
// //   int _counter = 0;

// //   void _incrementCounter() {
// //     setState(() {
// //       // This call to setState tells the Flutter framework that something has
// //       // changed in this State, which causes it to rerun the build method below
// //       // so that the display can reflect the updated values. If we changed
// //       // _counter without calling setState(), then the build method would not be
// //       // called again, and so nothing would appear to happen.
// //       _counter++;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     // This method is rerun every time setState is called, for instance as done
// //     // by the _incrementCounter method above.
// //     //
// //     // The Flutter framework has been optimized to make rerunning build methods
// //     // fast, so that you can just rebuild anything that needs updating rather
// //     // than having to individually change instances of widgets.
// //     return Scaffold(
// //       appBar: AppBar(
// //         // TRY THIS: Try changing the color here to a specific color (to
// //         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
// //         // change color while the other colors stay the same.
// //         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
// //         // Here we take the value from the MyHomePage object that was created by
// //         // the App.build method, and use it to set our appbar title.
// //         title: Text(widget.title),
// //       ),
// //       body: Center(
// //         // Center is a layout widget. It takes a single child and positions it
// //         // in the middle of the parent.
// //         child: Column(
// //           // Column is also a layout widget. It takes a list of children and
// //           // arranges them vertically. By default, it sizes itself to fit its
// //           // children horizontally, and tries to be as tall as its parent.
// //           //
// //           // Column has various properties to control how it sizes itself and
// //           // how it positions its children. Here we use mainAxisAlignment to
// //           // center the children vertically; the main axis here is the vertical
// //           // axis because Columns are vertical (the cross axis would be
// //           // horizontal).
// //           //
// //           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
// //           // action in the IDE, or press "p" in the console), to see the
// //           // wireframe for each widget.
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: <Widget>[
// //             const Text('You have pushed the button this many times:'),
// //             Text(
// //               '$_counter',
// //               style: Theme.of(context).textTheme.headlineMedium,
// //             ),
// //           ],
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: _incrementCounter,
// //         tooltip: 'Increment',
// //         child: const Icon(Icons.add),
// //       ), // This trailing comma makes auto-formatting nicer for build methods.
// //     );
// //   }
// // }



// import 'dart:typed_data';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:sodium/sodium.dart';

// import 'crypto/master_key.dart';
// import 'crypto/xchacha.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final sodium = await SodiumInit.init();
//   runApp(MyApp(sodium));
// }

// class MyApp extends StatefulWidget {
//   final Sodium sodium;
//   MyApp(this.sodium);

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   String status = "Running crypto test...";

//   @override
//   void initState() {
//     super.initState();
//     _testCrypto();
//   }

//   Future<void> _testCrypto() async {
//     final mkm = MasterKeyManager(widget.sodium);
//     final pw = "TestPassword123";

//     // 1. master key
//     final masterKey = mkm.generateMasterKey();

//     // 2. encrypt master key
//     final enc = await mkm.encryptMasterKey(
//       masterKey: masterKey,
//       password: pw,
//     );

//     // 3. decrypt master key
//     final decrypted = await mkm.decryptMasterKey(
//       encryptedMasterKeyHex: enc["encrypted_master_key_hex"]!,
//       password: pw,
//       keySaltB64: enc["key_salt_b64"]!,
//       nonceB64: enc["nonce_b64"]!,
//     );

//     // 4. derive keys
//     final fileSalt = widget.sodium.randombytes.buf(16);
//     final fileKey = mkm.deriveFileKey(masterKey, fileSalt);
//     final chunkKey = mkm.deriveChunkKey(fileKey, 0);

//     // 5. encrypt/decrypt chunk
//     final x = XChaCha(widget.sodium);
//     final message = Uint8List.fromList(utf8.encode("Hello Silvora Crypto"));
//     final encChunk = x.encrypt(message, chunkKey);
//     final decChunk = x.decrypt(encChunk["ciphertext"]!, encChunk["nonce"]!, chunkKey);

//     setState(() {
//       if (utf8.decode(decChunk) == "Hello Silvora Crypto" &&
//           const ListEquality().equals(masterKey, decrypted)) {
//         status = "CRYPTO OK ✓";
//       } else {
//         status = "CRYPTO FAILED ✗";
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(home: Scaffold(body: Center(child: Text(status))));
//   }
// }








// ----------------------------------------
// dev
// ----------------------------------------

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:cryptography/cryptography.dart';
// import 'crypto/master_key.dart';
// import 'crypto/xchacha.dart';
// import 'package:collection/collection.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatefulWidget {
//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   String _status = 'Running test...';

//   @override
//   void initState() {
//     super.initState();
//     _runTest();
//   }


//   Future<void> _runTest() async {
//     try {
//       final mkm = MasterKeyManager();
//       final password = 'TestPassword!234';
//       final masterKey = mkm.generateMasterKey();

//       final enc = await mkm.encryptMasterKey(masterKey: masterKey, password: password);

//       final dec = await mkm.decryptMasterKey(
//         encryptedMasterKeyHex: enc['encrypted_master_key_hex']!,
//         password: password,
//         keySaltB64: enc['key_salt_b64']!,
//         nonceB64: enc['nonce_b64']!,
//         macB64: enc['mac_b64']!,
//       );

//       final fileSalt = XChaCha().algorithm.newNonce().sublist(0, 16);
//       final fileKey = await mkm.deriveFileKey(masterKey, fileSalt);
//       final chunkKey = await mkm.deriveChunkKey(fileKey, 0);

//       // encrypt chunk
//       final message = utf8.encode('Hello Silvora');
//       final encChunk = await XChaCha().encrypt(message, chunkKey);
//       final decChunk = await XChaCha().decrypt(encChunk['ciphertext']!, encChunk['nonce']!, chunkKey, encChunk['mac']!);

//       final equal = const ListEquality().equals(masterKey, dec);
//       final chunkEqual = utf8.decode(decChunk) == 'Hello Silvora';

//       setState(() {
//         _status = (equal && chunkEqual) ? 'CRYPTO OK ✓' : 'CRYPTO FAIL ✗';
//       });
//     } catch (e, st) {
//       setState(() {
//         _status = 'ERROR: $e\n$st';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(body: Center(child: Text(_status))),
//     );
//   }
// }

// ---------------------------
// prod trail
// // ---------------------------
// import 'package:flutter/material.dart';

// import 'screens/login/login_screen.dart';
// import 'screens/home/home_screen.dart';
// import 'screens/upload/upload_screen.dart';

// void main() {
//   runApp(const SilvoraApp());
// }

// class SilvoraApp extends StatelessWidget {
//   const SilvoraApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Silvora',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         colorSchemeSeed: Colors.deepPurple,
//       ),

//       // FIRST SCREEN WHEN APP STARTS
//       home: const LoginScreen(),

//       // ROUTES AVAILABLE IN THE APP
//       routes: {
//         "/home": (context) => const HomeScreen(),
//         "/upload": (context) =>  UploadScreen(),
//       },
//     );
//   }
// }

// lib/main.dart
// // lib/main.dart
// import 'package:flutter/material.dart';
// import 'package:silvora_app/crypto/crypto_self_test.dart';
// // import 'package:silvora_app/crypto/crypto_self_test.dart';
// import 'package:silvora_app/screens/login/login_screen.dart';

// // import 'screens/upload/upload_screen.dart';

// Future<void> main() async {
//   // Required before using any plugins / async init.
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize libsodium (Android + iOS + Web) via sodium_libs.
//   // await SodiumService.init();
//   await CryptoSelfTest.run();

//   runApp(const SilvoraApp());
// }

// class SilvoraApp extends StatelessWidget {
//   const SilvoraApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Silvora',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         brightness: Brightness.dark,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF6C63FF),
//           brightness: Brightness.dark,
//         ),
//         useMaterial3: true,
//       ),
//       home: const LoginScreen(),
//     );
//   }
// }
//==============================================================================
// lib/main.dart

// import 'package:flutter/material.dart';
// import 'package:silvora_app/core/app_lifecycle_guard.dart';

// // Crypto
// import 'package:silvora_app/crypto/crypto_self_test.dart';

// // Screens (LIGHT first)
// import 'package:silvora_app/screens/login/login_screen.dart';
// import 'package:silvora_app/screens/login/register_screen.dart';

// // Screens (HEAVY – lazy loaded by routes)
// import 'package:silvora_app/screens/files/file_list_screen.dart';
// import 'package:silvora_app/screens/splash/splash_screen.dart';
// import 'package:silvora_app/state/secure_state.dart';

// Future<void> main() async {
//   // Required before any plugins / async init
//   WidgetsFlutterBinding.ensureInitialized();

//   // 🔐 Crypto sanity check (SAFE, fast)
//   await CryptoSelfTest.run();

//   // AppLifecycleGuard().init();
//   await SecureState.restoreSession();

//   runApp(const SilvoraApp());
// }

// class SilvoraApp extends StatelessWidget {
//   const SilvoraApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Silvora',
//       debugShowCheckedModeBanner: false,

//       // ─────────────────────────────
//       // THEME
//       // ─────────────────────────────
//       theme: ThemeData(
//         brightness: Brightness.dark,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF6C63FF),
//           brightness: Brightness.dark,
//         ),
//         useMaterial3: true,
//       ),

//       // ─────────────────────────────
//       // ROUTING (IMPORTANT)
//       // ─────────────────────────────
//       initialRoute: '/splash',

//       routes: {
//         '/splash': (_) => const SplashScreen(),
//         // Auth   
//         '/login': (_) => const LoginScreen(),
//         '/register': (_) => const RegisterScreen(),

//         // App (crypto + files loaded ONLY after login)
//         '/files': (_) => const FileListScreen(),
//       },
//     );
//   }
// }
// =========================================================
// import 'package:flutter/material.dart';

// import 'crypto/crypto_self_test.dart';
// import 'state/secure_state.dart';

// import 'screens/login/login_screen.dart';
// import 'screens/login/register_screen.dart';
// import 'screens/files/file_list_screen.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // 🔐 Crypto sanity check
//   await CryptoSelfTest.run();

//   // 🔑 Restore JWTs from secure storage
//   await SecureState.restoreSession();

//   runApp(const SilvoraApp());
// }

// class SilvoraApp extends StatelessWidget {
//   const SilvoraApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Silvora',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         brightness: Brightness.dark,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF6C63FF),
//           brightness: Brightness.dark,
//         ),
//         useMaterial3: true,
//       ),
//       initialRoute: '/login',
//       routes: {
//         '/login': (_) => const LoginScreen(),
//         '/register': (_) => const RegisterScreen(),
//         '/files': (_) => const FileListScreen(),
//       },
//     );
//   }
// }
// // =========================================================

// // main.dart
// import 'package:flutter/material.dart';

// import 'crypto/crypto_self_test.dart';
// import 'state/secure_state.dart';

// import 'screens/login/login_screen.dart';
// import 'screens/login/register_screen.dart';
// import 'screens/files/file_list_screen.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await CryptoSelfTest.run();
//   await SecureState.restoreSession();

//   runApp(const SilvoraApp());
// }

// class SilvoraApp extends StatelessWidget {
//   const SilvoraApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData.dark(useMaterial3: true),
//       initialRoute:
//           SecureState.accessToken == null ? '/login' : '/files',
//       routes: {
//         '/login': (_) => const LoginScreen(),
//         '/register': (_) => const RegisterScreen(),
//         '/files': (_) => const FileListScreen(),
//       },
//     );
//   }
// }
// =========================================================
// lib/main.dart
// import 'package:flutter/material.dart';

// // import 'crypto/crypto_self_test.dart';
// import 'state/secure_state.dart';

// import 'screens/login/login_screen.dart';
// import 'screens/login/register_screen.dart';
// import 'screens/files/file_list_screen.dart';
// class SilvoraApp extends StatefulWidget {
//   const SilvoraApp({super.key});

//   @override
//   State<SilvoraApp> createState() => _SilvoraAppState();
// }

// class _SilvoraAppState extends State<SilvoraApp>
//     with WidgetsBindingObserver {

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused) {
//       SecureState.onAppPaused();
//     } else if (state == AppLifecycleState.resumed) {
//       SecureState.onAppResumed();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData.dark(useMaterial3: true),
//       initialRoute:
//           SecureState.isAuthenticated ? '/files' : '/login',
//       routes: {
//         '/login': (_) => const LoginScreen(),
//         '/register': (_) => const RegisterScreen(),
//         '/files': (_) => const FileListScreen(),
//       },
//     );
//   }
// }
// ====================================================================
// // lib/main.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// import 'state/secure_state.dart';
// import 'crypto/crypto_self_test.dart';
//
// import 'screens/login/login_screen.dart';
// import 'screens/login/register_screen.dart';
// import 'screens/files/file_list_screen.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Optional: lock orientation (recommended for stability)
//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//   ]);
//
//   // Crypto sanity check (dev-time safety)
//   await CryptoSelfTest.run();
//
//   // Restore JWTs from secure storage
//   await SecureState.restoreSession();
//
//   runApp(const SilvoraApp());
// }
//
// class SilvoraApp extends StatefulWidget {
//   const SilvoraApp({super.key});
//
//   @override
//   State<SilvoraApp> createState() => _SilvoraAppState();
// }
//
// class _SilvoraAppState extends State<SilvoraApp>
//     with WidgetsBindingObserver {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//
//     // Mark activity on app start
//     SecureState.markUserActive();
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   // ─────────────────────────────────────────────
//   // APP LIFECYCLE → delegated to SecureState
//   // ─────────────────────────────────────────────
//   @override
// void didChangeAppLifecycleState(AppLifecycleState state) {
//   switch (state) {
//     case AppLifecycleState.resumed:
//       SecureState.onAppResumed();
//       break;
//
//     case AppLifecycleState.inactive:
//     case AppLifecycleState.paused:
//     case AppLifecycleState.hidden:
//       SecureState.onAppPaused();
//       break;
//
//     case AppLifecycleState.detached:
//       // App is terminating — no UI work here
//       break;
//   }
// }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       // Any tap = user is active
//       behavior: HitTestBehavior.translucent,
//       onTap: SecureState.markUserActive,
//       onPanDown: (_) => SecureState.markUserActive(),
//
//       child: MaterialApp(
//         title: 'Silvora',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData.dark(useMaterial3: true),
//
//         // 🔐 AUTH GATE
//         home: SecureState.isAuthenticated
//             ? const FileListScreen()
//             : const LoginScreen(),
//
//         routes: {
//           '/login': (_) => const LoginScreen(),
//           '/register': (_) => const RegisterScreen(),
//           '/files': (_) => const FileListScreen(),
//         },
//       ),
//     );
//   }
// }



// =======================================
// lib/main.dart
import 'package:flutter/material.dart';

import 'screens/login/login_screen.dart';
import 'screens/login/register_screen.dart';
import 'screens/files/file_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SilvoraApp());
}

class SilvoraApp extends StatelessWidget {
  const SilvoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),

      // ALWAYS start at login
      initialRoute: '/login',

      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/files': (_) => const FileListScreen(),
      },
    );
  }
}
