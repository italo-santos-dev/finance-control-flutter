import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';

class ExtractEmptyState extends StatelessWidget {
  final bool isFiltering;
  final VoidCallback onClearFilters;
  final VoidCallback? onAddTransaction;

  const ExtractEmptyState({
    super.key,
    required this.isFiltering,
    required this.onClearFilters,
    this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Icon(
              isFiltering ? Icons.filter_alt_off_outlined : Icons.receipt_long_outlined,
              size: 36,
              color: AppColors.blueAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltering ? 'Nenhuma movimentação encontrada' : 'Nenhum extrato registrado ainda',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltering
                ? 'Tente ajustar os filtros de período, tipo de operação ou o termo de busca.'
                : 'Suas ordens de compra, venda e proventos aparecerão consolidadas aqui.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (isFiltering)
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.blueAccent),
              label: const Text(
                'Limpar Filtros',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.blueAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.blueAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )
          else if (onAddTransaction != null)
            ElevatedButton.icon(
              onPressed: onAddTransaction,
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Cadastrar Transação',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }
}
