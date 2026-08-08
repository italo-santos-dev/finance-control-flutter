import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/active_model.dart';
import 'package:intl/intl.dart';

class ActiveDetailsSectorPeers extends StatelessWidget {
  final Active active;
  final List<Active> sectorPeers;
  final Function(Active) onPeerTap;

  const ActiveDetailsSectorPeers({
    super.key,
    required this.active,
    required this.sectorPeers,
    required this.onPeerTap,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');

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
                'Ativos Relacionados do Setor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.inputDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  active.sector.isNotEmpty ? active.sector : 'B3',
                  style: const TextStyle(fontSize: 10, color: AppColors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sectorPeers.isEmpty)
            const Text(
              'Nenhum par direto encontrado para este segmento na base.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: sectorPeers.length,
                itemBuilder: (context, index) {
                  final peer = sectorPeers[index];
                  bool isPos = peer.dividendYield > 0;

                  return GestureDetector(
                    onTap: () => onPeerTap(peer),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
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
                                peer.symbol,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                realFormat.format(peer.lastPrice),
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                peer.name.isNotEmpty ? peer.name : peer.sector,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                              Text(
                                'DY ${peer.dividendYield.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isPos ? AppColors.emeraldGreen : Colors.grey,
                                ),
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
      ),
    );
  }
}
