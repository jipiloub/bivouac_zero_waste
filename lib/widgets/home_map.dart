import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bivouac_zero_waste/classes/geojson.dart';
import 'package:bivouac_zero_waste/widgets/parc_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geodesy/geodesy.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;
import 'package:latlong2/latlong.dart';

class HomeMapWidget extends StatefulWidget {
  const HomeMapWidget({Key? key}) : super(key: key);

  @override
  State<HomeMapWidget> createState() => _HomeMapWidgetState();
}

class _HomeMapWidgetState extends State<HomeMapWidget> {
  late final proj4.Projection epsg4326;
  late ParcList parcList;
  late LatLng clickedPoint;
  final initialCenter = LatLng(46.41640616670052, 5.992162595827724);

  final polygons = <Polygon>[];
  final circles = <CircleMarker>[];
  String clickedParc = "";

  Geodesy geodesy = Geodesy();

  @override
  void initState() {
    super.initState();

    // Trigger parc loading
    parcList = ParcList();

    // EPSG:4326 is a predefined projection ships with proj4dart
    epsg4326 = proj4.Projection.get('EPSG:4326')!;

    // Wait for parc loading and display them
    displayParcs();

    // Initialize clicked point. This will update the status bar
    clickedPoint = initialCenter;
  }

  void displayParcs() async {
    await parcList.futureParcList;

    for (final parc in parcList.parcs) {
      for (final feature in parc.features) {
        setState(() {
          if (feature.type == FeatureType.Polygon ||
              feature.type == FeatureType.MultiPolygon) {
            polygons.add(feature.convertToFlutterMap());
          }
        });
      }
    }
  }

  void displayCircleAtClick(LatLng point) {
    setState(() {
      clickedPoint = point;
      CircleMarker circleClickedLocation = CircleMarker(
          point: point,
          radius: 4,
          color: Colors.lightBlue.withOpacity(0.3),
          borderColor: Colors.blue,
          borderStrokeWidth: 0.5);
      // Empty the circle list
      while (circles.isNotEmpty) {
        circles.removeLast();
      }
      // Add the new circle
      circles.add(circleClickedLocation!);
    });
  }

  void checkIfClickedInParcs(LatLng point) async {
    await parcList.futureParcList;

    for (final parc in parcList.parcs) {
      for (final feature in parc.features) {
        if (feature.type == FeatureType.Polygon) {
          if (geodesy.isGeoPointInPolygon(point, feature.points)) {
            setState(() {
              clickedParc = parc.name;
            });
            if (kDebugMode) {
              print("Clicked in ${parc.toString()}");
            }
            return;
          }
        } else if (feature.type == FeatureType.MultiPolygon) {
          if (geodesy.isGeoPointInPolygon(point, feature.outer)) {
            // If point is in the outer polygon, check if it is in one of the
            // inner polygons.
            if (feature.innerList != null) {
              for (final innerPolygon in feature.innerList) {
                if (geodesy.isGeoPointInPolygon(point, innerPolygon)) {
                  // In an inner polygon: this is not included in the parc
                  setState(() {
                    clickedParc = "";
                  });
                  return;
                }
              }
            }
            setState(() {
              clickedParc = parc.name;
            });
            if (kDebugMode) {
              print("Clicked in ${parc.toString()}");
            }
            return;
          }
        }
      }
    }

    setState(() {
      clickedParc = "";
    });
  }

  String getFormattedClickedLocation() {
    return "${clickedPoint.latitude.toStringAsFixed(6)}, ${clickedPoint.longitude.toStringAsFixed(6)}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
            child: FlutterMap(
          options: MapOptions(
            center: initialCenter,
            zoom: 9,
            interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            onTap: (tapPosition, p) {
              displayCircleAtClick(p);
              checkIfClickedInParcs(p);
            },
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
            PolygonLayer(polygons: polygons),
            CircleLayer(circles: circles),
          ],
        )),
        Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            height: 40,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: Text(getFormattedClickedLocation()),
                    onLongPress: () {
                      Clipboard.setData(
                          ClipboardData(text: getFormattedClickedLocation()));
                      const snackBar =
                          SnackBar(content: Text("Copied to Clipboard"));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                  ),
                  GestureDetector(
                    child: Text(clickedParc),
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: clickedParc));
                      const snackBar =
                          SnackBar(content: Text("Copied to Clipboard"));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                  ),
                  const ParcsLoader(),
                ]))
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
