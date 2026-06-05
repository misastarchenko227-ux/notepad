import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notepad/Main_Screen/main.dart';



class UnicoreLoadingScreen extends StatefulWidget {
  const UnicoreLoadingScreen({super.key});

  @override
  State<UnicoreLoadingScreen> createState() => _UnicoreLoadingScreenState();

// УДАЛИЛ ОТСЮДА ЛИШНИЙ build(), который вызывал ошибку
}

class _UnicoreLoadingScreenState extends State<UnicoreLoadingScreen> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return; // Проверка, что экран еще существует
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.01;
        } else {
          _timer?.cancel();
          // Переход на главный экран приложения
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyNotesPage()), // Убедись, что MyApp импортирован правильно
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),

            // ЛОГОТИП
            Center(
              child: Column(
                children: [
                   Image.asset('assets/images/logo.png',width: 120, // Подбери нужный размер
                     height: 120,
                     fit: BoxFit.contain,),
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

            // ЗАГРУЗКА
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Container(
                    height: 40,
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) => AnimatedContainer(
                            duration: const Duration(milliseconds: 50),
                            width: constraints.maxWidth * _progress,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFBDC3C7), Color(0xFF2C3E50)],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            "${(_progress * 100).toInt()}%",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _progress > 0.5 ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.auto_awesome_mosaic_outlined, size: 16, color: Colors.blueGrey),
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}