import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';

class PortfolioUpcomingDividends extends StatelessWidget {
  const PortfolioUpcomingDividends({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> items = [
      {'dayWeek': 'Qui', 'dayNum': '14', 'ticker': 'VALE3', 'type': 'JCP', 'valStr': 'R\$ 1,24/Ação'},
      {'dayWeek': 'Seg', 'dayNum': '18', 'ticker': 'MXRF11', 'type': 'Rendimentos', 'valStr': 'R\$ 0,11/Cota'},
      {'dayWeek': 'Sex', 'dayNum': '29', 'ticker': 'ITUB4', 'type': 'Dividendos', 'valStr': 'R\$ 0,017/Ação'},
    ];

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
                  Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    'Dividendos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const Text(
                'Próximos Pagamentos',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.inputDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  children: [
                    // Date Badge Box
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['dayWeek'],
                            style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            item['dayNum'],
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Ticker & Dividend Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['ticker'],
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['type'],
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    Text(
                      item['valStr'],
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Full Calendar Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abrindo agenda completa de proventos')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderDark),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Ver Calendário Completo',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
