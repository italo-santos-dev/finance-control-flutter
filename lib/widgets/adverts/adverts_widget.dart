import 'package:flutter/material.dart';

typedef OnAdClosedCallback = void Function();


class Anuncio extends StatelessWidget {
  final VoidCallback onAdClosed;

  const Anuncio({Key? key, required this.onAdClosed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
    );
  }
}

