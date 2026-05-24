import 'dart:async';
import 'dart:io'; // Обязательно для проверки сети
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Не забудь добавить в pubspec.yaml
import 'main.dart'; // Проверь, что MyNotesPage импортирован правильно

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

  // Скрываем баннер, если нет интернета
  Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() => _isVisible = true);
      }
    } on SocketException catch (_) {
      setState(() => _isVisible = false);
    }
  }

  // Функция для открытия твоего ТГ-канала
  Future<void> _launchTelegram() async {
    final Uri url = Uri.parse('https://t.me/uncorelabs');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Не удалось открыть ссылку");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _launchTelegram,
      child: Container(
        width: double.infinity,
        height: 65,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12), // Отступы от краев
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2481CC), Color(0xFF33A1DE)], // Цвета Telegram
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Row(
            children: [
              // Левая часть: Иконка
              Container(
                width: 65,
                height: 65,
                color: Colors.white.withOpacity(0.1),
                child: const Icon(Icons.telegram, color: Colors.white, size: 35),
              ),
              const SizedBox(width: 12),
              // Центр: Текст
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ПРИСОЕДИНЯЙСЯ К НАМ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Новости Unicore Labs в Telegram",
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Правая часть: Стрелочка
              const Icon(Icons.chevron_right, color: Colors.white54),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}