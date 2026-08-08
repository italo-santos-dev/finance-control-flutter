import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/active_model.dart';
import 'package:intl/intl.dart';

class ActiveDetailsGrahamCard extends StatelessWidget {
  final Active active;
  final double? Function(String) getRawIndicatorValue;
  final VoidCallback onShowInfo;

  const ActiveDetailsGrahamCard({
    super.key,
    required this.active,
    required this.getRawIndicatorValue,
    required this.onShowInfo,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');
    double? rawLpa = getRawIndicatorValue('lpa');
    double? rawVpa = getRawIndicatorValue('vpa');
    bool hasValidData = rawLpa != null && rawVpa != null && rawLpa > 0 && rawVpa > 0;

    double fairValue = hasValidData ? sqrt(22.5 * rawLpa * rawVpa) : 0.0;
    double currentPrice = active.lastPrice;
    double marginSafety = hasValidData && currentPrice > 0 ? ((fairValue - currentPrice) / currentPrice) * 100 : 0.0;
    bool isDiscounted = marginSafety >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preço Justo (Graham)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                onPressed: onShowInfo,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasValidData)
            const Text(
              'Preço justo indisponível para este ativo (LPA/VPA ausente ou negativo).',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FÓRMULA DE GRAHAM', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(realFormat.format(fairValue), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.white)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDiscounted ? AppColors.emeraldGreen : AppColors.redLoss).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isDiscounted ? 'Desconto de' : 'Prêmio de'} ${marginSafety.abs().toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDiscounted ? AppColors.emeraldGreen : AppColors.redLoss),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
