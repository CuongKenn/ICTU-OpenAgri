import 'package:flutter/material.dart';
import '../models/api_models.dart';

class PestRiskCard extends StatelessWidget {
  final PestWarningDTO warning;

  const PestRiskCard({super.key, required this.warning});

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color textColor;
    Color iconColor;
    IconData icon;
    String riskLabel;

    switch (warning.riskLevel.toLowerCase()) {
      case 'high':
        cardColor = const Color(0xFFFEF2F2); // Red 50
        textColor = const Color(0xFF991B1B); // Red 800
        iconColor = const Color(0xFFDC2626); // Red 600
        icon = Icons.warning_rounded;
        riskLabel = 'Nguy cơ Cao';
        break;
      case 'medium':
        cardColor = const Color(0xFFFFFBEB); // Amber 50
        textColor = const Color(0xFF92400E); // Amber 800
        iconColor = const Color(0xFFD97706); // Amber 600
        icon = Icons.info_rounded;
        riskLabel = 'Nguy cơ Trung bình';
        break;
      default:
        cardColor = const Color(0xFFECFDF5); // Emerald 50
        textColor = const Color(0xFF065F46); // Emerald 800
        iconColor = const Color(0xFF059669); // Emerald 600
        icon = Icons.check_circle_rounded;
        riskLabel = 'Nguy cơ Thấp';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              warning.pestName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: iconColor.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                riskLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          warning.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (warning.lastSeenYear != null)
                          Row(
                            children: [
                              Icon(Icons.history,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                'Lần cuối: ${warning.lastSeenYear}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.numbers,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                '${warning.occurrenceCount} lần',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
