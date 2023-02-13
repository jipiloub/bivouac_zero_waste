import 'dart:async';
import 'dart:convert';

import 'package:bivouac_zero_waste/widgets/parc_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geojson/geojson.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;
import 'package:latlong2/latlong.dart';
import 'package:map_controller_plus/map_controller_plus.dart';

class HomeMapWidget extends StatefulWidget {
  const HomeMapWidget({Key? key}) : super(key: key);

  @override
  State<HomeMapWidget> createState() => _HomeMapWidgetState();
}

class _HomeMapWidgetState extends State<HomeMapWidget> {
  late ParcList parcList;
  late final proj4.Projection epsg4326;
  late final MapController mapController;
  late final StatefulMapController statefulMapController;
  late final StreamSubscription<StatefulMapControllerStateChange> sub;

  proj4.Point clickedPoint =
      proj4.Point(x: 46.41640616670052, y: 5.992162595827724);

  @override
  void initState() {
    super.initState();

    // Load parcs
    parcList = ParcList();

    // EPSG:4326 is a predefined projection ships with proj4dart
    epsg4326 = proj4.Projection.get('EPSG:4326')!;

    // intialize the controllers
    mapController = MapController();
    statefulMapController = StatefulMapController(mapController: mapController);
    /// [Important] listen to the changefeed to rebuild the map on changes:
    /// this will rebuild the map when for example addMarker or any method
    /// that mutates the map assets is called
    sub = statefulMapController.changeFeed.listen((change) => setState(() {}));
    displayParcs();
  }

  void displayParcs() async {
    await ParcList().futureParcList;
    for (final parc in parcList.parcs) {
      statefulMapController.fromGeoJson(jsonEncode(parc.geojsonFeature));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
            child: FlutterMap(
              mapController: mapController,
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
                PolygonLayer(polygons: statefulMapController.polygons)
              ],
        )),
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child:
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${clickedPoint.x.toStringAsFixed(6)}, ${clickedPoint.y.toStringAsFixed(6)}"),
              ParcsLoader()
            ]
          )
        )
      ],
    );
  }

  @override
  void dispose() {
    sub.cancel();
    mapController.dispose();
    super.dispose();
  }
}
