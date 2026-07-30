import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/active_model.dart';
import 'package:intl/intl.dart';

/// Smooth, automated live stock ticker marquee for the Hero Banner
class StockTickerWidget extends StatefulWidget {
  final List<Active> stocks;
  final Function(Active) onStockTap;

  const StockTickerWidget({
    Key? key,
    required this.stocks,
    required this.onStockTap,
  }) : super(key: key);

  @override
  State<StockTickerWidget> createState() => _StockTickerWidgetState();
}

class _StockTickerWidgetState extends State<StockTickerWidget> {
  final ScrollController _scrollController = ScrollController();
  Timer? _tickerTimer;
  final NumberFormat _realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_scrollController.hasClients) return;
      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.offset;
      double delta = 1.0; // scroll speed px per step

      if (currentScroll >= maxScroll) {
        _scrollController.jumpTo(0.0);
      } else {
        _scrollController.jumpTo(currentScroll + delta);
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validStocks = widget.stocks.where((s) => s.lastPrice > 0.0).toList();
    if (validStocks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Duplicate list 3 times for endless seamless scrolling effect
    final displayList = [...validStocks, ...validStocks, ...validStocks];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final stock = displayList[index];
          final bool isPositive = stock.dividendYield > 0;
          final Color badgeColor = isPositive ? AppColors.emeraldGreen : AppColors.blueAccent;

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onStockTap(stock),
                borderRadius: BorderRadius.circular(20),
                hoverColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.chipDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.borderMedium.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stock Symbol
                      Text(
                        stock.symbol,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Stock Price
                      Text(
                        _realFormat.format(stock.lastPrice),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Dividend Yield Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DY ${stock.dividendYield.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
