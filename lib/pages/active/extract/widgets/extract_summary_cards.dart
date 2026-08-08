import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:intl/intl.dart';

class ExtractSummaryCards extends StatelessWidget {
  final double totalTraded;
  final double totalPurchases;
  final double totalSales;

  const ExtractSummaryCards({
    super.key,
    required this.totalTraded,
    required this.totalPurchases,
    required this.totalSales,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 750;

        List<Widget> cards = [
          _buildCard(
            title: 'TOTAL NEGOCIADO',
            value: realFormat.format(totalTraded),
            icon: Icons.swap_horiz_rounded,
            iconColor: AppColors.blueAccent,
            iconBg: AppColors.primaryBlue.withValues(alpha: 0.15),
          ),
          _buildCard(
            title: 'VOLUME DE COMPRAS',
            value: realFormat.format(totalPurchases),
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.emeraldGreen,
            iconBg: AppColors.emeraldGreen.withValues(alpha: 0.15),
          ),
          _buildCard(
            title: 'VOLUME DE VENDAS',
            value: realFormat.format(totalSales),
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.redLoss,
            iconBg: AppColors.redLoss.withValues(alpha: 0.15),
          ),
        ];

        if (isMobile) {
          return Column(
            children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList(),
          );
        }

        return Row(
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
