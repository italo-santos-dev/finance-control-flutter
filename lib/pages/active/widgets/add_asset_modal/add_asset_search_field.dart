import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';

class AddAssetSearchField extends StatefulWidget {
  final Function(Map<String, dynamic>) onAssetSelected;
  final List<Map<String, dynamic>> knownAssets;

  const AddAssetSearchField({
    super.key,
    required this.onAssetSelected,
    required this.knownAssets,
  });

  @override
  State<AddAssetSearchField> createState() => _AddAssetSearchFieldState();
}

class _AddAssetSearchFieldState extends State<AddAssetSearchField> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim().toUpperCase());
    });
  }

  void _performSearch(String query) {
    List<Map<String, dynamic>> results = [];

    // Search against known database/cache
    for (var a in widget.knownAssets) {
      String ticker = (a['ticker'] ?? a['symbol'] ?? '').toString().toUpperCase();
      String name = (a['name'] ?? a['segment'] ?? '').toString().toUpperCase();

      if (ticker.contains(query) || name.contains(query)) {
        results.add(a);
      }
    }

    // If ticker looks like a B3 symbol (e.g. PETR4, ITUB4, HGLG11, MXRF11, WEGE3, VALE3)
    if (results.isEmpty && query.length >= 3) {
      String inferredType = query.endsWith('11') ? 'FII' : (query.endsWith('34') ? 'BDR' : 'Ação');
      results.add({
        'ticker': query,
        'symbol': query,
        'name': '$query S.A.',
        'segment': 'B3 Brasil',
        'activeType': inferredType,
        'lastPrice': 0.0,
      });
    }

    if (mounted) {
      setState(() {
        _searchResults = results.take(6).toList();
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buscar ativo',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Digite o ticker ou nome da empresa (ex: PETR4)',
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.normal),
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.blueAccent),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                    ),
                  )
                : (_searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null),
            filled: true,
            fillColor: AppColors.inputDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
          ),
        ),
        const SizedBox(height: 10),

        // Suggestions List or Empty Feedback
        if (_hasSearched) ...[
          if (_isSearching)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text('Buscando ativo na B3...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else if (_searchResults.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: const [
                  Icon(Icons.search_off, size: 28, color: Colors.grey),
                  SizedBox(height: 6),
                  Text(
                    'Não encontramos esse ativo.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Verifique o ticker ou tente outro nome.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(color: AppColors.borderDark, height: 1),
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  String ticker = item['ticker'] ?? item['symbol'] ?? '';
                  String name = item['name'] ?? item['segment'] ?? ticker;
                  String type = item['activeType'] ?? 'Ação';
                  String tag = '$ticker · $type · B3';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: _buildMiniAvatar(ticker),
                    title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(tag, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.blueAccent),
                    onTap: () {
                      _searchController.text = ticker;
                      setState(() {
                        _searchResults = [];
                        _hasSearched = false;
                      });
                      widget.onAssetSelected(item);
                    },
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildMiniAvatar(String symbol) {
    String initials = symbol.length >= 2 ? symbol.substring(0, 2) : symbol;
    String logoUrl = 'https://icons.brapi.dev/icons/${symbol.toUpperCase()}.png';

    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
      child: ClipOval(
        child: Image.network(
          logoUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.heroGradientStart],
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
