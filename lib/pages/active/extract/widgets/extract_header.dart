import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';

class ExtractHeader extends StatelessWidget {
  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;

  const ExtractHeader({
    super.key,
    required this.onExportCsv,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmall = constraints.maxWidth < 600;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Extrato de Negociações',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Histórico completo de compras e vendas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildOutlinedButton(
                  icon: Icons.download_outlined,
                  label: 'CSV',
                  onTap: onExportCsv,
                  isSmall: isSmall,
                ),
                const SizedBox(width: 8),
                _buildOutlinedButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  onTap: onExportPdf,
                  isSmall: isSmall,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOutlinedButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSmall,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: Colors.white70),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.inputDark,
        side: const BorderSide(color: AppColors.borderDark),
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
