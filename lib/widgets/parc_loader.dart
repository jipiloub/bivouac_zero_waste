import 'package:bivouac_zero_waste/classes/parc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../classes/geojson.dart';

class ParcsLoader extends StatefulWidget {
  const ParcsLoader({Key? key}) : super(key: key);

  @override
  State<ParcsLoader> createState() => _ParcsLoaderState();
}

class _ParcsLoaderState extends State<ParcsLoader> {
  late ParcList parcList;

  @override
  void initState() {
    super.initState();
    parcList = ParcList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Parc>>(
      future: parcList.futureParcList,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text("${snapshot.data!.length.toString()} parcs");
        } else if (snapshot.hasError) {
          throw Exception('${snapshot.error}');
        }
        // By default, show progress indicator.
        return const CircularProgressIndicator();
      },
    );
  }
}

// Singleton class
// Credit: https://dev.to/lucianojung/global-variable-access-in-flutter-3ijm
class ParcList {
  static final ParcList _instance = ParcList._internal();
  final List<Parc> _parcList = List<Parc>.empty(growable: true);
  late Future<List<Parc>> _futureParcList;

  // passes the instantiation to the _instance object
  factory ParcList() => _instance;

  //initialize variables in here
  ParcList._internal() {
    _futureParcList = fetchParcs(_parcList);
  }

  //short getters
  List<Parc> get parcs => _parcList;

  Future<List<Parc>> get futureParcList => _futureParcList;

  int get parcCount => _parcList.length;

  //short setters
  void addParc(Parc parc) => _parcList.add(parc);

  List<Parc> getParcsInBounds(LatLngBounds currentViewBounds) {
    final filteredParcList = <Parc>[];
    for (final parc in _parcList) {
      if (currentViewBounds.isOverlapping(parc.geojsonFeature.latLngBounds)) {
        filteredParcList.add(parc);
      }
    }
    return filteredParcList;
  }

  List<Parc> getParcsOnPoint(LatLng point) {
    final filteredParcList = <Parc>[];
    for (final parc in _parcList) {
      if (parc.geojsonFeature.isInFeatureBounds(point)) {
        filteredParcList.add(parc);
      }
    }
    return filteredParcList;
  }

  @override
  String toString() {
    return "$parcCount parcs";
  }
}

Future<List<Parc>> fetchParcs(List<Parc> parcList) async {
  int limit = 3;
  final startTime = DateTime.now();

  final response = await http.get(Uri.parse(
      'https://data.laregion.fr/api/v2/catalog/datasets/parcs-naturels-regionaux/records?limit=3&offset=0'));

  if (response.statusCode != 200) {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load parcs with offset 0 and limit 3');
  }
  int totalCount = jsonDecode(response.body)["total_count"];
  print("Retrieving $totalCount parcs...");

  List<Future<dynamic>> responseFutures = [];
  for (var offset = 0; offset < totalCount + limit; offset += limit) {
    responseFutures.add(http.get(Uri.parse(
        'https://data.laregion.fr/api/v2/catalog/datasets/parcs-naturels-regionaux/records?limit=$limit&offset=$offset')));
  }

  final responses = await Future.wait(responseFutures);

  for (var response in responses) {
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // If the server did return a 200 OK response, then parse the JSON.
      for (var i = 0; i < json["records"].length; i++) {
        final fields = json["records"][i]["record"]["fields"];
        final parcName = fields["pnr"];
        final geoShape = fields["geo_shape"];

        // If no name or no geo_shape, skip
        if (parcName == null || geoShape == null) {
          if (kDebugMode) {
            print("Skipping parc ${parcName ?? ''}");
          }
          continue;
        }

        // Add the parc to the list
        parcList.add(Parc.fromJson(fields));
        if (kDebugMode) {
          print("New parc $parcName");
        }
      }
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load some parcs');
    }
  }
  print(
      "Parcs retrieved in ${DateTime.now().difference(startTime).toString()}");
  return parcList;
}
