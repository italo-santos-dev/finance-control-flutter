import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PortfolioHeader extends StatelessWidget {
  final bool hideValues;
  final VoidCallback onToggleHideValues;
  final VoidCallback onAddAsset;

  const PortfolioHeader({
    super.key,
    required this.hideValues,
    required this.onToggleHideValues,
    required this.onAddAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'VISÃO CONSOLIDADA DO SEU PORTFÓLIO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: hideValues ? 'Mostrar valores' : 'Ocultar valores',
                icon: FaIcon(
                  hideValues ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                  color: Colors.grey,
                  size: 18.0,
                ),
                onPressed: onToggleHideValues,
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Notificações',
                icon: const Icon(Icons.notifications_none, color: Colors.grey, size: 20.0),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sem novas notificações no portfólio')),
                  );
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onAddAsset,
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Novo Ativo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
