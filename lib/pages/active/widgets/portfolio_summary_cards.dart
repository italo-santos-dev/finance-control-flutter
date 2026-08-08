import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:intl/intl.dart';

class PortfolioSummaryCards extends StatelessWidget {
  final double totalEquity;
  final double monthlyYieldPct;
  final double accumulatedDividends;
  final double projectedDividends;
  final bool hideValues;

  const PortfolioSummaryCards({
    super.key,
    required this.totalEquity,
    required this.monthlyYieldPct,
    required this.accumulatedDividends,
    required this.projectedDividends,
    required this.hideValues,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');
    bool isPositiveYield = monthlyYieldPct >= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;

        List<Widget> cards = [
          _buildSummaryCard(
            title: 'PATRIMÔNIO TOTAL',
            icon: Icons.account_balance_wallet_outlined,
            iconBg: AppColors.primaryBlue.withValues(alpha: 0.15),
            iconColor: AppColors.blueAccent,
            mainValue: hideValues ? 'R\$ •••••••' : realFormat.format(totalEquity),
            subtitleChild: Row(
              children: [
                const Icon(Icons.trending_up, size: 14, color: AppColors.emeraldGreen),
                const SizedBox(width: 4),
                Text(
                  '+12.4% no ano',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emeraldGreen,
                  ),
                ),
              ],
            ),
          ),
          _buildSummaryCard(
            title: 'RENTABILIDADE (MÊS)',
            icon: Icons.show_chart,
            iconBg: AppColors.emeraldGreen.withValues(alpha: 0.15),
            iconColor: AppColors.emeraldGreen,
            mainValue: hideValues
                ? '••••%'
                : '${isPositiveYield ? '+' : ''}${monthlyYieldPct.toStringAsFixed(2).replaceAll('.', ',')}%',
            mainValueColor: isPositiveYield ? AppColors.emeraldGreen : AppColors.redLoss,
            subtitleChild: const Text(
              'CDI: +0,92% (128% do CDI)',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          _buildSummaryCard(
            title: 'PROVENTOS (ACUMULADO)',
            icon: Icons.payments_outlined,
            iconBg: Colors.amber.withValues(alpha: 0.15),
            iconColor: Colors.amber,
            mainValue: hideValues ? 'R\$ •••••' : realFormat.format(accumulatedDividends),
            subtitleChild: Text(
              hideValues ? '+R\$ ••• previstos' : '+${realFormat.format(projectedDividends)} previstos',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ];

        if (isMobile) {
          return Column(
            children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
          );
        }

        return Row(
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String mainValue,
    Color mainValueColor = AppColors.white,
    required Widget subtitleChild,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: mainValueColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          subtitleChild,
        ],
      ),
    );
  }
}
