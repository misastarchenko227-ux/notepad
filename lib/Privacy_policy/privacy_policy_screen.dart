// lib/Privacy_policy/privacy_policy_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Privacy_policy.dart'; // <-- единственный импорт данных, hide больше не нужен

class PrivacyPolicyScreen extends StatelessWidget {
  final List<PrivacyPolicySection> sections;

  const PrivacyPolicyScreen({
    super.key,
    required this.sections,
  });

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Политика конфиденциальности')),
      body: sections.isEmpty
          ? const Center(child: Text('Текст отсутствует'))
          : SelectionArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, index) => _SectionView(
            section: sections[index],
            onLinkTap: _openLink,
          ),
        ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  final PrivacyPolicySection section;
  final void Function(String url) onLinkTap;

  const _SectionView({required this.section, required this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        _LinkifiedText(
          text: section.body,
          onLinkTap: onLinkTap,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _LinkifiedText extends StatefulWidget {
  final String text;
  final void Function(String url) onLinkTap;
  final TextStyle? style;

  const _LinkifiedText({
    required this.text,
    required this.onLinkTap,
    this.style,
  });

  @override
  State<_LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<_LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = widget.style?.copyWith(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    );

    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final segments = LinkTextParser.parse(widget.text);

    return RichText(
      text: TextSpan(
        children: segments.map((segment) {
          if (!segment.isLink) {
            return TextSpan(text: segment.text, style: widget.style);
          }
          final recognizer = TapGestureRecognizer()
            ..onTap = () => widget.onLinkTap(segment.text);
          _recognizers.add(recognizer);
          return TextSpan(
            text: segment.text,
            style: linkStyle,
            recognizer: recognizer,
          );
        }).toList(),
      ),
    );
  }
}