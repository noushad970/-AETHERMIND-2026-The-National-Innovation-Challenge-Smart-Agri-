import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/services/crops_realtime_service.dart';
import '../../../../data/models/app_notification.dart';
import '../../../livestock/presentation/providers/livestock_provider.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationType? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  Future<void> _sync() async {
    if (!mounted) return;
    final crops = context.read<CropsRealtimeService>().snapshot;
    final animals = context.read<LivestockProvider>().animals;
    final weather = context.read<WeatherProvider>().data;
    final isBn = context.read<LocaleProvider>().isBangla;

    await context.read<NotificationProvider>().syncAndSchedule(
      crops: crops,
      animals: animals,
      weather: weather,
      isBn: isBn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.notifications_outlined, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                AppStrings.notifications,
                AppStrings.notificationsBn,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Mark all as read', 'সব পঠিত হিসেবে চিহ্নিত করুন'),
            icon: const Icon(Icons.done_all),
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr(
                      'All notifications marked as read',
                      'সকল বিজ্ঞপ্তি পঠিত হিসেবে চিহ্নিত করা হয়েছে',
                    ),
                  ),
                ),
              );
            },
          ),
          const HeaderActionBar(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: AuthGate(
          featureName: context.tr('notifications', 'বিজ্ঞপ্তি'),
          child: Consumer<NotificationProvider>(
            builder: (context, notifProv, _) {
              var list = notifProv.notifications;
              if (_selectedType != null) {
                list = list.where((n) => n.type == _selectedType).toList();
              }

              return RefreshIndicator(
                onRefresh: _sync,
                child: Column(
                  children: [
                    _buildFilterChips(context),
                    const Divider(height: 1),
                    Expanded(
                      child: list.isEmpty
                          ? EmptyState(
                              title: context.tr(
                                'No notifications found',
                                'কোনো বিজ্ঞপ্তি পাওয়া যায়নি',
                              ),
                              subtitle: context.tr(
                                'Scheduled activity reminders and weather alerts will appear here.',
                                'পরিকল্পিত কাজের রিমাইন্ডার ও আবহাওয়ার সতর্কতা এখানে দেখতে পাবেন।',
                              ),
                              icon: Icons.notifications_off_outlined,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: list.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final n = list[i];
                                return _NotificationTile(
                                  notification: n,
                                  onTap: () => _handleTap(context, n),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: Text(context.tr('All', 'সকল')),
            selected: _selectedType == null,
            onSelected: (_) => setState(() => _selectedType = null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(context.tr('Crops', 'ফসল')),
            selected: _selectedType == NotificationType.cropReminder,
            onSelected: (_) =>
                setState(() => _selectedType = NotificationType.cropReminder),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(context.tr('Livestock', 'পশুপালন')),
            selected: _selectedType == NotificationType.livestockReminder,
            onSelected: (_) => setState(
              () => _selectedType = NotificationType.livestockReminder,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(context.tr('Weather', 'আবহাওয়া')),
            selected: _selectedType == NotificationType.weatherAlert,
            onSelected: (_) =>
                setState(() => _selectedType = NotificationType.weatherAlert),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, AppNotification n) {
    context.read<NotificationProvider>().markAsRead(n.id);
    if (n.route != null && n.route!.isNotEmpty) {
      if (n.route == '/crop_detail' && n.routeArgument != null) {
        Navigator.of(context).pushNamed(
          AppRoutes.cropDetail,
          arguments: n.routeArgument,
        );
      } else if (n.route == '/livestock_detail' && n.routeArgument != null) {
        Navigator.of(context).pushNamed(
          AppRoutes.livestockDetail,
          arguments: n.routeArgument,
        );
      } else if (n.route == '/weather') {
        Navigator.of(context).pushNamed(AppRoutes.weatherScreen);
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;
    final title = isBn ? notification.titleBn : notification.titleEn;
    final body = isBn ? notification.bodyBn : notification.bodyEn;
    final isUnread = !notification.isRead;

    return ListTile(
      onTap: onTap,
      tileColor: isUnread
          ? AppTheme.primaryGreen.withValues(alpha: 0.06)
          : null,
      leading: CircleAvatar(
        backgroundColor: _colorFor(notification.type).withValues(alpha: 0.18),
        child: Icon(
          _iconFor(notification.type),
          color: _colorFor(notification.type),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
          color: isUnread ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.daysFromNow(
                notification.scheduledTime.difference(DateTime.now()).inDays,
                isBn: isBn,
              ),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      trailing: isUnread
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
            )
          : const Icon(Icons.chevron_right, color: AppTheme.divider, size: 20),
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.cropReminder:
        return Icons.eco;
      case NotificationType.livestockReminder:
        return Icons.pets;
      case NotificationType.weatherAlert:
        return Icons.cloud;
      case NotificationType.marketUpdate:
        return Icons.trending_up;
      case NotificationType.systemAdvisory:
        return Icons.notifications_active;
    }
  }

  Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.cropReminder:
        return AppTheme.primaryGreen;
      case NotificationType.livestockReminder:
        return AppTheme.accentAmber;
      case NotificationType.weatherAlert:
        return AppTheme.skyBlue;
      case NotificationType.marketUpdate:
        return AppTheme.primaryGreenLight;
      case NotificationType.systemAdvisory:
        return AppTheme.earthBrown;
    }
  }
}
