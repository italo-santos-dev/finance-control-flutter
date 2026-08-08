import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';

class ExtractPaginationFooter extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int recordsPerPage;
  final Function(int) onPageSelected;

  const ExtractPaginationFooter({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.recordsPerPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    int start = totalRecords == 0 ? 0 : ((currentPage - 1) * recordsPerPage) + 1;
    int end = (currentPage * recordsPerPage) > totalRecords ? totalRecords : (currentPage * recordsPerPage);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isCompact = constraints.maxWidth < 600;

        Widget infoText = Text(
          'Mostrando $start-$end de $totalRecords registros',
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
        );

        Widget pageButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous Page Button
            _buildPageButton(
              icon: Icons.chevron_left,
              isEnabled: currentPage > 1,
              onTap: () => onPageSelected(currentPage - 1),
            ),
            const SizedBox(width: 4),

            // Numbered Pills
            ..._generatePagePills().map((p) {
              if (p == -1) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                );
              }
              bool isSelected = p == currentPage;
              return GestureDetector(
                onTap: () => onPageSelected(p),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.blueAccent : AppColors.inputDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? AppColors.blueAccent : AppColors.borderDark),
                  ),
                  child: Center(
                    child: Text(
                      '$p',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(width: 4),
            // Next Page Button
            _buildPageButton(
              icon: Icons.chevron_right,
              isEnabled: currentPage < totalPages,
              onTap: () => onPageSelected(currentPage + 1),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            children: [
              infoText,
              const SizedBox(height: 12),
              pageButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            infoText,
            pageButtons,
          ],
        );
      },
    );
  }

  Widget _buildPageButton({required IconData icon, required bool isEnabled, required VoidCallback onTap}) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.inputDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Icon(icon, size: 16, color: isEnabled ? Colors.white : Colors.white24),
      ),
    );
  }

  List<int> _generatePagePills() {
    if (totalPages <= 5) {
      return List.generate(totalPages, (i) => i + 1);
    }
    if (currentPage <= 3) {
      return [1, 2, 3, -1, totalPages];
    } else if (currentPage >= totalPages - 2) {
      return [1, -1, totalPages - 2, totalPages - 1, totalPages];
    } else {
      return [1, -1, currentPage, -1, totalPages];
    }
  }
}
