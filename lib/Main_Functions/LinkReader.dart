import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Один "кусок" текста после разбора: либо обычный текст, либо ссылка.
class TextSegment {
  final String text;
  final bool isLink;

  const TextSegment(this.text, {this.isLink = false});
}

/// Разбирает произвольный текст на текстовые куски и ссылки.
/// Ничего не знает про Flutter-виджеты — только парсинг строки.
class LinkParser {
  // http(s)://..., www.something.xx, а также голые домены вида youtube.com/...
  static final RegExp _urlPattern = RegExp(
    r'((https?:\/\/)|(www\.))[^\s]+',
    caseSensitive: false,
  );

  static List<TextSegment> parse(String text) {
    final List<TextSegment> segments = [];
    int lastEnd = 0;

    for (final match in _urlPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        segments.add(TextSegment(text.substring(lastEnd, match.start)));
      }

      String rawUrl = match.group(0)!;
      // отрезаем случайную пунктуацию на конце ("...ссылка.", "(ссылка)")
      final trailingPunctuation = RegExp(r'[.,!?;:\)\]]+$');
      final trailingMatch = trailingPunctuation.firstMatch(rawUrl);
      String cleanUrl = rawUrl;
      String tail = '';
      if (trailingMatch != null) {
        cleanUrl = rawUrl.substring(0, trailingMatch.start);
        tail = rawUrl.substring(trailingMatch.start);
      }

      segments.add(TextSegment(cleanUrl, isLink: true));
      if (tail.isNotEmpty) segments.add(TextSegment(tail));

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      segments.add(TextSegment(text.substring(lastEnd)));
    }

    return segments.isEmpty ? [TextSegment(text)] : segments;
  }
}

/// Виджет, который показывает текст с кликабельными ссылками.
/// StatefulWidget нужен, чтобы правильно освобождать TapGestureRecognizer —
/// их нельзя пересоздавать на каждый build без утечки памяти.
class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;

  const LinkifiedText({
    super.key,
    required this.text,
    this.textStyle,
    this.linkStyle,
  });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    String normalized = url;
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // recognizers с прошлого build больше не нужны — освобождаем перед пересборкой
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final segments = LinkParser.parse(widget.text);
    final defaultStyle = widget.textStyle ?? DefaultTextStyle.of(context).style;
    final defaultLinkStyle = widget.linkStyle ??
        defaultStyle.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        );

    return RichText(
      text: TextSpan(
        children: segments.map((segment) {
          if (!segment.isLink) {
            return TextSpan(text: segment.text, style: defaultStyle);
          }
          final recognizer = TapGestureRecognizer()
            ..onTap = () => _openLink(segment.text);
          _recognizers.add(recognizer);
          return TextSpan(
            text: segment.text,
            style: defaultLinkStyle,
            recognizer: recognizer,
          );
        }).toList(),
      ),
    );
  }
}