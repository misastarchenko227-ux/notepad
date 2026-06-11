import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notepad/Main_Screen/main.dart';

class UnicoreLoadingScreen extends StatefulWidget {
  const UnicoreLoadingScreen({super.key});

  @override
  State<UnicoreLoadingScreen> createState() => _UnicoreLoadingScreenState();
}

class _UnicoreLoadingScreenState extends State<UnicoreLoadingScreen> {
  double _progress = 0.0;
  Timer? _progressTimer;
  Timer? _pageTimer;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _imagePaths = [
    'assets/images/manual1.jpg',
    'assets/images/manual2.jpg',
    'assets/images/manual3.jpg',
    'assets/images/manual4.jpg',
    'assets/images/manual5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _startProgress();
    _startAutoScroll();
  }

  void _startProgress() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.01;
        } else {
          _progressTimer?.cancel();
        }
      });
    });
  }

  void _startAutoScroll() {
    _pageTimer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
      if (!mounted) return;

      if (_currentPage < _imagePaths.length - 1) {
        setState(() => _currentPage++);
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _pageTimer?.cancel();
        if (_progress >= 1.0) {
          _navigateToMain();
        } else {
          _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
            if (!mounted) return;
            setState(() => _progress += 0.01);
            if (_progress >= 1.0) {
              t.cancel();
              _navigateToMain();
            }
          });
        }
      }
    });
  }

  void _navigateToMain() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MyNotesPage()),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pageTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "UNICORE",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const Text(
                    "LABS",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _imagePaths.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        _imagePaths[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _imagePaths.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? const Color(0xFF2C3E50)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.auto_awesome_mosaic_outlined,
                          size: 16, color: Colors.blueGrey),
                      SizedBox(width: 10),
                      Text(
                        "Загрузка контента...",
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.waves, size: 16, color: Colors.blueGrey),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}