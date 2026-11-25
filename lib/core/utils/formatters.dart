import 'package:intl/intl.dart';

/// Date/time and number formatters with guaranteed safe Bengali conversion.
class Formatters {
  Formatters._();

  static final DateFormat date = DateFormat('dd MMM yyyy'); // 07 Aug 2026
  static final DateFormat dateLong = DateFormat('EEEE, dd MMMM yyyy');
  static final DateFormat time = DateFormat('hh:mm a');
  static final DateFormat dateTime = DateFormat('dd MMM, hh:mm a');

  static const List<String> _bnMonths = [
    'জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'
  ];

  /// Convert standard digits (0-9) to Bengali digits (০-৯)
  static String toBnNumber(dynamic n) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var s = n.toString();
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(en[i], bn[i]);
    }
    return s;
  }

  /// Safe date formatting that never throws LocaleDataException
  static String formatDate(DateTime d, {bool isBn = false}) {
    if (isBn) {
      try {
        return DateFormat('dd MMM, yyyy', 'bn').format(d);
      } catch (_) {
        final day = toBnNumber(d.day.toString().padLeft(2, '0'));
        final month = _bnMonths[d.month - 1];
        final year = toBnNumber(d.year);
        return '$day $month, $year';
      }
    }
    try {
      return date.format(d);
    } catch (_) {
      return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    }
  }

  static String formatBnDate(DateTime d) => formatDate(d, isBn: true);

  /// Safe dateBn reference with fallback
  static final DateFormat dateBn = DateFormat('dd MMM, yyyy');

  static String formatBdt(num value) =>
      '৳${NumberFormat.decimalPattern().format(value)}';

  static String daysAgo(int days, {bool isBn = false}) {
    if (isBn) {
      if (days <= 0) return 'আজ';
      if (days == 1) return 'গতকাল';
      if (days < 7) return '$days দিন আগে';
      if (days < 30) return '${(days / 7).floor()} সপ্তাহ আগে';
      return '${(days / 30).floor()} মাস আগে';
    }
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) return '${(days / 7).floor()} week(s) ago';
    return '${(days / 30).floor()} month(s) ago';
  }

  static String daysFromNow(int days, {bool isBn = false}) {
    if (isBn) {
      if (days <= 0) return 'এখনই';
      if (days == 1) return 'আগামীকাল';
      return '$days দিন পর';
    }
    if (days <= 0) return 'Now';
    if (days == 1) return 'Tomorrow';
    return 'in $days days';
  }
}
