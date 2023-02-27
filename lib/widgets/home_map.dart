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

import '../classes/parc.dart';

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

  Parc? clickedParc;
  Parc? hoveredParc;
  List<Parc> visibleParcList = <Parc>[];
  Parc? oldClickedParc;
  Parc? oldHoveredParc;
  List<Parc> oldVisibleParcList = <Parc>[];

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
        color: Colors.blue.withOpacity(0.5),
        borderColor: Colors.white,
        borderStrokeWidth: 1);
    setState(() {
      // Empty the circle list
      while (circles.isNotEmpty) {
        circles.removeLast();
      }
      // Add the new circle
      circles.add(circleClickedLocation);
    });
  }

  void checkIfParcHovered(LatLng point) async {
    await parcList.futureParcList;

    final filteredParcList = parcList.getParcsOnPoint(point);

    Parc? tmpHoveredParc;
    for (Parc parc in filteredParcList) {
      if (parc.geojsonFeature.isInGeoJsonFeature(point)) {
        tmpHoveredParc = parc;
      }
    }

    setState(() {
      if (hoveredParc != tmpHoveredParc) {
        hoveredParc = tmpHoveredParc;
        print("Parc hovered: $hoveredParc");
        redrawPolygons();
      }
    });
  }

  void checkIfClickedInParcs(LatLng point) async {
    await parcList.futureParcList;
    final start_time = DateTime.now().millisecondsSinceEpoch;

    Parc? tmpClickedParc;
    final filteredParcList = parcList.getParcsOnPoint(point);
    for (Parc parc in filteredParcList) {
      if (parc.geojsonFeature.isInGeoJsonFeature(point)) {
        tmpClickedParc = parc;
        break;
      }
    }

    if (kDebugMode) {
      print(
          "${Trace.current().frames[0].member}: ${DateTime.now().millisecondsSinceEpoch - start_time}ms");
    }

    setState(() {
      if (clickedParc != tmpClickedParc) {
        clickedParc = tmpClickedParc;
        print("Parc clicked: $clickedParc");
        redrawPolygons();
      }
    });
  }

  String getFormattedClickedLocation() {
    return "${clickedPoint.latitude.toStringAsFixed(6)}, ${clickedPoint.longitude.toStringAsFixed(6)}";
  }

  void updateVisibleParcs() async {
    await parcList.futureParcList;

    final currentViewBounds = _mapController.bounds ?? LatLngBounds();
    if (currentViewBounds.isValid == false) {
      return;
    }

    visibleParcList = parcList.getParcsInBounds(currentViewBounds);

    redrawPolygons();
  }

  void redrawPolygons() async {
    bool visibleParcListChanged = false;
    if (visibleParcList.length != oldVisibleParcList.length) {
      visibleParcListChanged = true;
    } else {
      for (Parc parc in visibleParcList) {
        final index = oldVisibleParcList
            .indexWhere((element) => element.name == parc.name);
        if (index >= 0) {
          // Item from new list can be found in old list. Go to next items...
          continue;
        } else {
          // Item from new list CANNOT be found in old list. The lists are different. Stop here...
          visibleParcListChanged = true;
          break;
        }
      }
    }
    if (visibleParcListChanged ||
        clickedParc != oldClickedParc ||
        hoveredParc != oldHoveredParc) {
      setState(() {
        // Remove displayed polygons
        while (polygons.isNotEmpty) {
          polygons.removeLast();
        }
      });
      for (Parc parc in visibleParcList) {
        if (hoveredParc != null) {
          if (parc.name == hoveredParc!.name) {
            continue;
          }
        }
        if (clickedParc != null) {
          if (parc.name == clickedParc!.name) {
            continue;
          }
        }
        setState(() {
          polygons.addAll(parc.geojsonFeature.convertToFlutterMapFormat());
        });
      }
      final hoveredAndClickedColor = Colors.blue.withOpacity(0.3);
      const hoveredAndClickedBorderColor = Colors.white;
      if (hoveredParc != null) {
        polygons.addAll(hoveredParc!.geojsonFeature.convertToFlutterMapFormat(
            color: hoveredAndClickedColor,
            borderColor: hoveredAndClickedBorderColor));
      }
      // If clicked parc is different than hovered parc
      if (clickedParc != null && clickedParc != hoveredParc) {
        polygons.addAll(clickedParc!.geojsonFeature.convertToFlutterMapFormat(
            color: hoveredAndClickedColor,
            borderColor: hoveredAndClickedBorderColor));
      }
      oldVisibleParcList = visibleParcList;
      oldClickedParc = clickedParc;
      oldHoveredParc = hoveredParc;
    }
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
            },
            onPointerHover: (event, point) {
              checkIfParcHovered(point);
            },
            onTap: (tapPosition, point) {
              displayCircleAtClick(point);
              checkIfClickedInParcs(point);
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
                    child: Text(clickedParc != null ? clickedParc!.name : ""),
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(
                          text: clickedParc != null ? clickedParc!.name : ""));
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
