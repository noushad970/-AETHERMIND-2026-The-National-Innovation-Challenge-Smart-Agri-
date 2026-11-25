import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/password_validator.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginObscure = true;

  // Register controllers
  final _regFormKey = GlobalKey<FormState>();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();
  bool _regObscure = true;
  bool _regConfirmObscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _regPassCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final isBn = context.read<LocaleProvider>().isBangla;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(
      _loginEmailCtrl.text.trim(),
      _loginPassCtrl.text,
      isBn: isBn,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppTheme.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_regFormKey.currentState!.validate()) return;
    final isBn = context.read<LocaleProvider>().isBangla;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      _regEmailCtrl.text.trim(),
      _regPassCtrl.text,
      _regNameCtrl.text.trim(),
      isBn: isBn,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppTheme.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _handleDemoLogin() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInAsDemoUser();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _loginEmailCtrl.text.trim());
    final isBn = context.read<LocaleProvider>().isBangla;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isBn ? 'পাসওয়ার্ড রিসেট' : 'Reset Password',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBn
                  ? 'আপনার ইমেইল এড্রেস লিখুন। আমরা পাসওয়ার্ড রিসেট লিংক পাঠাব।'
                  : 'Enter your registered email address to receive a password reset link.',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isBn ? 'ইমেইল এড্রেস' : 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isBn ? 'বাতিল' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBn ? 'সঠিক ইমেইল দিন' : 'Enter a valid email'),
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              final auth = context.read<AuthProvider>();
              final sent = await auth.resetPassword(email);
              if (!mounted) return;
              if (sent) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBn
                        ? 'পাসওয়ার্ড রিসেট লিংক ইমেইলে পাঠানো হয়েছে!'
                        : 'Password reset link sent to your email!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: Text(isBn ? 'লিংক পাঠান' : 'Send Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isBn = context.watch<LocaleProvider>().isBangla;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Header Branding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/app_logo.png',
                      width: 36,
                      height: 36,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.agriculture,
                        color: AppTheme.primaryGreen,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isBn ? AppStrings.appNameBn : AppStrings.appName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Hero Greeting Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.paddyHeroGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withAlpha(50),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn
                                    ? 'স্মার্ট কৃষি সহকারীতে স্বাগতম'
                                    : 'Welcome to Smart Agri AI',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isBn
                                    ? 'আধুনিক এআই প্রযুক্তির সাথে আপনার ফসল ও খামার পরিচালনা করুন'
                                    : 'Empower your farming with Gemini AI & smart tools',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(220),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Main Auth Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Tab Bar (Login / Register)
                    Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(text: isBn ? 'লগইন' : 'Sign In'),
                          Tab(text: isBn ? 'নতুন একাউন্ট' : 'Sign Up'),
                        ],
                      ),
                    ),

                    // Quick Google Sign In Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: auth.isLoading ? null : _handleGoogleSignIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://fonts.gstatic.com/s/i/productlogos/googleg/v6/24px.svg',
                              width: 22,
                              height: 22,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.g_mobiledata,
                                size: 28,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isBn
                                  ? 'গুগল (Gmail) দিয়ে প্রবেশ করুন'
                                  : 'Continue with Google',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Divider "OR"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              isBn ? 'অথবা ইমেইল ব্যবহার করুন' : 'OR WITH EMAIL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                    ),

                    // Tab View Content
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        return _tabController.index == 0
                            ? _buildLoginForm(auth, isBn)
                            : _buildRegisterForm(auth, isBn);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Demo Access Button
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                ),
                onPressed: auth.isLoading ? null : _handleDemoLogin,
                icon: const Icon(Icons.flash_on, size: 18, color: AppTheme.goldenHarvest),
                label: Text(
                  isBn
                      ? 'একাউন্ট ছাড়া দ্রুত ঘুরে দেখুন (Demo Mode)'
                      : 'Explore as Demo Farmer (Instant Access)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIN FORM ---
  Widget _buildLoginForm(AuthProvider auth, bool isBn) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rate limit info note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isBn
                          ? 'নিরাপত্তা সুরক্ষা: সর্বোচ্চ ৫ বার চেষ্টার পর ১ ঘণ্টা লক থাকবে।'
                          : 'Security: Maximum 5 attempts before a 1-hour cooldown.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            TextFormField(
              controller: _loginEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isBn ? 'ইমেইল এড্রেস' : 'Email Address',
                hintText: 'farmer@example.com',
                prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return isBn ? 'ইমেইল এড্রেস দিন' : 'Enter email address';
                }
                if (!v.contains('@')) {
                  return isBn ? 'সঠিক ইমেইল এড্রেস দিন' : 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _loginPassCtrl,
              obscureText: _loginObscure,
              decoration: InputDecoration(
                labelText: isBn ? 'পাসওয়ার্ড' : 'Password',
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
                suffixIcon: IconButton(
                  icon: Icon(
                    _loginObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _loginObscure = !_loginObscure),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              validator: (v) => v == null || v.isEmpty
                  ? (isBn ? 'পাসওয়ার্ড দিন' : 'Please enter password')
                  : null,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  isBn ? 'পাসওয়ার্ড ভুলে গেছেন?' : 'Forgot Password?',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: auth.isLoading ? null : _handleEmailLogin,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isBn ? 'লগইন করুন' : 'Sign In',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REGISTER FORM ---
  Widget _buildRegisterForm(AuthProvider auth, bool isBn) {
    final pass = _regPassCtrl.text;
    final hasMinLen = PasswordValidator.hasMinLength(pass);
    final hasUpper = PasswordValidator.hasUppercase(pass);
    final hasLower = PasswordValidator.hasLowercase(pass);
    final hasNum = PasswordValidator.hasDigit(pass);
    final hasSpec = PasswordValidator.hasSpecialChar(pass);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _regFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _regNameCtrl,
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                labelText: isBn ? 'আপনার পূর্ণ নাম' : 'Full Name',
                hintText: isBn ? 'যেমন: মোহাম্মদ রহিম' : 'e.g. John Doe',
                prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryGreen),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? (isBn ? 'নাম লিখুন' : 'Please enter your name')
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _regEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isBn ? 'ইমেইল এড্রেস' : 'Email Address',
                hintText: 'farmer@example.com',
                prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return isBn ? 'ইমেইল এড্রেস দিন' : 'Enter email address';
                }
                if (!v.contains('@')) {
                  return isBn ? 'সঠিক ইমেইল এড্রেস দিন' : 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password Field 1
            TextFormField(
              controller: _regPassCtrl,
              obscureText: _regObscure,
              decoration: InputDecoration(
                labelText: isBn ? 'পাসওয়ার্ড' : 'Password',
                hintText: 'e.g. Agri@2026',
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
                suffixIcon: IconButton(
                  icon: Icon(
                    _regObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _regObscure = !_regObscure),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              validator: (v) => PasswordValidator.validate(v, isBn: isBn),
            ),

            const SizedBox(height: 8),

            // Live Password Strength Checklist
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'পাসওয়ার্ডের শর্তাবলী:' : 'Password Requirements:',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildRequirementRow(
                    isBn ? 'কমপক্ষে ৮টি অক্ষর' : 'At least 8 characters',
                    hasMinLen,
                  ),
                  _buildRequirementRow(
                    isBn ? 'কমপক্ষে ১টি বড় হাতের অক্ষর (A-Z)' : 'At least 1 uppercase letter (A-Z)',
                    hasUpper,
                  ),
                  _buildRequirementRow(
                    isBn ? 'কমপক্ষে ১টি ছোট হাতের অক্ষর (a-z)' : 'At least 1 lowercase letter (a-z)',
                    hasLower,
                  ),
                  _buildRequirementRow(
                    isBn ? 'কমপক্ষে ১টি সংখ্যা (0-9)' : 'At least 1 number (0-9)',
                    hasNum,
                  ),
                  _buildRequirementRow(
                    isBn
                        ? 'কমপক্ষে ১টি স্পেশাল ক্যারেক্টার (@, #, \$, ! ইত্যাদি)'
                        : 'At least 1 special character (@, #, \$, ! etc.)',
                    hasSpec,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Password Field 2 (Confirmation)
            TextFormField(
              controller: _regConfirmPassCtrl,
              obscureText: _regConfirmObscure,
              decoration: InputDecoration(
                labelText: isBn ? 'পুনরায় পাসওয়ার্ড দিন (কনফার্ম)' : 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_reset, color: AppTheme.primaryGreen),
                suffixIcon: IconButton(
                  icon: Icon(
                    _regConfirmObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _regConfirmObscure = !_regConfirmObscure),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return isBn
                      ? 'পুনরায় পাসওয়ার্ড প্রদান করুন'
                      : 'Please confirm your password';
                }
                if (v != _regPassCtrl.text) {
                  return isBn
                      ? 'পাসওয়ার্ড দুটি মিলছে না'
                      : 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: auth.isLoading ? null : _handleRegister,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isBn ? 'নিবন্ধন সম্পন্ন করুন' : 'Create Account',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: met ? AppTheme.success : Colors.grey.shade400,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: met ? AppTheme.success : AppTheme.textSecondary,
                fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}