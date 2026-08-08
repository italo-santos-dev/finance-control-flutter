import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:intl/intl.dart';

class AddAssetSummaryPreview extends StatelessWidget {
  final String ticker;
  final String assetName;
  final String assetType;
  final double quantity;
  final double purchasePrice;
  final double fees;
  final DateTime purchaseDate;
  final String broker;

  const AddAssetSummaryPreview({
    super.key,
    required this.ticker,
    required this.assetName,
    required this.assetType,
    required this.quantity,
    required this.purchasePrice,
    required this.fees,
    required this.purchaseDate,
    required this.broker,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');
    double subtotal = quantity * purchasePrice;
    double total = subtotal + fees;

    if (quantity <= 0 || purchasePrice <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumo da Operação',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.blueAccent),
              ),
              Text(
                '$ticker · $assetType',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 8),

          _buildRow('Quantidade', quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString()),
          _buildRow('Preço de compra', realFormat.format(purchasePrice)),
          _buildRow('Data', DateFormat('dd/MM/yyyy').format(purchaseDate)),
          _buildRow('Corretora', broker),

          if (fees > 0) ...[
            _buildRow('Investimento', realFormat.format(subtotal)),
            _buildRow('Taxas / Custos', realFormat.format(fees)),
          ],

          const SizedBox(height: 6),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Investido',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                realFormat.format(total),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
