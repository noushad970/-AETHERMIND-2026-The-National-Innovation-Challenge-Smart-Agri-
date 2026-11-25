import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

/// One button in the desktop sidebar.
class SidebarItem {
  const SidebarItem(this.route, this.icon, this.label, this.labelBn);

  final String route;
  final IconData icon;
  final String label;
  final String labelBn;
}

/// A titled block of sidebar buttons.
class SidebarGroup {
  const SidebarGroup(this.title, this.titleBn, this.items);

  final String title;
  final String titleBn;
  final List<SidebarItem> items;
}

const List<SidebarGroup> sidebarGroups = [
  SidebarGroup('Overview', 'সারসংক্ষেপ', [
    SidebarItem(AppRoutes.home, Icons.dashboard_rounded, 'Home', 'হোম'),
    SidebarItem(
      AppRoutes.diseaseDetect,
      Icons.qr_code_scanner_rounded,
      'AI Disease Scan',
      'এআই রোগ নির্ণয়',
    ),
    SidebarItem(
      AppRoutes.chatbot,
      Icons.psychology_outlined,
      'AI Advisor',
      'এআই কৃষি পরামর্শ',
    ),
  ]),
  SidebarGroup('My Farm', 'আমার খামার', [
    SidebarItem(AppRoutes.cropList, Icons.grass_rounded, 'My Crops', 'আমার ফসল'),
    SidebarItem(
      AppRoutes.livestockList,
      Icons.pets_rounded,
      'Livestock',
      'গবাদিপশু',
    ),
    SidebarItem(
      AppRoutes.fishList,
      Icons.set_meal_rounded,
      'Fish Ponds',
      'মাছের পুকুর',
    ),
    SidebarItem(
      AppRoutes.farmRecords,
      Icons.account_balance_wallet_outlined,
      'Farm Records',
      'খামারের হিসাব',
    ),
  ]),
  SidebarGroup('Plan & Decide', 'পরিকল্পনা', [
    SidebarItem(
      AppRoutes.weatherScreen,
      Icons.cloud_outlined,
      'Weather',
      'আবহাওয়া',
    ),
    SidebarItem(
      AppRoutes.smartIrrigation,
      Icons.water_drop_outlined,
      'Irrigation',
      'সেচ পরামর্শ',
    ),
    SidebarItem(
      AppRoutes.marketPrices,
      Icons.storefront_rounded,
      'Market Prices',
      'বাজার দর',
    ),
    SidebarItem(
      AppRoutes.yieldForecaster,
      Icons.insights_rounded,
      'Yield Forecast',
      'ফলন পূর্বাভাস',
    ),
  ]),
  SidebarGroup('Learn & Connect', 'শিখুন ও যোগাযোগ', [
    SidebarItem(
      AppRoutes.cropLibrary,
      Icons.local_library_outlined,
      'Crop Guides',
      'ফসল নির্দেশিকা',
    ),
    SidebarItem(
      AppRoutes.communityFeed,
      Icons.forum_rounded,
      'Community',
      'কৃষক ফিড',
    ),
    SidebarItem(
      AppRoutes.krishiHelpline,
      Icons.phone_in_talk_rounded,
      'Helpline',
      'কৃষি হেল্পলাইন',
    ),
  ]),
  SidebarGroup('Account', 'অ্যাকাউন্ট', [
    SidebarItem(
      AppRoutes.notifications,
      Icons.notifications_outlined,
      'Notifications',
      'বিজ্ঞপ্তি',
    ),
    SidebarItem(
      AppRoutes.settings,
      Icons.settings_outlined,
      'Settings',
      'সেটিংস',
    ),
  ]),
];

const Map<String, String> _parentRoutes = {
  AppRoutes.diseaseResult: AppRoutes.diseaseDetect,
  AppRoutes.addCrop: AppRoutes.cropList,
  AppRoutes.cropDetail: AppRoutes.cropList,
  AppRoutes.cropLiveTrack: AppRoutes.cropList,
  AppRoutes.addLivestock: AppRoutes.livestockList,
  AppRoutes.livestockDetail: AppRoutes.livestockList,
  AppRoutes.livestockLiveTrack: AppRoutes.livestockList,
  AppRoutes.addFish: AppRoutes.fishList,
  AppRoutes.fishDetail: AppRoutes.fishList,
  AppRoutes.fishLiveTrack: AppRoutes.fishList,
  AppRoutes.expenseList: AppRoutes.farmRecords,
  AppRoutes.addExpense: AppRoutes.farmRecords,
};

/// The sidebar button to highlight while [route] is open.
String sidebarSelectionFor(String route) => _parentRoutes[route] ?? route;

/// The desktop navigation sidebar. It holds no state of its own.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.currentRoute,
    required this.isBn,
    required this.isDark,
    required this.userName,
    required this.unreadCount,
    required this.onSelect,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    required this.onLogout,
  });

  final String currentRoute;
  final bool isBn;
  final bool isDark;
  final String userName;
  final int unreadCount;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final selected = sidebarSelectionFor(currentRoute);

    return Material(
      color: AppTheme.primaryGreenDark,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _brand(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: AppTheme.textPrimary,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () => onSelect(AppRoutes.addCrop),
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  isBn ? 'নতুন ফসল যোগ' : 'Add crop',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  for (final group in sidebarGroups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                      child: Text(
                        (isBn ? group.titleBn : group.title).toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    for (final item in group.items)
                      _button(item, item.route == selected),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _brand() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/app_logo.png',
              width: 38,
              height: 38,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.agriculture, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Agri BD',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isBn ? 'স্মার্ট কৃষি সহকারী' : 'Farm assistant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.sunYellow,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(SidebarItem item, bool active) {
    final color = active ? Colors.white : Colors.white.withValues(alpha: 0.78);
    final showBadge =
        item.route == AppRoutes.notifications && unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey('sidebar:${item.route}'),
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          onTap: () => onSelect(item.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: active ? AppTheme.sunYellow : color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isBn ? item.labelBn : item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (showBadge)
                  Badge(
                    label: Text('$unreadCount'),
                    backgroundColor: AppTheme.danger,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // No tooltips here: the sidebar sits outside the navigator's overlay.
  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryGreenLight,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('sidebar:logout'),
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _footerButton(
                  const ValueKey('sidebar:language'),
                  Icons.translate,
                  isBn ? 'English' : 'বাংলা',
                  onToggleLanguage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _footerButton(
                  const ValueKey('sidebar:theme'),
                  isDark ? Icons.light_mode : Icons.dark_mode_outlined,
                  isDark
                      ? (isBn ? 'আলো' : 'Light')
                      : (isBn ? 'ডার্ক' : 'Dark'),
                  onToggleTheme,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerButton(
    Key key,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      key: key,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size.fromHeight(38),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
