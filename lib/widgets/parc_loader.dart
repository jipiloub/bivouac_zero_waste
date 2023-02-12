import 'package:bivouac_legal_flutter/widgets/parc.dart';
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
          return Text(snapshot.data!.length.toString());
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

  //short setters
  void addParcList(Parc parc) => _parcList.add(parc);
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

  for (var offset = 0; offset < totalCount + limit; offset += limit) {
    final response = await http.get(Uri.parse(
        'https://data.laregion.fr/api/v2/catalog/datasets/parcs-naturels-regionaux/records?limit=$limit&offset=$offset'));
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // If the server did return a 200 OK response,
      // then parse the JSON.
      for (var i = 0; i < json["records"].length; i++) {
        parcList.add(Parc.fromJson(json["records"][i]["record"]["fields"]));
      }
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception(
          'Failed to load parcs with offset $offset and limit $limit');
    }
  }
  print(
      "Parcs retrieved in ${DateTime.now().difference(start_time).toString()}");
  return parcList;
}
