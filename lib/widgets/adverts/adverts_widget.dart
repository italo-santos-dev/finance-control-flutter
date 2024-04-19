// import 'package:flutter/material.dart';
//
// typedef OnAdClosedCallback = void Function();
//
//
// class Anuncio extends StatelessWidget {
//   final VoidCallback onAdClosed;
//
//   const Anuncio({Key? key, required this.onAdClosed}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//     );
//   }
// }

import 'package:flutter/material.dart';

typedef OnAdClosedCallback = void Function();

class LoadingScreen extends StatelessWidget {

  final VoidCallback onAdClosed;

  const LoadingScreen({Key? key, required this.onAdClosed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }
}
