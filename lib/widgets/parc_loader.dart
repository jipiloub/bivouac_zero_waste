import 'package:bivouac_zero_waste/classes/parc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  void addParcList(Parc parc) => _parcList.add(parc);

  @override
  String toString() {
    return "$parcCount parcs";
  }
}

Future<List<Parc>> fetchParcs(List<Parc> parcList) async {
  int limit = 3;
  final start_time = DateTime.now();

  final response = await http.get(Uri.parse(
      'https://data.laregion.fr/api/v2/catalog/datasets/parcs-naturels-regionaux/records?limit=3&offset=0'));

  if (response.statusCode != 200) {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load parcs with offset 0 and limit 3');
  }
  int totalCount = jsonDecode(response.body)["total_count"];
  print("Retrieving $totalCount parcs...");

  List<Future<dynamic>> response_futures = [];
  for (var offset = 0; offset < totalCount + limit; offset += limit) {
    response_futures.add(http.get(Uri.parse(
        'https://data.laregion.fr/api/v2/catalog/datasets/parcs-naturels-regionaux/records?limit=$limit&offset=$offset')));
  }

  final responses = await Future.wait(response_futures);

  for (var response in responses) {
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // If the server did return a 200 OK response, then parse the JSON.
      for (var i = 0; i < json["records"].length; i++) {
        final fields = json["records"][i]["record"]["fields"];
        final parcName = fields["pnr"];
        final geo_shape = fields["geo_shape"];

        // If no name or no geo_shape, skip
        if (parcName == null || geo_shape == null) {
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
      "Parcs retrieved in ${DateTime.now().difference(start_time).toString()}");
  return parcList;
}
