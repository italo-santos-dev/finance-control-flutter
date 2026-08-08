import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:intl/intl.dart';

class ExtractTransactionsTable extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final Function(Map<String, dynamic>) onTransactionTap;

  const ExtractTransactionsTable({
    super.key,
    required this.transactions,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 750;

        if (isMobile) {
          return _buildMobileCardList(realFormat);
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            children: [
              // Header Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderDark)),
                ),
                child: Row(
                  children: const [
                    Expanded(flex: 3, child: Text('DATA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(flex: 4, child: Text('ATIVO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(flex: 2, child: Text('TIPO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(flex: 2, child: Text('QTD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.right)),
                    Expanded(flex: 3, child: Text('PREÇO UNIT.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.right)),
                    Expanded(flex: 3, child: Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.right)),
                    Expanded(flex: 3, child: Text('INSTITUIÇÃO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.right)),
                  ],
                ),
              ),

              // Data Rows
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const Divider(color: AppColors.borderDark, height: 1),
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  return _buildTableRow(t, realFormat);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item, NumberFormat realFormat) {
    String ticker = item['ticker'] ?? 'ATIVO';
    String segment = item['segment'] ?? 'B3 Brasil';
    String dateStr = item['formattedDate'] ?? 'Data N/D';
    String typeStr = item['typeStr'] ?? 'Compra';
    bool isBuy = typeStr.toLowerCase() == 'compra';
    int qty = item['quantity'] ?? 0;
    double price = (item['price'] as num?)?.toDouble() ?? 0.0;
    double total = (item['total'] as num?)?.toDouble() ?? (price * qty);
    String institution = item['institution'] ?? 'XP Investimentos';

    Color badgeColor = isBuy ? AppColors.emeraldGreen : AppColors.redLoss;

    return InkWell(
      onTap: () => onTransactionTap(item),
      hoverColor: AppColors.primaryBlue.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Data
            Expanded(
              flex: 3,
              child: Text(
                dateStr,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),

            // Ativo (Avatar + Symbol + Description)
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _buildAvatar(ticker),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticker,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          segment,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tipo Badge
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeStr,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ),
            ),

            // Qtd
            Expanded(
              flex: 2,
              child: Text(
                '$qty',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                textAlign: TextAlign.right,
              ),
            ),

            // Preço Unitário
            Expanded(
              flex: 3,
              child: Text(
                realFormat.format(price),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.right,
              ),
            ),

            // Total
            Expanded(
              flex: 3,
              child: Text(
                realFormat.format(total),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.right,
              ),
            ),

            // Instituição
            Expanded(
              flex: 3,
              child: Text(
                institution,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCardList(NumberFormat realFormat) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = transactions[index];
        String ticker = item['ticker'] ?? 'ATIVO';
        String segment = item['segment'] ?? 'B3 Brasil';
        String dateStr = item['formattedDate'] ?? 'Data N/D';
        String typeStr = item['typeStr'] ?? 'Compra';
        bool isBuy = typeStr.toLowerCase() == 'compra';
        int qty = item['quantity'] ?? 0;
        double price = (item['price'] as num?)?.toDouble() ?? 0.0;
        double total = (item['total'] as num?)?.toDouble() ?? (price * qty);
        String institution = item['institution'] ?? 'XP Investimentos';
        Color badgeColor = isBuy ? AppColors.emeraldGreen : AppColors.redLoss;

        return InkWell(
          onTap: () => onTransactionTap(item),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
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
                        _buildAvatar(ticker),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ticker, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(segment, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(typeStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppColors.borderDark, height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Data', style: TextStyle(fontSize: 9, color: Colors.grey)),
                        Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Qtd x Preço Unit.', style: TextStyle(fontSize: 9, color: Colors.grey)),
                        Text('$qty x ${realFormat.format(price)}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text(realFormat.format(total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Instituição: $institution', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String symbol) {
    String initials = symbol.length >= 2 ? symbol.substring(0, 2) : symbol;
    String logoUrl = 'https://icons.brapi.dev/icons/${symbol.toUpperCase()}.png';

    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
      child: ClipOval(
        child: Image.network(
          logoUrl,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 28,
              height: 28,
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
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
