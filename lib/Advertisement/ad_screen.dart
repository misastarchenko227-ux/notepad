import 'dart:async';
import 'dart:io'; // Обязательно для проверки сети
import 'package:flutter/material.dart';
import 'package:notepad/Advertisement/TelegramBannerAd.dart';


// 1. ПОЛНОЭКРАННАЯ РЕКЛАМА (ЗАСТАВКА)
/*
class AdScreen extends StatefulWidget {
  const AdScreen({super.key});

  @override
  State<AdScreen> createState() => _AdScreenState();
}

class _AdScreenState extends State<AdScreen> {
  bool _canClose = false;
  int _secondsRemaining = 5;
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAndStart();
  }

  // Проверка интернета перед показом рекламы
  Future<void> _checkAndStart() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() => _isLoading = false);
        _startTimer();
      }
    } on SocketException catch (_) {
      _goToMain(); // Нет сети — сразу в приложение
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canClose = true);
        _timer?.cancel();
      }
    });
  }

  void _goToMain() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyNotesPage()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Colors.white);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // РЕКЛАМНОЕ ПОЛОТНО (Замени ссылку на реальную или используй Image.asset)
          Center(
            child: Image.network(
              'https://via.placeholder.com/1080x1920?text=UNICORE+LABS+ADS',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, color: Colors.white24, size: 50),
                );
              },
            ),
          ),

          // КНОПКА ЗАКРЫТИЯ
          Positioned(
            top: 50,
            right: 20,
            child: _canClose
                ? IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 40),
              onPressed: _goToMain,
            )
                : Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Закрыть через $_secondsRemaining",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/

// 2. МАЛЕНЬКИЙ БАННЕР (STICKY BANNER)
class MiniBannerAd extends StatefulWidget {
  const MiniBannerAd({super.key});

  @override
  State<MiniBannerAd> createState() => _MiniBannerAdState();
}

class _MiniBannerAdState extends State<MiniBannerAd> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _checkInternet();
  }
  Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (!mounted) return; // виджет мог быть удалён, пока шёл запрос — выходим без setState

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() => _isVisible = true);
      }
    } on SocketException catch (_) {
      if (!mounted) return; // та же проверка нужна и в catch-блоке — ошибка тоже приходит асинхронно

      setState(() => _isVisible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    // Сюда добавляешь новые баннеры
    return const Column(
      children: [
        TelegramBannerAd(),
        // GooglePlayBannerAd(),
        // DiscordBannerAd(),
      ],
    );
  }
}