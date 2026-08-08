import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/asset_model.dart';

class PortfolioTopPerformance extends StatelessWidget {
  final List<Asset> assets;
  final VoidCallback onViewAll;

  const PortfolioTopPerformance({
    super.key,
    required this.assets,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    List<Asset> sortedAssets = List.from(assets);
    sortedAssets.sort((a, b) => b.profitability.compareTo(a.profitability));
    List<Asset> top5 = sortedAssets.take(5).toList();

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
              Row(
                children: const [
                  Icon(Icons.star_outline, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Top 5 Performance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text(
                  'Ver todos',
                  style: TextStyle(fontSize: 11, color: AppColors.blueAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (top5.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Cadastre ativos para visualizar o ranking de performance.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            )
          else
            SizedBox(
              height: 78,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: top5.length,
                itemBuilder: (context, index) {
                  final item = top5[index];
                  double perf = item.profitability;
                  bool isPos = perf >= 0;

                  return Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.inputDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.ticker,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${isPos ? '+' : ''}${perf.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPos ? AppColors.emeraldGreen : AppColors.redLoss,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          item.segment.isNotEmpty ? item.segment : item.activeType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                        // Sparkline Mini Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              isPos ? Icons.trending_up : Icons.trending_down,
                              size: 14,
                              color: isPos ? AppColors.emeraldGreen : AppColors.redLoss,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
