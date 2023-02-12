import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'parc.dart';

class ParcsLoader extends StatefulWidget {
  const ParcsLoader({Key? key}) : super(key: key);

  @override
  State<ParcsLoader> createState() => _ParcsLoaderState();
}

class _ParcsLoaderState extends State<ParcsLoader> {
  late Future<List<Parc>> futureParcs;

  @override
  void initState() {
    super.initState();
    futureParcs = fetchParcs();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Parc>>(
      future: futureParcs,
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

  Future<List<Parc>> fetchParcs() async {
    int limit = 3;
    var parcList = List<Parc>.empty(growable: true);

    final response = await http.get(Uri.parse(
        'https://data.laregion.fr/api/v2/catalog/datasets/parcs-naturels-regionaux/records?limit=3&offset=0'));

    if (response.statusCode != 200) {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load parcs with offset 0 and limit 3');
    }
    else {
      print("Initial response received");
    }
    int totalCount = jsonDecode(response.body)["total_count"];
    print("Parc count: $totalCount");

    for (var offset = 0; offset < totalCount + limit; offset+=limit) {
      final response = await http.get(Uri.parse('https://data.laregion.fr/api/v2/catalog/datasets/parcs-naturels-regionaux/records?limit=$limit&offset=$offset'));
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
    return parcList;
  }
}
