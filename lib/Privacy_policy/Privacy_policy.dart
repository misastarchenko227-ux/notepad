// lib/Privacy_policy/Privacy_policy.dart

/// Одна секция политики конфиденциальности: заголовок + текст.
///
/// immutable-класс (final поля) — секция не меняется после создания.
/// Это единственное место в проекте, где определён PrivacyPolicySection —
/// раньше у тебя было 3 копии этого класса в разных файлах, из-за чего
/// компилятор не мог понять, какой из них использовать.
class PrivacyPolicySection {
  final String title;
  final String body;

  const PrivacyPolicySection({
    required this.title,
    required this.body,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PrivacyPolicySection &&
              runtimeType == other.runtimeType &&
              title == other.title &&
              body == other.body;

  @override
  int get hashCode => Object.hash(title, body);
}

/// Кусок текста внутри секции: обычный текст или ссылка.
class TextSegment {
  final String text;
  final bool isLink;

  const TextSegment({required this.text, required this.isLink});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TextSegment &&
              runtimeType == other.runtimeType &&
              text == other.text &&
              isLink == other.isLink;

  @override
  int get hashCode => Object.hash(text, isLink);
}

/// Разбивает текст на сегменты: обычный текст / ссылка.
/// Статический класс без состояния — чистая функция, тестируется
/// без виджетов.
class LinkTextParser {
  const LinkTextParser._();

  static final RegExp _urlPattern = RegExp(r'(https?:\/\/[^\s]+)');

  static List<TextSegment> parse(String text) {
    if (text.isEmpty) return [];

    final segments = <TextSegment>[];
    var lastEnd = 0;

    for (final match in _urlPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        segments.add(TextSegment(
          text: text.substring(lastEnd, match.start),
          isLink: false,
        ));
      }
      segments.add(TextSegment(text: match.group(0)!, isLink: true));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      segments.add(TextSegment(text: text.substring(lastEnd), isLink: false));
    }

    return segments;
  }
}

/// Статический источник текста политики конфиденциальности.
///
/// Не репозиторий с абстрактным интерфейсом — данные захардкожены,
/// смена источника не планируется (YAGNI).
class PrivacyPolicyContent {
  const PrivacyPolicyContent._();

  static const List<PrivacyPolicySection> sections = [
    PrivacyPolicySection(
      title: '1. Общие положения',
      body:
      'Разработчик не собирает, не хранит и не обрабатывает какие-либо '
          'персональные данные пользователей самостоятельно. Единственный '
          'сторонний сервис, интегрированный в Приложение, — рекламная сеть '
          'Yandex Advertising Network (Yandex Mobile Ads SDK), используемая '
          'исключительно для показа рекламных объявлений.',
    ),
    PrivacyPolicySection(
      title: '2. Кто обрабатывает данные',
      body:
      'Обработку данных, связанных с показом рекламы, осуществляет '
          'ООО «ЯНДЕКС» как самостоятельный оператор персональных данных — '
          'в соответствии со своей собственной Политикой конфиденциальности: '
          'https://yandex.ru/legal/confidential/',
    ),
    PrivacyPolicySection(
      title: '3. Какие данные собирает Yandex Ads',
      body:
      'Рекламный идентификатор устройства (Advertising ID / GAID / IDFA), '
          'IP-адрес, электронные данные устройства, дату и время обращения '
          'к рекламе, данные о взаимодействии с рекламой, приблизительную '
          'геолокацию, технические сведения о приложении.',
    ),
    PrivacyPolicySection(
      title: '4. Цель сбора данных в рамках Приложения',
      body:
      'Показ рекламных объявлений внутри Приложения, ограничение частоты '
          'показа одного и того же объявления, аналитика эффективности '
          'рекламы на стороне Яндекса.',
    ),
    PrivacyPolicySection(
      title: '5. Отказ от персонализированной рекламы',
      body:
      'Вы можете ограничить рекламный идентификатор устройства через '
          'настройки Android/iOS, а также управлять настройками '
          'персонализированной рекламы Яндекса: https://yandex.ru/tune/adv',
    ),
  ];
}