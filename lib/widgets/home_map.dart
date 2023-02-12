import 'package:bivouac_legal_flutter/widgets/parc_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;
import 'package:latlong2/latlong.dart';

class HomeMapWidget extends StatefulWidget {
  const HomeMapWidget({Key? key}) : super(key: key);

  @override
  State<HomeMapWidget> createState() => _HomeMapWidgetState();
}

class _HomeMapWidgetState extends State<HomeMapWidget> {
  late ParcList parcList;
  late final proj4.Projection epsg4326;

  proj4.Point clickedPoint =
      proj4.Point(x: 46.41640616670052, y: 5.992162595827724);

  @override
  void initState() {
    super.initState();

    // Load parcs
    parcList = ParcList();

    // EPSG:4326 is a predefined projection ships with proj4dart
    epsg4326 = proj4.Projection.get('EPSG:4326')!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
            child: FlutterMap(
          options: MapOptions(
            center: LatLng(clickedPoint.x, clickedPoint.y),
            zoom: 9,
            onTap: (tapPosition, p) => setState(() {
              clickedPoint = proj4.Point(x: p.latitude, y: p.longitude);
            }),
          ),
          nonRotatedChildren: [
            AttributionWidget.defaultWidget(
              source: 'OpenStreetMap contributors',
              onSourceTapped: null,
            ),
          ],
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
          ],
        )),
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child: Text(
              "${clickedPoint.x.toStringAsFixed(6)}, ${clickedPoint.y.toStringAsFixed(6)}"),
        )
      ],
    );
  }
}
