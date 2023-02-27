import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geodesy/geodesy.dart';
import 'package:latlong2/latlong.dart';

enum FeatureType {
  GeoJsonPolygon,
  GeoJsonMultiPolygon,
}

GeoJsonFeature digestFeatureCollection(Map<String, dynamic> featureCollection) {
  late final GeoJsonFeature geometry;
  if (kDebugMode) {
    print("");
    if (featureCollection["features"].length > 1) {
      print("WARNING: more features than expected for this parc");
    }
  }

  final feature = featureCollection["features"][0];
  if (kDebugMode) {
    print("Name: ${feature["properties"]["name"]}");
    print("Type: ${feature["geometry"]["type"]}");
  }

  switch (feature["geometry"]["type"]) {
    case ("Polygon"):
      {
        final coordinates = feature["geometry"]["coordinates"];
        if (kDebugMode && coordinates.length > 1) {
          print(
              "WARNING: this Polygon has too much points lists: ${coordinates.length}");
        }
        if (kDebugMode) {
          print("Polygon count: ${coordinates.length}");
        }
        geometry = GeoJsonPolygon(points: toLatLng(coordinates[0]));
      }
      break;
    case ("MultiPolygon"):
      {
        final coordinates = feature["geometry"]["coordinates"];
        final tmpPolygonList = <GeoJsonPolygon>[];
        for (final polygon in coordinates) {
          List<List<LatLng>> tmpList = [];
          for (final poly in polygon) {
            tmpList.add(toLatLng(poly));
          }
          tmpPolygonList.add(GeoJsonPolygon(
            points: tmpList[0],
            innerPointsList: tmpList.length > 1
                ? tmpList.getRange(1, tmpList.length).toList()
                : null,
          ));
        }
        geometry = GeoJsonMultiPolygon(polygons: tmpPolygonList);
        if (kDebugMode) {
          geometry as GeoJsonMultiPolygon;
          print("Polygon count: ${geometry.polygons.length}");
        }
      }
      break;
    default:
      {
        throw Exception("Unhandled type ${feature["geometry"]["type"]}");
      }
  }
  return geometry;
}

List<LatLng> toLatLng(List<dynamic> coordinateList) {
  final latLngList = <LatLng>[];
  for (final coord in coordinateList) {
    latLngList.add(LatLng(coord[1], coord[0]));
  }
  return latLngList;
}

abstract class GeoJsonFeature {
  late final FeatureType _type;
  late final LatLngBounds _latLngBounds;

  FeatureType get type => _type;

  LatLngBounds get latLngBounds => _latLngBounds;

  List<Polygon> convertToFlutterMapFormat(
      {Color? color, Color? borderColor, bool? isFilled});

  bool isInGeoJsonFeature(LatLng point);

  bool isInFeatureBounds(LatLng point) {
    return _latLngBounds.contains(point);
  }
}

class GeoJsonPolygon extends GeoJsonFeature {
  // Define the outer shape
  final List<LatLng> _points;

  // Define shapes in the outer shape that should be excluded
  final List<List<LatLng>>? _innerPointsList;

  GeoJsonPolygon(
      {required List<LatLng> points, List<List<LatLng>>? innerPointsList})
      : _points = points,
        _innerPointsList = innerPointsList {
    _type = FeatureType.GeoJsonPolygon;
    _latLngBounds = LatLngBounds.fromPoints(points);
  }

  List<LatLng> get points => _points;

  List<List<LatLng>>? get innerPointsList => _innerPointsList;

  @override
  List<Polygon> convertToFlutterMapFormat(
      {Color? color, Color? borderColor, bool? isFilled}) {
    return [
      Polygon(
        points: _points,
        holePointsList: _innerPointsList,
        color: color ?? Colors.blue.withOpacity(0.2),
        borderColor: borderColor ?? Colors.blueAccent,
        borderStrokeWidth: 1.0,
        isFilled: isFilled ?? true,
      )
    ];
  }

  @override
  bool isInGeoJsonFeature(LatLng point) {
    if (Geodesy().isGeoPointInPolygon(point, _points)) {
      for (List<LatLng> innerPoints in _innerPointsList ?? []) {
        if (Geodesy().isGeoPointInPolygon(point, innerPoints)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

// This is simply a list of polygons
class GeoJsonMultiPolygon extends GeoJsonFeature {
  final List<GeoJsonPolygon> _polygons;

  GeoJsonMultiPolygon({required List<GeoJsonPolygon> polygons})
      : _polygons = polygons {
    _type = FeatureType.GeoJsonMultiPolygon;
    _latLngBounds = LatLngBounds();
    for (GeoJsonPolygon polygon in polygons) {
      _latLngBounds.extendBounds(polygon.latLngBounds);
    }
  }

  List<GeoJsonPolygon> get polygons => _polygons;

  @override
  List<Polygon> convertToFlutterMapFormat(
      {Color? color, Color? borderColor, bool? isFilled}) {
    final polygons = <Polygon>[];
    for (GeoJsonPolygon polygon in _polygons) {
      polygons.addAll(polygon.convertToFlutterMapFormat(
          color: color, borderColor: borderColor, isFilled: isFilled));
    }
    return polygons;
  }

  @override
  bool isInGeoJsonFeature(LatLng point) {
    for (GeoJsonPolygon polygon in _polygons) {
      if (polygon.isInGeoJsonFeature(point)) {
        return true;
      }
    }
    return false;
  }
}
