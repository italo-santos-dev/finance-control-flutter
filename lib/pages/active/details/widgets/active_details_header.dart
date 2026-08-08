import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/active_model.dart';

class ActiveDetailsHeader extends StatelessWidget {
  final Active active;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;
  final VoidCallback onAlert;

  const ActiveDetailsHeader({
    super.key,
    required this.active,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onShare,
    required this.onAlert,
  });

  @override
  Widget build(BuildContext context) {
    String symbol = active.symbol;
    String assetTag = symbol.endsWith('11')
        ? 'FII • B3'
        : symbol.endsWith('3')
            ? 'ON • B3'
            : symbol.endsWith('4')
                ? 'PN • B3'
                : 'BDR • B3';

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
                children: [
                  _buildLogoAvatar(active.icon, symbol),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            symbol,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              assetTag,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        active.name.isNotEmpty ? active.name : symbol,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.chipDark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      active.sector.isNotEmpty ? active.sector : 'B3 Brasil',
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: isFavorite ? Icons.star : Icons.star_border,
                  label: isFavorite ? 'Favoritado' : 'Favoritar',
                  color: isFavorite ? Colors.amber : Colors.grey,
                  onTap: onToggleFavorite,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Compartilhar',
                  color: Colors.grey,
                  onTap: onShare,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.notifications_active_outlined,
                  label: 'Criar Alerta',
                  color: Colors.grey,
                  onTap: onAlert,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color == Colors.amber ? Colors.amber : Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoAvatar(String iconUrl, String symbol, {double radius = 22}) {
    String logoUrl = iconUrl;
    if (!logoUrl.startsWith('http')) {
      logoUrl = 'https://icons.brapi.dev/icons/${symbol.toUpperCase()}.png';
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
      child: ClipOval(
        child: Image.network(
          logoUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            String initials = symbol.length >= 3 ? symbol.substring(0, 3) : symbol;
            return Container(
              width: radius * 2,
              height: radius * 2,
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
                  style: TextStyle(
                    fontSize: radius * 0.6,
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
