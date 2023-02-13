import 'package:geojson/geojson.dart';


class Parc {
  final String name;
  final int id;
  final Map<String, dynamic> geojsonFeature;
  final Map<String, dynamic> additionalInfo;

  const Parc({
    required this.name,
    required this.id,
    required this.geojsonFeature,
    required this.additionalInfo,
  });

  factory Parc.fromJson(Map<String, dynamic> json) {
    json["geo_shape"]["properties"]["name"] = json["pnr"];

    // The GeoJson plugin is not so flexible. Eventually need to do some wrapping.
    late Map<String, dynamic> geo_shape;
    if (json["geo_shape"]["type"] != "FeatureCollection") {
      geo_shape = {"type": "FeatureCollection", "features": [json["geo_shape"]]};
    } else {
      geo_shape = json["geo_shape"];
    }
    return Parc(
      name: json["pnr"],
      id: json["id"],
      geojsonFeature: geo_shape,
      additionalInfo: json,
    );
  }

  @override
  String toString() {
    return "[$id] $name";
  }
}
