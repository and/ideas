import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'providers/app_provider.dart';
import 'screens/collections_screen.dart';
import 'screens/presentation_screen.dart';
import 'models/collection.dart';
import 'models/photo_item.dart';
import 'services/photo_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: const SafeGalleryApp(),
    ),
  );
}

class SafeGalleryApp extends StatefulWidget {
  const SafeGalleryApp({super.key});

  @override
  State<SafeGalleryApp> createState() => _SafeGalleryAppState();
}

class _SafeGalleryAppState extends State<SafeGalleryApp> {
  Collection? _sharedCollection;

  @override
  void initState() {
    super.initState();
    _initSharing();
  }

  void _initSharing() {
    // Handle shared media files when app is opened from share sheet
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
      }
    });

    // Handle shared media files while app is already running
    ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
      }
    });
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    // Convert shared files to PhotoItems
    final photoItems = files
        .where((file) => file.type == SharedMediaType.IMAGE)
        .map((file, index) => MapEntry(
              index,
              PhotoItem(
                id: 'shared_${DateTime.now().millisecondsSinceEpoch}_$index',
                path: file.path,
                addedAt: DateTime.now(),
                order: index,
              ),
            ))
        .values
        .toList();

    if (photoItems.isEmpty) return;

    // Create temporary collection for shared photos
    final collection = Collection(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Shared Photos',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      photos: photoItems,
    );

    setState(() {
      _sharedCollection = collection;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final settings = provider.settings;

    // Determine brightness based on theme mode
    Brightness brightness;
    switch (settings.themeMode) {
      case ThemeMode.light:
        brightness = Brightness.light;
        break;
      case ThemeMode.dark:
        brightness = Brightness.dark;
        break;
      default:
        brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }

    if (Platform.isIOS) {
      return CupertinoApp(
        title: 'Safe Gallery',
        theme: CupertinoThemeData(
          brightness: brightness,
          primaryColor: CupertinoColors.activeBlue,
        ),
        home: _sharedCollection != null
            ? PresentationScreen(collection: _sharedCollection!)
            : const CollectionsScreen(),
        debugShowCheckedModeBanner: false,
      );
    } else {
      return MaterialApp(
        title: 'Safe Gallery',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        home: _sharedCollection != null
            ? PresentationScreen(collection: _sharedCollection!)
            : const CollectionsScreen(),
        debugShowCheckedModeBanner: false,
      );
    }
  }
}
