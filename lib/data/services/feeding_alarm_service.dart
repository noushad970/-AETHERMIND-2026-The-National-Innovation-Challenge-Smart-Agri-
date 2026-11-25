import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_constants.dart';

enum FeedingTargetType { fish, chicken, duck }

class FeedingScheduleItem {
  const FeedingScheduleItem({
    required this.id,
    required this.type,
    required this.hour,
    required this.minute,
    required this.titleEn,
    required this.titleBn,
    required this.bodyEn,
    required this.bodyBn,
  });

  final int id;
  final FeedingTargetType type;
  final int hour; // 24-hr BST
  final int minute;
  final String titleEn;
  final String titleBn;
  final String bodyEn;
  final String bodyBn;
}

class FeedingAlarmService extends ChangeNotifier {
  FeedingAlarmService._();
  static final FeedingAlarmService instance = FeedingAlarmService._();

  static const String _prefAlarmsKey = 'feeding_alarms_enabled';
  static const String _prefNotifsKey = 'general_notifications_enabled';

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _alarmsEnabled = true;
  bool get alarmsEnabled => _alarmsEnabled;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  bool _isPlayingAlarm = false;
  bool get isPlayingAlarm => _isPlayingAlarm;

  bool _initialized = false;

  /// Bangladesh feeding schedules (BST, UTC+6) strictly for Fish, Chickens, and Ducks
  static const List<FeedingScheduleItem> feedingSchedules = [
    // Fish feeding schedules
    FeedingScheduleItem(
      id: 101,
      type: FeedingTargetType.fish,
      hour: 8,
      minute: 0,
      titleEn: '🐟 Fish Morning Feeding Time!',
      titleBn: '🐟 মাছের সকালের খাবার দেওয়ার সময় হয়েছে!',
      bodyEn: 'Time to feed your pond fishes! Provide measured floating/sinking feed.',
      bodyBn: 'পুকুরের মাছকে সকালের সুষম খাবার দিন এবং অক্সিজেন সঞ্চালন পর্যবেক্ষণ করুন।',
    ),
    FeedingScheduleItem(
      id: 102,
      type: FeedingTargetType.fish,
      hour: 16,
      minute: 30,
      titleEn: '🐟 Fish Afternoon Feeding Time!',
      titleBn: '🐟 মাছের বিকালের খাবার দেওয়ার সময় হয়েছে!',
      bodyEn: 'Time for second fish feed ration before evening.',
      bodyBn: 'পুকুরে বিকালের খাবার প্রদান করুন। সন্ধ্যার আগে খাদ্য গ্রহণ নিশ্চিত করুন।',
    ),
    // Chicken (মুরগি) feeding schedules
    FeedingScheduleItem(
      id: 201,
      type: FeedingTargetType.chicken,
      hour: 7,
      minute: 0,
      titleEn: '🐔 Chicken Morning Feed & Water Time!',
      titleBn: '🐔 মুরগির সকালের খাবার ও পানির সময় হয়েছে!',
      bodyEn: 'Feed the chickens fresh layer/broiler feed and clean fresh drinking water.',
      bodyBn: 'মুরগিকে সকালের সুষম দানা খাবার এবং পর্যাপ্ত পরিষ্কার পানি দিন।',
    ),
    FeedingScheduleItem(
      id: 202,
      type: FeedingTargetType.chicken,
      hour: 12,
      minute: 30,
      titleEn: '🐔 Chicken Midday Feed Inspection!',
      titleBn: '🐔 মুরগির দুপুরের খাবার ও তাপমাত্রা পরীক্ষা!',
      bodyEn: 'Check feeder troughs and refill water with vitamins/electrolytes if hot.',
      bodyBn: 'মুরগির খাবারের পাত্র দেখুন ও শেডের তাপমাত্রা নিয়ন্ত্রণ করুন।',
    ),
    FeedingScheduleItem(
      id: 203,
      type: FeedingTargetType.chicken,
      hour: 17,
      minute: 30,
      titleEn: '🐔 Chicken Evening Feeding Time!',
      titleBn: '🐔 মুরগির সন্ধ্যার খাবার দেওয়ার সময় হয়েছে!',
      bodyEn: 'Provide evening feed ration and lock coop securely for night.',
      bodyBn: 'মুরগিকে সন্ধ্যার খাবার দিন এবং শেড নিরাপদে বন্ধ করুন।',
    ),
    // Duck (হাঁস) feeding schedules
    FeedingScheduleItem(
      id: 301,
      type: FeedingTargetType.duck,
      hour: 7,
      minute: 30,
      titleEn: '🦆 Duck Morning Feed & Water Release!',
      titleBn: '🦆 হাঁসের সকালের খাবার ও জলকেলি সময়!',
      bodyEn: 'Feed the ducks morning mash and release to pond/grazing area.',
      bodyBn: 'হাঁসকে সকালের ভেজা খাবার দিন এবং জলাশয়ে নামার ব্যবস্থা করুন।',
    ),
    FeedingScheduleItem(
      id: 302,
      type: FeedingTargetType.duck,
      hour: 13,
      minute: 0,
      titleEn: '🦆 Duck Midday Feed Time!',
      titleBn: '🦆 হাঁসের দুপুরের খাবার দেওয়ার সময় হয়েছে!',
      bodyEn: 'Check water hydration and provide supplemental grains/greens.',
      bodyBn: 'হাঁসকে দুপুরের পরিপূরক খাবার ও ঠান্ডা পানি দিন।',
    ),
    FeedingScheduleItem(
      id: 303,
      type: FeedingTargetType.duck,
      hour: 17,
      minute: 0,
      titleEn: '🦆 Duck Evening Feeding & Coop Call!',
      titleBn: '🦆 হাঁসের সন্ধ্যার খাবার ও ঘরে তোলার সময়!',
      bodyEn: 'Feed evening ration and count flock into the shelter.',
      bodyBn: 'হাঁসকে সন্ধ্যার খাবার দিয়ে গুনে গুনে শেডে তুলুন।',
    ),
  ];

  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _alarmsEnabled = prefs.getBool(_prefAlarmsKey) ?? true;
      _notificationsEnabled = prefs.getBool(_prefNotifsKey) ?? true;
    } catch (_) {}

    // Listen to audio player state
    _audioPlayer.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      if (_isPlayingAlarm != playing) {
        _isPlayingAlarm = playing;
        notifyListeners();
      }
    });

    // Setup AudioContext for loud alarm playback across devices
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioMode: AndroidAudioMode.normal,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('AudioContext setup error: $e');
    }

    // Initialize notifications plugin settings
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        debugPrint('[FeedingAlarm] Notification clicked: ${resp.payload}');
        if (resp.actionId == 'stop_alarm_action' || resp.payload == 'stop_alarm') {
          stopAlarmAudio();
        }
      },
    );

    // Request permissions for Android 13+ and Exact Alarms
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    // Create heads-up notification channel specifically for feeding alarms
    const androidChannel = AndroidNotificationChannel(
      AppConstants.feedingAlarmChannelId,
      AppConstants.feedingAlarmChannelName,
      description: AppConstants.feedingAlarmChannelDescription,
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('alarm'),
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await androidImpl?.createNotificationChannel(androidChannel);

    if (_alarmsEnabled) {
      await scheduleAllFeedingAlarms();
    }

    _initialized = true;
  }

  Future<void> setAlarmsEnabled(bool enabled) async {
    _alarmsEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefAlarmsKey, enabled);
    } catch (_) {}

    if (enabled) {
      await scheduleAllFeedingAlarms();
    } else {
      await cancelAllFeedingAlarms();
      await stopAlarmAudio();
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefNotifsKey, enabled);
    } catch (_) {}
  }

  /// Triggers a test alarm specifically for Fish Feeding with sound and Heads-Up notification
  Future<void> testFishAlarmAudio({bool isBn = true}) async {
    await playAlarmAudio();
    await showHeadsUpFeedingNotification(
      id: 998,
      title: isBn
          ? '🐟 অ্যালার্ম: পুকুরের মাছকে খাবার দেওয়ার সময় হয়েছে!'
          : '🐟 Alarm: Time to Feed Pond Fishes!',
      body: isBn
          ? 'সকাল ০৮:০০ ও বিকাল ০৪:৩০ টার নির্ধারিত মাছের খাবার অ্যালার্ম সফলভাবে বাজছে।'
          : 'Scheduled 08:00 AM & 04:30 PM fish feeding alarm is active and ringing.',
    );
  }

  /// Triggers a test alarm so the user can hear the assets/audio/alarm.mp3 sound
  /// and verify the heads-up notification immediately.
  Future<void> testAlarmAudio({bool isBn = true}) async {
    await playAlarmAudio();
    await showHeadsUpFeedingNotification(
      id: 999,
      title: isBn
          ? '🔔 পরীক্ষামূলক অ্যালার্ম: মাছ ও প্রাণীর খাবার সময়'
          : '🔔 Test Alarm: Feed the Fishes & Animals',
      body: isBn
          ? 'মাছের খাবার, মুরগি ও হাঁসের খাবারের অ্যালার্ম সফলভাবে সক্রিয় রয়েছে!'
          : 'Fish, chicken, and duck feeding alarm is active and ringing!',
    );
  }

  /// Plays the alarm audio from assets/audio/alarm.mp3
  Future<void> playAlarmAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      try {
        await _audioPlayer.play(AssetSource('audio/alarm.mp3'), volume: 1.0);
      } catch (err1) {
        debugPrint('Primary asset source error: $err1, trying fallback');
        await _audioPlayer.play(AssetSource('assets/audio/alarm.mp3'), volume: 1.0);
      }
      _isPlayingAlarm = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing alarm audio: $e');
    }
  }

  Future<void> stopAlarmAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlayingAlarm = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping alarm audio: $e');
    }
  }

  /// Displays an immediate Heads-Up notification at the top of the mobile device screen.
  Future<void> showHeadsUpFeedingNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_notificationsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.feedingAlarmChannelId,
      AppConstants.feedingAlarmChannelName,
      channelDescription: AppConstants.feedingAlarmChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      sound: RawResourceAndroidNotificationSound('alarm'),
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction(
          'stop_alarm_action',
          'Stop Alarm (বন্ধ করুন)',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show heads-up feeding notification: $e');
    }
  }

  /// Schedules all Bangladesh time feeding alarms for Fish, Chickens, and Ducks
  Future<void> scheduleAllFeedingAlarms({bool isBn = true}) async {
    if (!_alarmsEnabled) return;

    for (final schedule in feedingSchedules) {
      await _scheduleDailyFeedingItem(schedule, isBn: isBn);
    }
  }

  Future<void> cancelAllFeedingAlarms() async {
    for (final schedule in feedingSchedules) {
      await _notificationsPlugin.cancel(schedule.id);
    }
  }

  Future<void> _scheduleDailyFeedingItem(
    FeedingScheduleItem item, {
    bool isBn = true,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      item.hour,
      item.minute,
    );

    // If time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      AppConstants.feedingAlarmChannelId,
      AppConstants.feedingAlarmChannelName,
      channelDescription: AppConstants.feedingAlarmChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      sound: RawResourceAndroidNotificationSound('alarm'),
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction(
          'stop_alarm_action',
          'Stop Alarm (বন্ধ করুন)',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        item.id,
        isBn ? item.titleBn : item.titleEn,
        isBn ? item.bodyBn : item.bodyEn,
        scheduled,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Failed to schedule feeding alarm ${item.id}: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
