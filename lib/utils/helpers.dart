import 'package:intl/intl.dart';

class AppHelpers {
  // Format date in Arabic
  static String formatDateArabic(DateTime date) {
    final arabicFormat = DateFormat('dd MMMM yyyy', 'ar');
    return arabicFormat.format(date);
  }

  // Format date with time
  static String formatDateTimeArabic(DateTime dateTime) {
    final format = DateFormat('dd/MM/yyyy HH:mm', 'ar');
    return format.format(dateTime);
  }

  // Get day name in Arabic
  static String getDayNameArabic(DateTime date) {
    final dayNames = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return dayNames[date.weekday - 1];
  }

  // Get month name in Arabic
  static String getMonthNameArabic(int month) {
    final monthNames = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return monthNames[month - 1];
  }

  // Calculate difference in days
  static int calculateDaysDifference(DateTime date1, DateTime date2) {
    return date2.difference(date1).inDays;
  }

  // Calculate age in months
  static int calculateAgeInMonths(DateTime birthDate) {
    final now = DateTime.now();
    int months = now.month - birthDate.month;
    if (now.day < birthDate.day) {
      months--;
    }
    months += (now.year - birthDate.year) * 12;
    return months;
  }

  // Calculate age in weeks (for pregnancy)
  static int calculateWeeksOfPregnancy(DateTime dueDate) {
    final now = DateTime.now();
    const gestationPeriod = 280; // days
    final difference = dueDate.difference(now).inDays;
    final weeks = ((gestationPeriod - difference) / 7).round();
    return weeks;
  }

  // Get next period date
  static DateTime getNextPeriodDate(DateTime lastDate, int cycleLength) {
    return lastDate.add(Duration(days: cycleLength));
  }

  // Check if date is in fertile window
  static bool isInFertileWindow(DateTime date, DateTime cycleStart, int cycleLength) {
    final fertileWindowStart = cycleStart.add(Duration(days: (cycleLength / 2 - 2).round()));
    final fertileWindowEnd = cycleStart.add(Duration(days: (cycleLength / 2 + 2).round()));
    return date.isAfter(fertileWindowStart) && date.isBefore(fertileWindowEnd);
  }

  // Format time
  static String formatTime(DateTime time) {
    final format = DateFormat('HH:mm');
    return format.format(time);
  }

  // Get greeting message based on time
  static String getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'صباح الخير';
    } else if (hour < 18) {
      return 'مساء الخير';
    } else {
      return 'تصبحي على خير';
    }
  }
}






