import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'parcs.dart';

class ParcsLoader extends StatefulWidget {
  const ParcsLoader({Key? key}) : super(key: key);

  @override
  State<ParcsLoader> createState() => _ParcsLoaderState();
}

class _ParcsLoaderState extends State<ParcsLoader> {
  late Future<Parcs> futureParcs;

  @override
  void initState() {
    super.initState();
    futureParcs = fetchParcs();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Parcs>(
      future: futureParcs,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Row(
              children: List.generate(snapshot.data!.parcList.length,
                      (index) =>
                      Expanded(child: Text(
                          snapshot.data!.parcList[index].toString()))));
        } else if (snapshot.hasError) {
          throw Exception('${snapshot.error}');
        }
        // By default, show loading.
        return const CircularProgressIndicator();
      },
    );
  }

  Future<Parcs> fetchParcs() async {
    final response = await http.get(Uri.parse(
        'https://data.laregion.fr/api/v2/catalog/datasets/parcs-naturels-regionaux/records?limit=3&offset=0'));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return Parcs.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load parc');
    }
  }
}
