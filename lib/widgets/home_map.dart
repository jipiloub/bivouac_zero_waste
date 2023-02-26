import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bivouac_zero_waste/classes/geojson.dart';
import 'package:bivouac_zero_waste/classes/helper.dart';
import 'package:bivouac_zero_waste/widgets/parc_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;
import 'package:latlong2/latlong.dart';
import "package:stack_trace/stack_trace.dart";

class HomeMapWidget extends StatefulWidget {
  const HomeMapWidget({Key? key}) : super(key: key);

  @override
  State<HomeMapWidget> createState() => _HomeMapWidgetState();
}

class _HomeMapWidgetState extends State<HomeMapWidget> {
  late final proj4.Projection epsg4326;
  late ParcList parcList;
  late LatLng clickedPoint;
  late final MapController _mapController;

  final initialCenter = LatLng(46.41640616670052, 5.992162595827724);
  final polygons = <Polygon>[];
  final circles = <CircleMarker>[];

  String clickedParc = "";

  @override
  void initState() {
    super.initState();

    // Instantiate an empty map controller
    _mapController = MapController();

    // Trigger parc loading
    parcList = ParcList();

    // EPSG:4326 is a predefined projection ships with proj4dart
    epsg4326 = proj4.Projection.get('EPSG:4326')!;

    // Wait for parc loading and display them
    updateVisibleParcs();

    // Initialize clicked point. This will update the status bar
    clickedPoint = initialCenter;
  }

  void displayCircleAtClick(LatLng point) {
    clickedPoint = point;
    CircleMarker circleClickedLocation = CircleMarker(
        point: point,
        radius: 4,
        color: Colors.lightBlue.withOpacity(0.3),
        borderColor: Colors.blue,
        borderStrokeWidth: 0.5);
    setState(() {
      // Empty the circle list
      while (circles.isNotEmpty) {
        circles.removeLast();
      }
      // Add the new circle
      circles.add(circleClickedLocation);
    });
  }

  void checkIfClickedInParcs(LatLng point) async {
    await parcList.futureParcList;
    final start_time = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      print("");
    }

    for (final parc in parcList.parcs) {
      final feature = parc.geojsonFeature;
      if (feature.isInGeoJsonFeature(point)) {
        setState(() {
          clickedParc = parc.name;
        });
        if (kDebugMode) {
          print("Clicked in ${parc.toString()}");
          print(
              "${Trace.current().frames[0].member}: ${DateTime.now().millisecondsSinceEpoch - start_time}ms");
        }
        return;
      }
    }

    setState(() {
      clickedParc = "";
    });
    if (kDebugMode) {
      print(
          "${Trace.current().frames[0].member}: ${DateTime.now().millisecondsSinceEpoch - start_time}ms");
    }
  }

  String getFormattedClickedLocation() {
    return "${clickedPoint.latitude.toStringAsFixed(6)}, ${clickedPoint.longitude.toStringAsFixed(6)}";
  }

  void updateVisibleParcs() async {
    await parcList.futureParcList;
    final start_time = DateTime.now().millisecondsSinceEpoch;

    if (kDebugMode) {
      print("");
    }

    final currentViewBounds = _mapController.bounds ?? LatLngBounds();
    if (currentViewBounds.isValid == false) {
      print("WARNING: current view has no bounds");
      return;
    }
    print(
        "View bounds: [[${currentViewBounds.east}, ${currentViewBounds.west}],"
        " [${currentViewBounds.north}, ${currentViewBounds.south}]");

    // Remove displayed polygons
    setState(() {
      while (polygons.isNotEmpty) {
        polygons.removeLast();
      }
    });

    for (final parc in parcList.parcs) {
      switch (parc.geojsonFeature.type) {
        case FeatureType.GeoJsonPolygon:
          {
            final feature = parc.geojsonFeature as GeoJsonPolygon;
            if (currentViewBounds.isOverlapping(feature.latLngBounds)) {
              print("${parc.name} is in the view");
              setState(() {
                polygons.add(feature.convertToFlutterMapFormat());
              });
            }
          }
          break;
        case FeatureType.GeoJsonMultiPolygon:
          {
            final feature = parc.geojsonFeature as GeoJsonMultiPolygon;
            if (currentViewBounds.isOverlapping(feature.latLngBounds)) {
              print("${parc.name} is in the view");
              setState(() {
                polygons.addAll(feature.convertToFlutterMapFormat());
              });
            }
          }
          break;
        default:
          {
            throw Exception("Error: Unknown type: ${parc.geojsonFeature.type}");
          }
      }
    }

    print(
        "${Trace.current().frames[0].member}: ${DateTime.now().millisecondsSinceEpoch - start_time}ms");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
            child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
              center: initialCenter,
              zoom: 9,
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              onTap: (tapPosition, p) {
                displayCircleAtClick(p);
                checkIfClickedInParcs(p);
              },
              // Update the visible parcs while the map is moving. Does not seem
              // to work on phones.
              // onPositionChanged: (a, b) {
              //   updateVisibleParcs();
              // }
              onMapEvent: (mapEvent) {
                if (mapEvent.runtimeType == MapEventMoveEnd) {
                  updateVisibleParcs();
                }
                if (getPlatform() != PlatformCustom.webMobile) {
                  if (mapEvent.runtimeType == MapEventFlingAnimation ||
                      mapEvent.runtimeType == MapEventScrollWheelZoom ||
                      mapEvent.runtimeType == MapEventMove) {
                    updateVisibleParcs();
                  }
                }
              }),
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
