import 'package:flutter/material.dart';
import 'package:flutter_investment_control/pages/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigationStarted = false;

  @override
  void initState() {
    super.initState();

    // Inicia a navegação após um atraso de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (!_navigationStarted) {
        _navigationStarted = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF121212)],
          ),
        ),
        child: const Text(
          "worthy",
          style: TextStyle(
            fontSize: 40.0,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
