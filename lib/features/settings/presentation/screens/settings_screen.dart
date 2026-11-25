import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/adaptive_two_pane.dart';
import '../../../../core/providers/animation_mode_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/animation_mode_chooser.dart';
import '../../../../data/services/feeding_alarm_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FeedingAlarmService _alarmService = FeedingAlarmService.instance;

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;
    final auth = context.watch<AuthProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final localeProv = context.watch<LocaleProvider>();

    final userIdentifier = auth.user?.email ??
        auth.user?.phoneNumber ??
        '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBn ? 'সেটিংস ও নিয়ন্ত্রণ প্যানেল' : 'Settings & Control Panel',
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: AgriAtmosphericBackground(
        child: AdaptiveTwoPane(
          primary: [
            // User Profile & Status Card
            _ProfileHeaderCard(
              userIdentifier: userIdentifier,
              displayName: auth.displayName,
              isBn: isBn,
            ),
            const SizedBox(height: 16),

            // Section 1: Alarms for Fish, Chicken & Duck
            _FeedingAlarmCard(
              alarmService: _alarmService,
              isBn: isBn,
            ),
            const SizedBox(height: 16),

            // Section 2: General Notifications
            _NotificationCard(
              alarmService: _alarmService,
              isBn: isBn,
            ),
            const SizedBox(height: 16),

          ],
          secondary: [
            // Section 3: Language & Theme
            _AppearanceAndLanguageCard(
              themeProv: themeProv,
              localeProv: localeProv,
              isBn: isBn,
            ),
            const SizedBox(height: 16),

            // Section 4: Animated / Static interface mode
            _DisplayModeCard(isBn: isBn),
            const SizedBox(height: 16),

            // Section 5: Logout Action
            _LogoutCard(isBn: isBn),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.userIdentifier,
    required this.displayName,
    required this.isBn,
  });

  final String userIdentifier;
  final String displayName;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F5C4A), Color(0xFF1B7A5C)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isNotEmpty ? displayName : (isBn ? 'সম্মানিত কৃষক' : 'Valued Farmer'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (userIdentifier.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    userIdentifier.contains('@') ? '✉️ $userIdentifier' : '📱 $userIdentifier',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isBn ? 'স্মার্ট এগ্রি সদস্য' : 'Smart Agri Member',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedingAlarmCard extends StatelessWidget {
  const _FeedingAlarmCard({
    required this.alarmService,
    required this.isBn,
  });

  final FeedingAlarmService alarmService;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: alarmService,
      builder: (context, _) {
        final alarmsOn = alarmService.alarmsEnabled;
        final isPlaying = alarmService.isPlayingAlarm;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPlaying
                  ? AppTheme.danger
                  : const Color(0xFF00695C).withValues(alpha: 0.2),
              width: isPlaying ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isPlaying
                    ? AppTheme.danger.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? AppTheme.danger.withValues(alpha: 0.15)
                          : const Color(0xFF00695C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.notifications_active
                          : Icons.notifications_active_rounded,
                      color: isPlaying ? AppTheme.danger : const Color(0xFF00695C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn
                              ? 'খাবারের অ্যালার্ম সিস্টেম'
                              : 'Feeding Alarm System',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isBn
                              ? 'মাছ, মুরগি ও হাঁসের নির্দিষ্ট সময়ে অ্যালার্ম'
                              : 'Fish, Chicken & Duck Feeding Times',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: alarmsOn,
                    activeTrackColor: const Color(0xFF00695C),
                    onChanged: (val) async {
                      await alarmService.setAlarmsEnabled(val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn
                          ? '⏰ বাংলাদেশ সময় অনুযায়ী অ্যালার্মের সূচি:'
                          : '⏰ BST Scheduled Alarm Timings:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF00695C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isBn
                          ? '• 🐟 মাছের খাবার: সকাল ০৮:০০ ও বিকাল ০৪:৩০ (BST)\n• 🐔 মুরগির খাবার: সকাল ০৭:০০, দুপুর ১২:৩০ ও বিকাল ০৫:৩০ (BST)\n• 🦆 হাঁসের খাবার: সকাল ০৭:৩০, দুপুর ০১:০০ ও বিকাল ০৫:০০ (BST)'
                          : '• 🐟 Fish Feed: 08:00 AM & 04:30 PM (BST)\n• 🐔 Chicken Feed: 07:00 AM, 12:30 PM & 05:30 PM (BST)\n• 🦆 Duck Feed: 07:30 AM, 01:00 PM & 05:00 PM (BST)',
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isBn
                          ? '🔔 অ্যালার্ম বাজার সময় মোবাইলের স্ক্রিনে হেডস-আপ নোটিফিকেশন আসবে এবং assets/audio/alarm.mp3 বাজবে।'
                          : '🔔 When alarm rings, a Heads-Up alert appears on screen and plays assets/audio/alarm.mp3.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Highlighted Full-Width Stop Alarm Button when Alarm is ringing
              if (isPlaying) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await alarmService.stopAlarmAudio();
                    },
                    icon: const Icon(Icons.stop_circle_rounded, size: 24),
                    label: Text(
                      isBn ? '🚨 অ্যালার্ম বন্ধ করুন (Stop Alarm)' : '🚨 Stop Alarm Sound Now',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],

              // Responsive Action Buttons: Test Alarm & Always-Available Stop Button
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00695C),
                        side: const BorderSide(color: Color(0xFF00695C)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await alarmService.testAlarmAudio(isBn: isBn);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isBn
                                    ? '🔔 অ্যালার্ম বাজছে... বন্ধ করতে "Stop" বাটনে চাপুন।'
                                    : '🔔 Alarm ringing... Tap "Stop Alarm" to silence.',
                              ),
                              duration: const Duration(seconds: 10),
                              action: SnackBarAction(
                                label: isBn ? 'বন্ধ করুন' : 'Stop Alarm',
                                textColor: Colors.amberAccent,
                                onPressed: () => alarmService.stopAlarmAudio(),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                      label: Text(
                        isBn ? 'অ্যালার্ম পরীক্ষা' : 'Test Alarm',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPlaying ? AppTheme.danger : Colors.red.shade50,
                        foregroundColor: isPlaying ? Colors.white : AppTheme.danger,
                        side: BorderSide(
                          color: isPlaying
                              ? AppTheme.danger
                              : AppTheme.danger.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: isPlaying ? 3 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await alarmService.stopAlarmAudio();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        }
                      },
                      icon: const Icon(Icons.stop_rounded, size: 20),
                      label: Text(
                        isBn ? 'বন্ধ করুন' : 'Stop Alarm',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.alarmService,
    required this.isBn,
  });

  final FeedingAlarmService alarmService;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: alarmService,
      builder: (context, _) {
        final notifsOn = alarmService.notificationsEnabled;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'সাধারণ নোটিফিকেশন' : 'General Notifications',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isBn
                          ? 'আবহাওয়া ও ফসলের রিমাইন্ডার'
                          : 'Weather & crop tips',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: notifsOn,
                activeTrackColor: Colors.blue,
                onChanged: (val) async {
                  await alarmService.setNotificationsEnabled(val);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppearanceAndLanguageCard extends StatelessWidget {
  const _AppearanceAndLanguageCard({
    required this.themeProv,
    required this.localeProv,
    required this.isBn,
  });

  final ThemeProvider themeProv;
  final LocaleProvider localeProv;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final isDark = themeProv.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBn ? 'ভাষা ও থিম নিয়ন্ত্রণ' : 'Language & Appearance',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 14),

          // Responsive Language toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'অ্যাপের ভাষা' : 'App Language',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      localeProv.isBangla ? 'বাংলা নির্বাচিত' : 'English Selected',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SegmentedButton<AppLanguage>(
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment(
                    value: AppLanguage.bangla,
                    label: Text('বাং', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  ButtonSegment(
                    value: AppLanguage.english,
                    label: Text('EN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
                selected: {localeProv.language},
                onSelectionChanged: (val) {
                  localeProv.setLanguage(val.first);
                },
              ),
            ],
          ),
          const Divider(height: 24),

          // Responsive Dark & Day mode toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'ডার্ক মোড ও ডে মোড' : 'Dark & Day Mode',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isDark
                          ? (isBn ? 'ডার্ক মোড সক্রিয়' : 'Dark Mode Enabled')
                          : (isBn ? 'ডে (লাইট) মোড সক্রিয়' : 'Day Mode Enabled'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: isDark,
                activeTrackColor: Colors.purple,
                onChanged: (val) async {
                  await themeProv.toggleTheme();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}



/// Lets the user switch between the animated and the static (fast) interface.
class _DisplayModeCard extends StatelessWidget {
  const _DisplayModeCard({required this.isBn});

  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final modeProv = context.watch<AnimationModeProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBn ? 'অ্যাপের ধরন (অ্যানিমেশন)' : 'App Style (Animations)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            isBn
                ? 'ফোন ধীর চললে বা ব্যাটারি বাঁচাতে স্ট্যাটিক বেছে নিন।'
                : 'Choose Static if the app feels slow or to save battery.',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          AnimationModeSelector(
            value: modeProv.mode,
            onChanged: (m) => context.read<AnimationModeProvider>().setMode(m),
          ),
        ],
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.isBn});
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: AppTheme.danger,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.3)),
          ),
        ),
        onPressed: () => _confirmLogout(context, isBn),
        icon: const Icon(Icons.logout_rounded),
        label: Text(
          isBn ? 'লগআউট করুন' : 'Logout',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isBn ? 'লগআউট করতে চান?' : 'Confirm Logout?'),
          content: Text(
            isBn
                ? 'আপনি কি নিশ্চিত যে আপনার অ্যাকাউন্ট থেকে লগআউট করতে চান?'
                : 'Are you sure you want to logout from your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isBn ? 'বাতিল' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (_) => false,
                  );
                }
              },
              child: Text(isBn ? 'লগআউট' : 'Logout'),
            ),
          ],
        );
      },
    );
  }
}
