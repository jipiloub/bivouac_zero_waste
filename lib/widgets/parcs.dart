import 'package:flutter/foundation.dart';

class Parc {
  final String pnr;
  final int id;
  final Map<String, dynamic>? geoShape;
  final Map<String, dynamic> additionalInfo;

  const Parc({
    required this.pnr,
    required this.id,
    this.geoShape,
    required this.additionalInfo,
  });

  factory Parc.fromJson(Map<String, dynamic> json) {
    return Parc(
      pnr: json["pnr"],
      id: json["id"],
      geoShape: json["geo_shape"],
      additionalInfo: json,
    );
  }

  @override
  String toString() {
    return "[$id] $pnr: ${geoShape?["geometry"]["coordinates"].length ?? 0} points";
  }
}

class Parcs {
  final List<Parc> parcList;

  const Parcs({
    required this.parcList,
  });

  factory Parcs.fromJson(Map<String, dynamic> json) {
    var parcList = List<Parc>.empty(growable: true);
    for (var i = 0; i < json["records"].length; i++) {
      parcList.add(Parc.fromJson(json["records"][i]["record"]["fields"]));
    }

    return Parcs(
      parcList: parcList,
    );
  }
}

