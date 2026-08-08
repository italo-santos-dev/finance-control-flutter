import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:intl/intl.dart';

class AddAssetOperationForm extends StatelessWidget {
  final TextEditingController quantityController;
  final TextEditingController purchasePriceController;
  final TextEditingController feesController;
  final String selectedBroker;
  final DateTime purchaseDate;
  final Function(String) onBrokerChanged;
  final Function(DateTime) onDateSelected;
  final VoidCallback onValuesChanged;

  const AddAssetOperationForm({
    super.key,
    required this.quantityController,
    required this.purchasePriceController,
    required this.feesController,
    required this.selectedBroker,
    required this.purchaseDate,
    required this.onBrokerChanged,
    required this.onDateSelected,
    required this.onValuesChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<String> brokers = [
      'XP Investimentos',
      'NuInvest',
      'BTG Pactual',
      'Banco Inter',
      'Clear Corretora',
      'Itaú Corretora',
      'Ágora Investimentos',
      'Rico Investimentos',
      'Binance',
      'Mercado Bitcoin',
      'Outra Corretora',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dados da Operação',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),

        // Row 1: Quantidade and Preço de Compra
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quantidade', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                    onChanged: (_) => onValuesChanged(),
                    decoration: _inputDecoration('Ex: 100'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preço de compra (pago)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: purchasePriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                    onChanged: (_) => onValuesChanged(),
                    decoration: _inputDecoration('Ex: 35,20'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Data da Compra and Corretora
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker Clickable Field
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data da compra', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: purchaseDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primaryBlue,
                                onPrimary: Colors.white,
                                surface: AppColors.cardDark,
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        onDateSelected(picked);
                      }
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(purchaseDate),
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                          ),
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.blueAccent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Broker Dropdown Field
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Corretora', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.inputDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: brokers.contains(selectedBroker) ? selectedBroker : brokers.first,
                        dropdownColor: AppColors.cardDark,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                        items: brokers.map((b) {
                          return DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onBrokerChanged(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Optional Fees / Costs Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Taxas e Custos (opcional)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              controller: feesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13, color: Colors.white),
              onChanged: (_) => onValuesChanged(),
              decoration: _inputDecoration('Ex: 0,00 (emolumentos/corretagem)'),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      filled: true,
      fillColor: AppColors.inputDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderDark)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderDark)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue)),
    );
  }
}
