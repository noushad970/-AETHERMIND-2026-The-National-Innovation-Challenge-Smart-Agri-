import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// One text in both languages.
typedef _Text = (String en, String bn);

/// The website's front page: navigation bar, hero banner, features, steps,
/// language choice and footer.
///
/// It only draws what it is given, so it needs no providers.
class LandingView extends StatefulWidget {
  const LandingView({
    super.key,
    required this.isBn,
    required this.isSignedIn,
    required this.onToggleLanguage,
    required this.onLogin,
    required this.heroBackground,
  });

  static const double maxContentWidth = 1180;

  final bool isBn;

  /// A signed-in visitor is offered the dashboard instead of a login.
  final bool isSignedIn;

  final VoidCallback onToggleLanguage;
  final VoidCallback onLogin;

  /// Artwork painted behind the hero banner.
  final Widget heroBackground;

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView> {
  static const double _gap = 16;

  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _stepsKey = GlobalKey();

  static const List<(IconData, _Text, _Text)> _features = [
    (
      Icons.qr_code_scanner_rounded,
      ('AI disease detection', 'এআই রোগ নির্ণয়'),
      (
        'Upload a leaf photo to get the likely disease and treatment steps.',
        'পাতার ছবি দিয়ে সম্ভাব্য রোগ ও চিকিৎসার ধাপ জানুন।',
      ),
    ),
    (
      Icons.psychology_outlined,
      ('AI farm advisor', 'এআই কৃষি পরামর্শ'),
      (
        'Ask farming questions in Bangla or English.',
        'বাংলা বা ইংরেজিতে চাষাবাদের প্রশ্ন করুন।',
      ),
    ),
    (
      Icons.cloud_outlined,
      ('Weather', 'আবহাওয়া'),
      (
        'See current conditions, the forecast and advice for your area.',
        'আপনার এলাকার বর্তমান আবহাওয়া, পূর্বাভাস ও পরামর্শ দেখুন।',
      ),
    ),
    (
      Icons.water_drop_outlined,
      ('Smart irrigation', 'স্মার্ট সেচ'),
      (
        'Plan watering from your soil type, crop and land size.',
        'মাটির ধরন, ফসল ও জমির পরিমাণ থেকে সেচের পরিকল্পনা করুন।',
      ),
    ),
    (
      Icons.storefront_outlined,
      ('Market prices', 'বাজার দর'),
      (
        'Check crop and produce prices before you sell.',
        'বিক্রির আগে ফসল ও পণ্যের দাম দেখে নিন।',
      ),
    ),
    (
      Icons.trending_up_rounded,
      ('Yield forecaster', 'ফলন পূর্বাভাস'),
      (
        'Estimate the harvest, costs and profit of a season.',
        'মৌসুমের ফলন, খরচ ও লাভের হিসাব অনুমান করুন।',
      ),
    ),
    (
      Icons.grass_rounded,
      ('Crop tracking', 'ফসল ট্র্যাকিং'),
      (
        'Follow the growth stage and daily tasks of every field.',
        'প্রতিটি জমির বৃদ্ধির ধাপ ও দৈনিক কাজ অনুসরণ করুন।',
      ),
    ),
    (
      Icons.pets_outlined,
      ('Livestock and poultry', 'গবাদিপশু ও পোলট্রি'),
      (
        'Keep daily checklists and health records for your animals.',
        'পশুপাখির দৈনিক চেকলিস্ট ও স্বাস্থ্যের তথ্য রাখুন।',
      ),
    ),
    (
      Icons.set_meal_outlined,
      ('Fish farming', 'মৎস্য চাষ'),
      (
        'Manage ponds with feeding and care advice.',
        'খাবার ও পরিচর্যার পরামর্শ নিয়ে পুকুর পরিচালনা করুন।',
      ),
    ),
    (
      Icons.account_balance_wallet_outlined,
      ('Farm accounts', 'খামারের হিসাব'),
      (
        'Record expenses and see where the money goes.',
        'খরচ লিখে রাখুন এবং কোথায় কত ব্যয় হচ্ছে দেখুন।',
      ),
    ),
    (
      Icons.local_library_outlined,
      ('Crop library', 'ফসল লাইব্রেরি'),
      (
        'Read growing guides for the crops you plant.',
        'আপনার ফসলের চাষ পদ্ধতির নির্দেশিকা পড়ুন।',
      ),
    ),
    (
      Icons.forum_outlined,
      ('Farmer community', 'কৃষক ফিড'),
      (
        'Share updates and questions with other farmers.',
        'অন্য কৃষকদের সাথে খবর ও প্রশ্ন শেয়ার করুন।',
      ),
    ),
  ];

  static const List<(_Text, _Text)> _steps = [
    (
      ('Sign in', 'লগইন করুন'),
      (
        'Open your account or create a new one.',
        'আপনার অ্যাকাউন্টে ঢুকুন অথবা নতুন অ্যাকাউন্ট খুলুন।',
      ),
    ),
    (
      ('Add your farm', 'আপনার খামার যোগ করুন'),
      (
        'Register crops, cattle and fish ponds to track them.',
        'ফসল, গবাদিপশু ও পুকুর যোগ করে নজরে রাখুন।',
      ),
    ),
    (
      ('Decide with advice', 'পরামর্শ নিয়ে সিদ্ধান্ত নিন'),
      (
        'Scan leaves, ask the AI and check the weather first.',
        'আগে পাতা স্ক্যান করুন, এআই-কে জিজ্ঞাসা করুন ও আবহাওয়া দেখুন।',
      ),
    ),
  ];

  String _t(_Text text) => widget.isBn ? text.$2 : text.$1;

  String get _loginLabel => widget.isSignedIn
      ? _t(('Open dashboard', 'ড্যাশবোর্ড খুলুন'))
      : _t(('Login', 'লগইন'));

  /// The other language, written in that language.
  String get _otherLanguage => widget.isBn ? 'English' : 'বাংলা';

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  static const TextStyle _buttonText = TextStyle(
    fontFamily: 'NotoSansBengali',
    fontWeight: FontWeight.bold,
    fontSize: 15,
  );

  ButtonStyle _goldButton(double height) => FilledButton.styleFrom(
    backgroundColor: AppTheme.accentAmber,
    foregroundColor: AppTheme.textPrimary,
    minimumSize: Size(0, height),
    padding: const EdgeInsets.symmetric(horizontal: 22),
    textStyle: _buttonText,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final total = constraints.maxWidth;
          final side = math.max(
            total < 600 ? 16.0 : 32.0,
            (total - LandingView.maxContentWidth) / 2,
          );
          final width = total - side * 2;

          return Column(
            children: [
              _navigationBar(side, total),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _hero(side, width),
                      _section(
                        key: _featuresKey,
                        side: side,
                        title: (
                          'Everything your farm needs',
                          'আপনার খামারের সব প্রয়োজন',
                        ),
                        subtitle: (
                          'Crops, livestock and fish in one assistant.',
                          'ফসল, গবাদিপশু ও মাছ চাষ এক সহকারীতেই।',
                        ),
                        child: _featureGrid(context, width),
                      ),
                      _section(
                        key: _stepsKey,
                        side: side,
                        title: ('How it works', 'যেভাবে কাজ করে'),
                        subtitle: (
                          'Three steps from your field to a better decision.',
                          'মাঠ থেকে সঠিক সিদ্ধান্তে পৌঁছানোর তিনটি ধাপ।',
                        ),
                        child: _stepGrid(context, width),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(side, 48, side, 48),
                        child: _callToAction(width),
                      ),
                      _footer(side),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _navigationBar(double side, double total) {
    final wide = total >= 900;
    final compact = total < 600;
    final linkStyle = TextButton.styleFrom(
      foregroundColor: Colors.white,
      textStyle: _buttonText,
    );

    return Material(
      color: AppTheme.primaryGreenDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: side, vertical: 12),
          child: Row(
            children: [
              _logo(36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Smart Agri BD',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 16 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (wide) ...[
                TextButton(
                  key: const ValueKey('landing-nav-features'),
                  style: linkStyle,
                  onPressed: () => _scrollTo(_featuresKey),
                  child: Text(_t(('Features', 'সুবিধাসমূহ'))),
                ),
                TextButton(
                  key: const ValueKey('landing-nav-steps'),
                  style: linkStyle,
                  onPressed: () => _scrollTo(_stepsKey),
                  child: Text(_t(('How it works', 'যেভাবে কাজ করে'))),
                ),
                const SizedBox(width: 12),
              ],
              TextButton(
                key: const ValueKey('landing-language'),
                style: linkStyle.copyWith(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                onPressed: widget.onToggleLanguage,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compact) ...[
                      const Icon(Icons.translate, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Text(_otherLanguage),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const ValueKey('landing-nav-login'),
                style: _goldButton(42),
                onPressed: widget.onLogin,
                child: Text(
                  compact && widget.isSignedIn
                      ? _t(('Open', 'খুলুন'))
                      : _loginLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo(double size) => ClipRRect(
    borderRadius: BorderRadius.circular(size / 4),
    child: Image.asset(
      'assets/app_logo.png',
      width: size,
      height: size,
      errorBuilder: (_, _, _) =>
          Icon(Icons.agriculture, color: Colors.white, size: size),
    ),
  );

  Widget _hero(double side, double width) {
    final sideBySide = width >= 860;

    return Stack(
      children: [
        Positioned.fill(child: widget.heroBackground),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreenDark.withValues(alpha: 0.95),
                  AppTheme.primaryGreenDark.withValues(alpha: 0.82),
                  AppTheme.primaryGreenDark.withValues(
                    alpha: sideBySide ? 0.3 : 0.75,
                  ),
                ],
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: sideBySide ? 520 : 440),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: side, vertical: 56),
            child: sideBySide
                ? Row(
                    children: [
                      Expanded(child: _headline(width)),
                      const SizedBox(width: 40),
                      SizedBox(width: 340, child: _highlights()),
                    ],
                  )
                : _headline(width),
          ),
        ),
      ],
    );
  }

  Widget _headline(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.spa, color: AppTheme.sunYellow, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _t((
                    'AI farm assistant for Bangladesh',
                    'বাংলাদেশের জন্য এআই কৃষি সহকারী',
                  )),
                  style: const TextStyle(
                    color: AppTheme.sunYellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _t((
            'Smarter farming for every field',
            'প্রতিটি জমির জন্য স্মার্ট চাষাবাদ',
          )),
          style: TextStyle(
            color: Colors.white,
            fontSize: width >= 860 ? 52 : (width >= 500 ? 40 : 32),
            height: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            _t((
              'Detect crop diseases, ask an AI advisor and plan irrigation, '
                  'weather and market decisions in one place.',
              'ফসলের রোগ শনাক্ত করুন, এআই পরামর্শ নিন এবং সেচ, আবহাওয়া ও '
                  'বাজার দর এক জায়গায় দেখুন।',
            )),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 17,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const ValueKey('landing-hero-login'),
              style: _goldButton(52),
              onPressed: widget.onLogin,
              icon: const Icon(Icons.login_rounded, size: 20),
              label: Text(_loginLabel),
            ),
            OutlinedButton.icon(
              key: const ValueKey('landing-hero-features'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70, width: 1.5),
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                textStyle: _buttonText,
              ),
              onPressed: () => _scrollTo(_featuresKey),
              icon: const Icon(Icons.arrow_downward_rounded, size: 20),
              label: Text(_t(('See features', 'সুবিধাগুলো দেখুন'))),
            ),
          ],
        ),
      ],
    );
  }

  /// The three headline features beside the hero text on wide windows.
  Widget _highlights() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (icon, title, body) in _features.take(3))
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.sunYellow, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t(title),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _t(body),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _section({
    required Key key,
    required double side,
    required _Text title,
    required _Text subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Padding(
      key: key,
      padding: EdgeInsets.fromLTRB(side, 48, side, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t(title),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(subtitle),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }

  /// Lays out [cards] in rows of [columns] cards of equal height.
  Widget _grid(List<Widget> cards, int columns) {
    return Column(
      children: [
        for (var start = 0; start < cards.length; start += columns)
          Padding(
            padding: EdgeInsets.only(top: start == 0 ? 0 : _gap),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = start; i < start + columns; i++) ...[
                    if (i > start) const SizedBox(width: _gap),
                    Expanded(
                      child: i < cards.length ? cards[i] : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _card(BuildContext context, Widget leading, _Text title, _Text body) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(height: 16),
          Text(
            _t(title),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(_t(body), style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _featureGrid(BuildContext context, double width) {
    final columns = width >= 1000
        ? 4
        : width >= 720
        ? 3
        : width >= 480
        ? 2
        : 1;
    final scheme = Theme.of(context).colorScheme;

    return _grid([
      for (final (icon, title, body) in _features)
        _card(
          context,
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryGreenLight.withValues(alpha: 0.16),
            child: Icon(icon, color: scheme.primary),
          ),
          title,
          body,
        ),
    ], columns);
  }

  Widget _stepGrid(BuildContext context, double width) {
    return _grid([
      for (final (index, (title, body)) in _steps.indexed)
        _card(
          context,
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            child: Text(widget.isBn ? '১২৩'[index] : '${index + 1}'),
          ),
          title,
          body,
        ),
    ], width >= 760 ? 3 : 1);
  }

  Widget _callToAction(double width) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _t(('Ready to start?', 'শুরু করতে প্রস্তুত?')),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t((
            'Use it in Bangla or English, and switch at any time.',
            'বাংলা বা ইংরেজিতে ব্যবহার করুন, যেকোনো সময় ভাষা বদলান।',
          )),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 15,
          ),
        ),
      ],
    );
    final button = FilledButton.icon(
      key: const ValueKey('landing-cta-login'),
      style: _goldButton(52),
      onPressed: widget.onLogin,
      icon: const Icon(Icons.login_rounded, size: 20),
      label: Text(_loginLabel),
    );

    return Container(
      padding: EdgeInsets.all(width >= 600 ? 40 : 24),
      decoration: BoxDecoration(
        gradient: AppTheme.paddyHeroGradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: width >= 700
          ? Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 24),
                button,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 20), button],
            ),
    );
  }

  Widget _footer(double side) {
    final faded = TextStyle(
      color: Colors.white.withValues(alpha: 0.78),
      height: 1.5,
    );

    return ColoredBox(
      color: AppTheme.primaryGreenDark,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: side, vertical: 32),
        child: Wrap(
          spacing: 48,
          runSpacing: 20,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Smart Agri BD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _t((
                    'Made for the farmers of Bangladesh.',
                    'বাংলাদেশের কৃষকদের জন্য তৈরি।',
                  )),
                  style: faded,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_in_talk_rounded,
                  color: AppTheme.sunYellow,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _t(('Krishi helpline: 16123', 'কৃষি হেল্পলাইন: ১৬১২৩')),
                    style: faded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
