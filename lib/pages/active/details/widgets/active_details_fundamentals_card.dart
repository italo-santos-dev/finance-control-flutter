import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/active_model.dart';

class ActiveDetailsFundamentalsCard extends StatefulWidget {
  final Active active;
  final String Function(String, {bool isPct, bool isMultiplier, double? fallbackIfMissing}) formatIndicatorStr;
  final double? Function(String) getRawIndicatorValue;

  const ActiveDetailsFundamentalsCard({
    super.key,
    required this.active,
    required this.formatIndicatorStr,
    required this.getRawIndicatorValue,
  });

  @override
  State<ActiveDetailsFundamentalsCard> createState() => _ActiveDetailsFundamentalsCardState();
}

class _ActiveDetailsFundamentalsCardState extends State<ActiveDetailsFundamentalsCard> {
  bool _showAllFundamentalGroups = false;

  @override
  Widget build(BuildContext context) {
    double dyVal = widget.active.dividendYield > 0 ? widget.active.dividendYield : (widget.getRawIndicatorValue('dividendYield') ?? 0.0);
    String dyStr = dyVal > 0 ? '${dyVal.toStringAsFixed(2)}%' : widget.formatIndicatorStr('dividendYield', isPct: true);

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
                  const Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    'INDICADORES FUNDAMENTALISTAS ${widget.active.symbol}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Comparar indicadores', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 6),
                  Switch(
                    value: false,
                    onChanged: (v) {},
                    activeColor: AppColors.primaryBlue,
                  ),
                ],
              ),
            ],
          ),
          Text(
            'Confira os fundamentos das ações de ${widget.active.symbol}.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Valuation Group (Visible by Default)
          _buildFundamentalGroupTitle('Valuation'),
          const SizedBox(height: 10),
          _buildIndicatorGrid([
            {'label': 'P/L', 'val': widget.formatIndicatorStr('pe')},
            {'label': 'P/VP', 'val': widget.formatIndicatorStr('priceToBook')},
            {'label': 'P/Receita (PSR)', 'val': widget.formatIndicatorStr('priceToSales')},
            {'label': 'EV/Ebitda', 'val': widget.formatIndicatorStr('enterpriseValueToEbitda')},
            {'label': 'EV/Ebit', 'val': widget.formatIndicatorStr('enterpriseValueToEbit')},
            {'label': 'P/Ebitda', 'val': widget.formatIndicatorStr('priceToEbitda')},
            {'label': 'P/Ebit', 'val': widget.formatIndicatorStr('priceToEbit')},
            {'label': 'P/Ativo', 'val': widget.formatIndicatorStr('priceToAssets')},
            {'label': 'P/Ativo Circ. Liq.', 'val': widget.formatIndicatorStr('priceToNetCurrentAssets')},
            {'label': 'P/Cap.Giro', 'val': widget.formatIndicatorStr('priceToWorkingCapital')},
            {'label': 'LPA', 'val': widget.formatIndicatorStr('lpa')},
            {'label': 'VPA', 'val': widget.formatIndicatorStr('vpa')},
          ]),

          // Additional Groups (Shown when _showAllFundamentalGroups is true)
          if (_showAllFundamentalGroups) ...[
            const SizedBox(height: 20),
            _buildFundamentalGroupTitle('Eficiência'),
            const SizedBox(height: 10),
            _buildIndicatorGrid([
              {'label': 'Margem Bruta', 'val': widget.formatIndicatorStr('grossMargin', isPct: true)},
              {'label': 'Margem Ebitda', 'val': widget.formatIndicatorStr('ebitdaMargin', isPct: true)},
              {'label': 'Margem Ebit', 'val': widget.formatIndicatorStr('ebitMargin', isPct: true)},
              {'label': 'Margem Líquida', 'val': widget.formatIndicatorStr('netMargin', isPct: true)},
              {'label': 'Giro Ativos', 'val': widget.formatIndicatorStr('assetTurnover')},
            ]),
            const SizedBox(height: 20),
            _buildFundamentalGroupTitle('Rentabilidade'),
            const SizedBox(height: 10),
            _buildIndicatorGrid([
              {'label': 'ROE', 'val': widget.formatIndicatorStr('roe', isPct: true)},
              {'label': 'ROA', 'val': widget.formatIndicatorStr('roa', isPct: true)},
              {'label': 'ROIC', 'val': widget.formatIndicatorStr('roic', isPct: true)},
            ]),
            const SizedBox(height: 20),
            _buildFundamentalGroupTitle('Dividendos'),
            const SizedBox(height: 10),
            _buildIndicatorGrid([
              {'label': 'Dividend Yield', 'val': dyStr},
              {'label': 'Payout', 'val': widget.formatIndicatorStr('payout', isPct: true)},
            ]),
            const SizedBox(height: 20),
            _buildFundamentalGroupTitle('Endividamento'),
            const SizedBox(height: 10),
            _buildIndicatorGrid([
              {'label': 'Liquidez Corrente', 'val': widget.formatIndicatorStr('currentLiquidity')},
              {'label': 'Divida Liquida/Ebitda', 'val': widget.formatIndicatorStr('netDebtToEbitda')},
              {'label': 'Divida Liquida/Ebit', 'val': widget.formatIndicatorStr('netDebtToEbit')},
              {'label': 'Divida Liquida/Patrimônio', 'val': widget.formatIndicatorStr('netDebtToEquity')},
              {'label': 'Divida Bruta/Patrimônio', 'val': widget.formatIndicatorStr('grossDebtToEquity')},
              {'label': 'Patrimônio/Ativos', 'val': widget.formatIndicatorStr('equityToAssets')},
              {'label': 'Passivos/Ativos', 'val': widget.formatIndicatorStr('liabilitiesToAssets')},
            ]),
            const SizedBox(height: 20),
            _buildFundamentalGroupTitle('Crescimento'),
            const SizedBox(height: 10),
            _buildIndicatorGrid([
              {'label': 'CAGR Receitas 5 anos', 'val': widget.formatIndicatorStr('cagrRevenuesFiveYears', isPct: true)},
              {'label': 'CAGR Lucros 5 anos', 'val': widget.formatIndicatorStr('cagrProfitsFiveYears', isPct: true)},
            ]),
          ],

          const SizedBox(height: 16),

          // Toggle Button to expand/collapse
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showAllFundamentalGroups = !_showAllFundamentalGroups;
                });
              },
              icon: Icon(
                _showAllFundamentalGroups ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.blueAccent,
              ),
              label: Text(
                _showAllFundamentalGroups ? 'Ocultar outros indicadores' : 'Ver todos os indicadores fundamentalistas',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.blueAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.blueAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundamentalGroupTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.blueAccent),
    );
  }

  Widget _buildIndicatorGrid(List<Map<String, String>> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 6 : (constraints.maxWidth > 500 ? 3 : 2);
        double itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 10)) / crossAxisCount;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              height: 72,
              child: _buildInvestidor10IndicatorTile(item['label']!, item['val']!),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInvestidor10IndicatorTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.help_outline, size: 12, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Icon(Icons.show_chart, size: 14, color: AppColors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }
}
