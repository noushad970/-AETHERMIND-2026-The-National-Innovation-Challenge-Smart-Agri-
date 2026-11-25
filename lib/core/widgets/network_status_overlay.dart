import 'package:flutter/material.dart';
import '../../data/services/network_monitor_service.dart';
import '../theme/app_theme.dart';

/// Wraps the application to show an immediate notice popup and persistent warning
/// whenever mobile data or Wi-Fi internet connection is turned off or lost.
class NetworkStatusOverlay extends StatefulWidget {
  const NetworkStatusOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<NetworkStatusOverlay> createState() => _NetworkStatusOverlayState();
}

class _NetworkStatusOverlayState extends State<NetworkStatusOverlay> {
  final NetworkMonitorService _networkService = NetworkMonitorService.instance;
  bool _dismissedTemporarily = false;

  @override
  void initState() {
    super.initState();
    _networkService.addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    _networkService.removeListener(_onNetworkChange);
    super.dispose();
  }

  void _onNetworkChange() {
    if (_networkService.isOnline) {
      if (_dismissedTemporarily) {
        setState(() => _dismissedTemporarily = false);
      }
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _networkService,
      builder: (context, _) {
        final isOnline = _networkService.isOnline;
        final isChecking = _networkService.isChecking;

        return Stack(
          children: [
            widget.child,

            // If offline and not dismissed, show popup dialog/bottom notice
            if (!isOnline && !_dismissedTemporarily)
              Positioned.fill(
                child: Material(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: AppTheme.danger.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wifi_off_rounded,
                              size: 40,
                              color: AppTheme.danger,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '⚠️ ইন্টারনেট সংযোগ বিচ্ছিন্ন!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.danger,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No Internet Connection',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              'আপনার মোবাইল ডাটা (Mobile Data) অথবা ওয়াইফাই (Wi-Fi) বন্ধ রয়েছে।\n'
                              'লোকাল ডেটা অফলাইনে Hive মেমরিতে সংরক্ষিত হচ্ছে। অনলাইনে গ্লোবাল ডেটা সিঙ্ক এবং এআই সার্ভিসের জন্য ইন্টারনেট চালু করুন।',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: Colors.brown.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _dismissedTemporarily = true;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'অফলাইনে থাকুন',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isChecking
                                      ? null
                                      : () async {
                                          await _networkService.checkConnection();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: isChecking
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Icon(Icons.refresh_rounded, size: 18),
                                  label: Text(
                                    isChecking ? 'যাচাই হচ্ছে...' : 'পুনরায় চেষ্টা',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // When offline but dismissed, show a persistent top mini bar
            if (!isOnline && _dismissedTemporarily)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _dismissedTemporarily = false);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.signal_wifi_connected_no_internet_4_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'অফলাইন মোড (ইন্টারনেট নেই) • ট্যাপ করে বিস্তারিত দেখুন',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                              onPressed: () => _networkService.checkConnection(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
