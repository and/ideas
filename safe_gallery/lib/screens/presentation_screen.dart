import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/collection.dart';
import '../providers/app_provider.dart';
import '../services/lock_service.dart';

class PresentationScreen extends StatefulWidget {
  final Collection collection;
  final int initialIndex;

  const PresentationScreen({
    super.key,
    required this.collection,
    this.initialIndex = 0,
  });

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  late int _currentIndex;
  Timer? _autoAdvanceTimer;
  final LockService _lockService = LockService();
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addObserver(this);

    // Enter presentation mode
    _lockService.enterPresentationMode();

    // Set up auto-advance if enabled
    _setupAutoAdvance();

    // Set up auto-lock timer if enabled
    _setupAutoLockTimer();

    // Hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _autoAdvanceTimer?.cancel();
    _lockService.exitPresentationMode();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // CRITICAL: Lock device when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!_isExiting) {
        _lockDevice();
      }
    }
  }

  void _setupAutoAdvance() {
    final settings = context.read<AppProvider>().settings;
    if (settings.autoAdvance) {
      _startAutoAdvance(settings.autoAdvanceInterval);
    }
  }

  void _setupAutoLockTimer() {
    final settings = context.read<AppProvider>().settings;
    if (settings.autoLockEnabled) {
      _lockService.startAutoLockTimer(settings.autoLockMinutes);
    }
  }

  void _startAutoAdvance(int seconds) {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(Duration(seconds: seconds), (timer) {
      if (mounted) {
        _goToNext();
      }
    });
  }

  void _resetAutoLockTimer() {
    final settings = context.read<AppProvider>().settings;
    if (settings.autoLockEnabled) {
      _lockService.resetAutoLockTimer(settings.autoLockMinutes);
    }
  }

  void _goToNext() {
    final nextIndex = (_currentIndex + 1) % widget.collection.photos.length;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPrevious() {
    final previousIndex = (_currentIndex - 1 + widget.collection.photos.length) %
                         widget.collection.photos.length;
    _pageController.animateToPage(
      previousIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _lockDevice() {
    _lockService.lockDevice();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppProvider>().settings;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Lock device instead of allowing back navigation
          _lockDevice();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            _resetAutoLockTimer();
          },
          onHorizontalDragEnd: (details) {
            _resetAutoLockTimer();
          },
          child: Stack(
            children: [
              // Photo viewer with infinite loop
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index % widget.collection.photos.length;
                  });
                  _resetAutoLockTimer();
                },
                itemCount: null, // Infinite scroll
                itemBuilder: (context, index) {
                  final photoIndex = index % widget.collection.photos.length;
                  final photo = widget.collection.photos[photoIndex];

                  return InteractiveViewer(
                    panEnabled: settings.pinchToZoom,
                    scaleEnabled: settings.pinchToZoom,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.file(
                        File(photo.path),
                        fit: BoxFit.contain,
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            child: child,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, color: Colors.white, size: 48),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              // Photo counter overlay
              if (settings.showPhotoCounter)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} of ${widget.collection.photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

              // Tap zones for navigation (left/right thirds)
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _goToPrevious();
                          _resetAutoLockTimer();
                        },
                        behavior: HitTestBehavior.translucent,
                      ),
                    ),
                    Expanded(child: Container()), // Center third - no action
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _goToNext();
                          _resetAutoLockTimer();
                        },
                        behavior: HitTestBehavior.translucent,
                      ),
                    ),
                  ],
                ),
              ),

              // Exit button (long press to lock and exit)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: GestureDetector(
                  onLongPress: () {
                    _isExiting = true;
                    _lockDevice();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
