import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';

class ExtractFiltersBar extends StatelessWidget {
  final String selectedPeriod;
  final String searchQuery;
  final String selectedType;
  final Function(String) onPeriodChanged;
  final Function(String) onSearchChanged;
  final Function(String) onTypeChanged;

  const ExtractFiltersBar({
    super.key,
    required this.selectedPeriod,
    required this.searchQuery,
    required this.selectedType,
    required this.onPeriodChanged,
    required this.onSearchChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<String> periods = ['Hoje', '7D', '30D', '12M', 'Tudo'];

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isCompact = constraints.maxWidth < 800;

        Widget periodPills = Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.inputDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: periods.map((p) {
              bool isSelected = selectedPeriod == p;
              return GestureDetector(
                onTap: () => onPeriodChanged(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.cardDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected ? Border.all(color: AppColors.borderMedium) : null,
                  ),
                  child: Text(
                    p,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );

        Widget searchField = SizedBox(
          width: isCompact ? double.infinity : 220,
          height: 38,
          child: TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(fontSize: 12, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar ticker...',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              filled: true,
              fillColor: AppColors.inputDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderDark)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderDark)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue)),
            ),
          ),
        );

        Widget typeDropdown = Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.inputDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedType,
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
              items: const [
                DropdownMenuItem(value: 'Todos Tipos', child: Text('Todos Tipos')),
                DropdownMenuItem(value: 'Compra', child: Text('Compra')),
                DropdownMenuItem(value: 'Venda', child: Text('Venda')),
                DropdownMenuItem(value: 'Proventos', child: Text('Proventos')),
              ],
              onChanged: (val) {
                if (val != null) onTypeChanged(val);
              },
            ),
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: periodPills,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 8),
                  typeDropdown,
                ],
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            periodPills,
            Row(
              children: [
                searchField,
                const SizedBox(width: 8),
                typeDropdown,
              ],
            ),
          ],
        );
      },
    );
  }
}
