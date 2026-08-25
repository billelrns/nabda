import 'package:flutter/material.dart';
import '../services/qadaa_service.dart';
import '../screens/qadaa/qadaa_screen.dart';

/// بطاقة سريعة تفاعلية لعرض ملخص أيام القضاء والوصول إليها من مختلف شاشات التطبيق
class QadaaQuickCard extends StatelessWidget {
  final String? customTitle;
  final String? customSubtitle;
  final Color? accentColor;
  final bool compact;

  const QadaaQuickCard({
    Key? key,
    this.customTitle,
    this.customSubtitle,
    this.accentColor,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = QadaaService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final hasData = service.hasAnyDaysTracked;
        final remaining = service.totalRemainingDays;
        final completed = service.totalCompletedDays;
        final total = service.totalMissedDays;

        String subtitle;
        if (!hasData) {
          subtitle = customSubtitle ??
              'سجّلي وتابعي أيام إفطار رمضان لقضائها بسهولة ✨';
        } else if (remaining > 0) {
          subtitle = 'باقٍ $remaining من $total يوم للقضاء · تم قضاء $completed يوم';
        } else {
          subtitle = 'تم إتمام قضاء جميع الأيام المفطرة بحمد الله 🎉';
        }

        final color = accentColor ?? const Color(0xFF7E57C2);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QadaaScreen()),
              );
            },
            child: Container(
              padding: EdgeInsets.all(compact ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(compact ? 16 : 22),
                border: Border.all(color: color.withOpacity(0.22), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: compact ? 40 : 48,
                    height: compact ? 40 : 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '🏮',
                        style: TextStyle(fontSize: compact ? 18 : 22),
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              customTitle ?? 'أيام القضاء',
                              style: TextStyle(
                                fontSize: compact ? 13.5 : 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B1320),
                              ),
                            ),
                            if (hasData && remaining > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$remaining متبقي',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: compact ? 11 : 12,
                            color: const Color(0xFF6B6470),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_ios,
                    color: color,
                    size: compact ? 13 : 15,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
