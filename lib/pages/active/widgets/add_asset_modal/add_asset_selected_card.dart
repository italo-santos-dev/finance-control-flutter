import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:intl/intl.dart';

class AddAssetSelectedCard extends StatelessWidget {
  final Map<String, dynamic> assetData;
  final double currentPrice;
  final double changePercent;
  final String updateTime;
  final bool isLoadingPrice;
  final bool priceUnavailable;
  final VoidCallback onRetryPrice;
  final VoidCallback onChangeAsset;

  const AddAssetSelectedCard({
    super.key,
    required this.assetData,
    required this.currentPrice,
    required this.changePercent,
    required this.updateTime,
    required this.isLoadingPrice,
    required this.priceUnavailable,
    required this.onRetryPrice,
    required this.onChangeAsset,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');
    String ticker = (assetData['ticker'] ?? assetData['symbol'] ?? '').toString().toUpperCase();
    String name = (assetData['name'] ?? assetData['segment'] ?? ticker).toString();
    String type = (assetData['activeType'] ?? 'Ação').toString();
    String sector = (assetData['sector'] ?? assetData['segment'] ?? 'B3 Brasil').toString();

    bool isPos = changePercent >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Avatar, Name, and Change Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildAvatar(ticker),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$ticker · $type · B3',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: onChangeAsset,
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('Trocar ativo', style: TextStyle(fontSize: 11, color: AppColors.blueAccent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 12),

          // Live Price / Unavailable Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cotação atual', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (isLoadingPrice)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                    )
                  else if (priceUnavailable || currentPrice <= 0)
                    Row(
                      children: [
                        const Text('Cotação indisponível', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onRetryPrice,
                          child: const Text('Tentar novamente', style: TextStyle(fontSize: 11, color: AppColors.blueAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          realFormat.format(currentPrice),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isPos ? AppColors.emeraldGreen : AppColors.redLoss).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${isPos ? '+' : ''}${changePercent.toStringAsFixed(2)}% hoje',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPos ? AppColors.emeraldGreen : AppColors.redLoss,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (!isLoadingPrice && currentPrice > 0)
                Text(
                  'Atualizado às $updateTime',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Read-only Metadata Badges
          Row(
            children: [
              Text('Setor: $sector', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(width: 12),
              const Text('Moeda: BRL (R\$)', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String symbol) {
    String initials = symbol.length >= 2 ? symbol.substring(0, 2) : symbol;
    String logoUrl = 'https://icons.brapi.dev/icons/${symbol.toUpperCase()}.png';

    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
      child: ClipOval(
        child: Image.network(
          logoUrl,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.heroGradientStart],
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
