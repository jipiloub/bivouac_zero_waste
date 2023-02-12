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
      pnr: json["pnr"] ?? "Unknown PNR",
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
