import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_icons.dart';
import 'package:flutter_investment_control/models/active_model.dart';
import 'package:flutter_investment_control/pages/active/details/active_details_page.dart';
import 'package:flutter_investment_control/pages/active/active_page.dart';
import 'package:flutter_investment_control/services/api_brapi_get_logo.dart';
import 'package:flutter_investment_control/services/api_stocks_ibovespa.dart';
import 'package:flutter_investment_control/widgets/adverts/adverts_widget.dart';
import 'package:flutter_investment_control/widgets/btc/bitcoin_card_widget.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> newsList = [
    {
      "title": "Bitcoin reaches new all-time high!",
      "image":
          "https://www.cointribune.com/app/uploads/2024/02/bitcoin-proces-Australien-2.png",
    },
    {
      "title": "Major companies now accepting Bitcoin as payment",
      "image":
          "https://www.cointribune.com/app/uploads/2024/02/bitcoin-proces-Australien-2.png",
    },
    {
      "title": "Bitcoin price analysis: Is it the right time to invest?",
      "image":
          "https://www.cointribune.com/app/uploads/2024/02/bitcoin-proces-Australien-2.png",
    },
    {
      "title": "Government regulations shake up the Bitcoin market",
      "image":
          "https://www.cointribune.com/app/uploads/2024/02/bitcoin-proces-Australien-2.png",
    },
    {
      "title": "Top 5 Bitcoin wallets for secure storage",
      "image":
          "https://www.cointribune.com/app/uploads/2024/02/bitcoin-proces-Australien-2.png",
    },
  ];

  List<Active> selecionadas = [];
  List<Active> filteredStocks = [];
  String searchText = '';
  NumberFormat real = NumberFormat.currency(locale: 'pt-br', name: 'R\$');

  StockIbovespaApi api = StockIbovespaApi();
  ApiBrapiGetLogo apiBrapi = ApiBrapiGetLogo();
  List<Active> stockIndicators = [];

  InterstitialAd? _interstitialAd;

  final PageController _controller = PageController();
  int _currentPage = 0;

  TextEditingController _searchController = TextEditingController();

  late Timer _timer;
  bool isLoading = true;
  bool isDispose = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_currentPage < newsList.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _controller.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _createInterstitialAd();
    });
    fetchData();
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  fetchData() async {
    try {
      var data = await api.fetchStockIndicators();
      var logoUrls = await apiBrapi.fetchLogoUrls();

      for (var item in data) {
        var assetDetails = logoUrls.firstWhere(
          (element) => element['ticker'] == item['symbol'],
          orElse: () => {},
        );

        setState(() {
          stockIndicators.add(Active(
            icon: assetDetails.isNotEmpty
                ? assetDetails['logoUrl']
                : AppIcons.btc,
            name: item['name'],
            symbol: item['symbol'],
            lastPrice: item['lastPrice'].toDouble(),
            sector: item['sector'],
            segment: item['segment'],
            dividendYield: item['dividendYield'].toDouble(),
            lastYearHigh: item['lastYearHigh'].toDouble(),
            lastYearLow: item['lastYearLow'].toDouble(),
          ));
          filteredStocks = stockIndicators;
          isLoading = false; // Set isLoading to false after data is fetched
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Widget _buildIcon(String? iconUrl) {
    double avatarSize = 40.0;

    if (iconUrl != null && iconUrl.isNotEmpty && iconUrl.endsWith('.svg')) {
      if (iconUrl == 'https://brapi.dev/favicon.svg') {
        return CircleAvatar(
          child: Image.asset(
            AppIcons.btc,
            height: avatarSize,
            width: avatarSize,
          ),
          radius: avatarSize / 2.0,
        );
      } else {
        return ClipOval(
          child: CircleAvatar(
            child: SvgPicture.network(
              iconUrl,
              placeholderBuilder: (BuildContext context) =>
                  CircularProgressIndicator(),
              headers: {'Accept': 'image/svg+xml'},
              height: avatarSize,
              width: avatarSize,
            ),
            radius: avatarSize / 2.0,
          ),
        );
      }
    } else {
      return CircleAvatar(
        child: Image.asset(
          AppIcons.btc,
          height: avatarSize,
          width: avatarSize,
        ),
        radius: avatarSize / 2.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarDynamics(),
      bottomNavigationBar: SizedBox(
        height: 70.0,
        child: BottomAppBar(
          color: Colors.grey[200],
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomAction(
                  FontAwesomeIcons.clockRotateLeft, navigateToWalletPage),
              _bottomAction(FontAwesomeIcons.wallet, navigateToWalletPage),
              const SizedBox(width: 48.0),
              _bottomAction(FontAwesomeIcons.chartPie, navigateToWalletPage),
              _bottomAction(Icons.settings, navigateToBtcPage),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: selecionadas.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                backgroundColor: Colors.grey,
                onPressed: () {},
                shape: const CircleBorder(),
                elevation: 0.0,
                child: const Icon(Icons.add, color: Colors.black),
              ),
            )
          : null,
      body: Column(
        children: [
          // Seção de Notícias
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Text(
                    'New',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: stockIndicators.isEmpty
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: 5,
                            itemBuilder: (_, __) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Container(),
                              ),
                            ),
                          ),
                        )
                      : PageView.builder(
                          controller: _controller,
                          itemCount: newsList.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        child: Image.network(
                                          newsList[index]['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(Icons.error),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(16.0),
                                            bottomRight: Radius.circular(16.0),
                                          ),
                                          color: Colors.black.withOpacity(0.6),
                                        ),
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          newsList[index]['title'],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 16.0,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Text(
                    'Stocks',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              searchText = value.toUpperCase();
                              filteredStocks = stockIndicators
                                  .where((active) =>
                                      active.symbol
                                          .toUpperCase()
                                          .contains(searchText) ||
                                      active.name
                                          .toUpperCase()
                                          .contains(searchText) ||
                                      active.sector
                                          .toUpperCase()
                                          .contains(searchText) ||
                                      active.segment
                                          .toUpperCase()
                                          .contains(searchText))
                                  .toList();
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            border: InputBorder.none,
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            searchText = '';
                            filteredStocks = stockIndicators;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? _buildLoadingScreen()
                      : ListView.separated(
                          itemBuilder: (BuildContext context, int active) {
                            bool isSelected =
                                selecionadas.contains(filteredStocks[active]);

                            return ListTile(
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              leading: isSelected
                                  ? const CircleAvatar(
                                      child: Icon(Icons.check),
                                    )
                                  : SizedBox(
                                      width: 40.0,
                                      child: _buildIcon(
                                          filteredStocks[active].icon),
                                    ),
                              title: Text(
                                filteredStocks[active].symbol,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Text(
                                real.format(filteredStocks[active].lastPrice),
                              ),
                              selected: isSelected,
                              tileColor: isSelected ? Colors.red : null,
                              onLongPress: () {
                                setState(() {
                                  isSelected
                                      ? selecionadas
                                          .remove(filteredStocks[active])
                                      : selecionadas
                                          .add(filteredStocks[active]);
                                });
                              },
                              onTap: () => {
                                showDetails(filteredStocks[active]),
                              },
                            );
                          },
                          padding: const EdgeInsets.all(16.0),
                          separatorBuilder: (_, __) => const Divider(),
                          itemCount: filteredStocks.length,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 24.0,
            color: Colors.white,
          ),
        ),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: 10,
      ),
    );
  }

  AppBar appBarDynamics() {
    if (selecionadas.isEmpty) {
      return AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              AppIcons.logo_icon_02,
              width: 17,
            ),
            const SizedBox(width: 5.0),
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'worthy',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 16.0,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 16.0,
            ),
            onPressed: () {},
          ),
        ],
      );
    } else {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              selecionadas = [];
              filteredStocks = stockIndicators;
              _searchController.clear();
            });
          },
        ),
        title: Text('${selecionadas.length} selecionadas'),
      );
    }
  }

  showDetails(Active active) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveDetailsPage(active: active),
      ),
    );
  }

  navigateToBtcPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DividendChart(),
      ),
    );
  }

  Widget _bottomAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          color: Colors.grey[900],
          size: 20.0,
        ),
      ),
    );
  }

  void navigateToWalletPage() {
    _showInterstitialAd(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AssetList()),
      );
    });
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          // Keep a reference to the ad so you can show it later.
          _interstitialAd = ad;
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void _showInterstitialAd(OnAdClosedCallback onAdClosed) {
    if (_interstitialAd == null) {
      print('Anúncio null');
      return;
    }

    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
      },
      onAdImpression: (InterstitialAd ad) => print('$ad impression occurred.'),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Anuncio(onAdClosed: onAdClosed)),
    );

    _interstitialAd?.show();
  }
}
