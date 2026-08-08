import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/active_model.dart';

class ActiveDetailsPeerComparison extends StatelessWidget {
  final Active active;
  final List<Active> sectorPeers;

  const ActiveDetailsPeerComparison({
    super.key,
    required this.active,
    required this.sectorPeers,
  });

  @override
  Widget build(BuildContext context) {
    List<Active> listToCompare = [active, ...sectorPeers.take(3)];

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
          const Text(
            'Comparador de Fundamentos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(2.0),
              2: FlexColumnWidth(2.0),
              3: FlexColumnWidth(2.0),
            },
            children: [
              TableRow(
                children: [
                  const Text('Ativo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ...listToCompare.map((a) => Text(
                        a.symbol,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: a.symbol == active.symbol ? AppColors.blueAccent : Colors.white,
                        ),
                      )),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('DY (12M)', style: TextStyle(fontSize: 11, color: Colors.grey))),
                  ...listToCompare.map((a) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          a.dividendYield > 0 ? '${a.dividendYield.toStringAsFixed(2)}%' : 'N/D',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen),
                        ),
                      )),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Preço', style: TextStyle(fontSize: 11, color: Colors.grey))),
                  ...listToCompare.map((a) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'R\$ ${a.lastPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
