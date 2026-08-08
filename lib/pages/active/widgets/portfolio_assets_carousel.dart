import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/asset_model.dart';
import 'package:intl/intl.dart';

class PortfolioAssetsCarousel extends StatelessWidget {
  final List<Asset> assets;
  final double totalPortfolioValue;
  final bool hideValues;
  final Function(Asset) onSelectAsset;
  final VoidCallback onViewAll;

  const PortfolioAssetsCarousel({
    super.key,
    required this.assets,
    required this.totalPortfolioValue,
    required this.hideValues,
    required this.onSelectAsset,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open, size: 18, color: AppColors.blueAccent),
                const SizedBox(width: 8),
                const Text(
                  'Ativos em Carteira',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.chipDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${assets.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_forward, size: 14, color: AppColors.blueAccent),
              label: const Text(
                'Ver todos',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.blueAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (assets.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: const [
                Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Nenhum ativo cadastrado na carteira',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Clique em "Novo Ativo" no topo para adicionar seu primeiro investimento.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final asset = assets[index];
                double positionValue = asset.totalAmount;
                double allocPct = totalPortfolioValue > 0 ? (positionValue / totalPortfolioValue) : 0.0;
                double yieldPct = asset.profitability;
                bool isPositiveYield = yieldPct >= 0;

                String typeTag = asset.activeType.toUpperCase();
                if (typeTag.contains('FII')) typeTag = 'FII';
                else if (typeTag.contains('AÇÃO') || typeTag.contains('ACAO')) typeTag = 'AÇÃO';
                else if (typeTag.contains('CRIPTO')) typeTag = 'CRIPTO';

                Color tagColor = AppColors.primaryBlue;
                if (typeTag == 'FII') tagColor = AppColors.emeraldGreen;
                if (typeTag == 'CRIPTO') tagColor = Colors.amber;

                return GestureDetector(
                  onTap: () => onSelectAsset(asset),
                  child: Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _buildAvatar(asset.ticker),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      asset.ticker,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    Text(
                                      asset.segment.isNotEmpty ? asset.segment : 'Ativo B3',
                                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                typeTag,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: tagColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Values Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Quantidade', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  hideValues ? '•••' : '${asset.quantity}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Posição Atual', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  hideValues ? 'R\$ •••••' : realFormat.format(positionValue),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Progress Allocation Bar & Yield Badge
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: allocPct.clamp(0.01, 1.0),
                                  backgroundColor: AppColors.inputDark,
                                  color: tagColor,
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(allocPct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Icon(
                                  isPositiveYield ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 10,
                                  color: isPositiveYield ? AppColors.emeraldGreen : AppColors.redLoss,
                                ),
                                Text(
                                  '${isPositiveYield ? '+' : ''}${yieldPct.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPositiveYield ? AppColors.emeraldGreen : AppColors.redLoss,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(String symbol) {
    String initials = symbol.length >= 2 ? symbol.substring(0, 2) : symbol;
    String logoUrl = 'https://icons.brapi.dev/icons/${symbol.toUpperCase()}.png';

    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
      child: ClipOval(
        child: Image.network(
          logoUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.heroGradientStart],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
