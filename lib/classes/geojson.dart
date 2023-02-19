import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum FeatureType {
  Polygon,
  MultiPolygon,
}

class Geojson {
  List<dynamic> digest_feature_collection(
      Map<String, dynamic> featureCollection) {
    final geometries = <dynamic>[];
    print("");
    for (final feature in featureCollection["features"]) {
      print("Name: ${feature["properties"]["name"]}");
      print("Type: ${feature["geometry"]["type"]}");

      switch (feature["geometry"]["type"]) {
        case ("Polygon"):
          {
            final coordinates = feature["geometry"]["coordinates"];
            print("Polygon count: ${coordinates.length}");
            for (final polygon in coordinates) {
              geometries.add(GeojsonPolygon(points: toLatLng(polygon)));
            }
          }
          break;
        case ("MultiPolygon"):
          {
            final coordinates = feature["geometry"]["coordinates"];
            print("Polygon count: ${coordinates.length}");
            for (final polygon in coordinates) {
              List<List<LatLng>> tmp_list = [];
              for (final poly in polygon) {
                tmp_list.add(toLatLng(poly));
              }
              geometries.add(GeoJsonMultiPolygon(
                outer: tmp_list[0],
                innerList: tmp_list.length > 1
                    ? tmp_list.getRange(1, tmp_list.length).toList()
                    : null,
              ));
            }
          }
          break;
        default:
          {
            throw Exception("Unhandled type ${feature["geometry"]["type"]}");
          }
      }
    }
    return geometries;
  }

  List<LatLng> toLatLng(List<dynamic> coordinate_list) {
    final latLngList = <LatLng>[];
    for (final coord in coordinate_list) {
      latLngList.add(LatLng(coord[1], coord[0]));
    }
    return latLngList;
  }
}

class GeojsonFeature {
  late FeatureType _type;

  FeatureType get type => _type;
}

class GeojsonPolygon extends GeojsonFeature {
  final List<LatLng> _points;

  GeojsonPolygon({required List<LatLng> points}) : _points = points {
    super._type = FeatureType.Polygon;
  }

  List<LatLng> get points => _points;

  Polygon convertToFlutterMap(
      [Color? color, Color? borderColor, bool? isFilled]) {
    return Polygon(
      points: _points,
      color: color ?? Colors.lightBlue.withOpacity(0.2),
      borderColor: borderColor ?? Colors.blue,
      isFilled: isFilled ?? true,
    );
  }
}

class GeoJsonMultiPolygon extends GeojsonFeature {
  final List<LatLng> _outer;
  final List<List<LatLng>>? _innerList;

  GeoJsonMultiPolygon(
      {required List<LatLng> outer, List<List<LatLng>>? innerList})
      : _outer = outer,
        _innerList = innerList {
    super._type = FeatureType.MultiPolygon;
  }

  List<LatLng> get outer => _outer;

  List<List<LatLng>>? get innerList => _innerList;

  Polygon convertToFlutterMap(
      [Color? color, Color? borderColor, bool? isFilled]) {
    return Polygon(
      points: _outer,
      holePointsList: _innerList,
      color: color ?? Colors.lightBlue.withOpacity(0.2),
      borderColor: borderColor ?? Colors.blue,
      isFilled: isFilled ?? true,
    );
  }
}
