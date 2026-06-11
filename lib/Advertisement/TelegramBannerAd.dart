import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Не забудь добавить в pubspec.yaml

class TelegramBannerAd extends StatelessWidget {
  const TelegramBannerAd({super.key});

  Future<void> _launchTelegram() async {
    final Uri url = Uri.parse('https://t.me/uncorelabs');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Не удалось открыть ссылку");
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double height = constraints.maxWidth * 0.16;
        final double iconSize = height * 0.5;
        final double fontSize = constraints.maxWidth * 0.033;
        final double subFontSize = constraints.maxWidth * 0.027;

        return GestureDetector(
          onTap: _launchTelegram,
          child: Container(
            width: double.infinity,
            height: height,
            margin: EdgeInsets.fromLTRB(
              constraints.maxWidth * 0.03,
              0,
              constraints.maxWidth * 0.03,
              constraints.maxWidth * 0.03,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2481CC), Color(0xFF33A1DE)],
              ),
              borderRadius: BorderRadius.circular(height * 0.25),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(height * 0.25),
              child: Row(
                children: [
                  Container(
                    width: height,
                    height: height,
                    color: Colors.white.withOpacity(0.1),
                    child: Icon(Icons.telegram,
                        color: Colors.white, size: iconSize),
                  ),
                  SizedBox(width: constraints.maxWidth * 0.03),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ПРИСОЕДИНЯЙСЯ К НАМ",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "Новости Unicore Labs в Telegram",
                          style: TextStyle(
                              color: Colors.white70, fontSize: subFontSize),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: Colors.white54, size: iconSize * 0.8),
                  SizedBox(width: constraints.maxWidth * 0.03),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}