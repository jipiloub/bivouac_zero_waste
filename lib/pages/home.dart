import 'package:bivouac_legal_flutter/widgets/home_map.dart';
import 'package:flutter/material.dart';
import 'package:bivouac_legal_flutter/widgets/parc_loader.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('BivouacZeroWaste'),
        ),
        body: const HomeMapWidget());
  }
}
