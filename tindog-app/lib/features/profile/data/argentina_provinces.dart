/// Provincias argentinas (GeoRef ids) + capitales.
class ArgentinaProvince {
  const ArgentinaProvince({
    required this.id,
    required this.name,
    required this.shortName,
    required this.capital,
  });

  /// Id oficial GeoRef (ej. `14` Córdoba, `02` CABA).
  final String id;
  final String name;

  /// Para guardar/mostrar: CABA, Buenos Aires, Córdoba…
  final String shortName;

  /// Capital provincial (en CABA no aplica; se usan barrios).
  final String? capital;

  bool get isCaba => id == '02';
}

/// Las 24 jurisdicciones, orden alfabético por [shortName] (CABA primero).
const kArgentinaProvinces = <ArgentinaProvince>[
  ArgentinaProvince(
    id: '02',
    name: 'Ciudad Autónoma de Buenos Aires',
    shortName: 'CABA',
    capital: null,
  ),
  ArgentinaProvince(
    id: '06',
    name: 'Buenos Aires',
    shortName: 'Buenos Aires',
    capital: 'La Plata',
  ),
  ArgentinaProvince(
    id: '10',
    name: 'Catamarca',
    shortName: 'Catamarca',
    capital: 'San Fernando del Valle de Catamarca',
  ),
  ArgentinaProvince(
    id: '22',
    name: 'Chaco',
    shortName: 'Chaco',
    capital: 'Resistencia',
  ),
  ArgentinaProvince(
    id: '26',
    name: 'Chubut',
    shortName: 'Chubut',
    capital: 'Rawson',
  ),
  ArgentinaProvince(
    id: '14',
    name: 'Córdoba',
    shortName: 'Córdoba',
    capital: 'Córdoba',
  ),
  ArgentinaProvince(
    id: '18',
    name: 'Corrientes',
    shortName: 'Corrientes',
    capital: 'Corrientes',
  ),
  ArgentinaProvince(
    id: '30',
    name: 'Entre Ríos',
    shortName: 'Entre Ríos',
    capital: 'Paraná',
  ),
  ArgentinaProvince(
    id: '34',
    name: 'Formosa',
    shortName: 'Formosa',
    capital: 'Formosa',
  ),
  ArgentinaProvince(
    id: '38',
    name: 'Jujuy',
    shortName: 'Jujuy',
    capital: 'San Salvador de Jujuy',
  ),
  ArgentinaProvince(
    id: '42',
    name: 'La Pampa',
    shortName: 'La Pampa',
    capital: 'Santa Rosa',
  ),
  ArgentinaProvince(
    id: '46',
    name: 'La Rioja',
    shortName: 'La Rioja',
    capital: 'La Rioja',
  ),
  ArgentinaProvince(
    id: '50',
    name: 'Mendoza',
    shortName: 'Mendoza',
    capital: 'Mendoza',
  ),
  ArgentinaProvince(
    id: '54',
    name: 'Misiones',
    shortName: 'Misiones',
    capital: 'Posadas',
  ),
  ArgentinaProvince(
    id: '58',
    name: 'Neuquén',
    shortName: 'Neuquén',
    capital: 'Neuquén',
  ),
  ArgentinaProvince(
    id: '62',
    name: 'Río Negro',
    shortName: 'Río Negro',
    capital: 'Viedma',
  ),
  ArgentinaProvince(
    id: '66',
    name: 'Salta',
    shortName: 'Salta',
    capital: 'Salta',
  ),
  ArgentinaProvince(
    id: '70',
    name: 'San Juan',
    shortName: 'San Juan',
    capital: 'San Juan',
  ),
  ArgentinaProvince(
    id: '74',
    name: 'San Luis',
    shortName: 'San Luis',
    capital: 'San Luis',
  ),
  ArgentinaProvince(
    id: '78',
    name: 'Santa Cruz',
    shortName: 'Santa Cruz',
    capital: 'Río Gallegos',
  ),
  ArgentinaProvince(
    id: '82',
    name: 'Santa Fe',
    shortName: 'Santa Fe',
    capital: 'Santa Fe',
  ),
  ArgentinaProvince(
    id: '86',
    name: 'Santiago del Estero',
    shortName: 'Santiago del Estero',
    capital: 'Santiago del Estero',
  ),
  ArgentinaProvince(
    id: '94',
    name: 'Tierra del Fuego, Antártida e Islas del Atlántico Sur',
    shortName: 'Tierra del Fuego',
    capital: 'Ushuaia',
  ),
  ArgentinaProvince(
    id: '90',
    name: 'Tucumán',
    shortName: 'Tucumán',
    capital: 'San Miguel de Tucumán',
  ),
];

ArgentinaProvince? provinceById(String id) {
  for (final p in kArgentinaProvinces) {
    if (p.id == id) return p;
  }
  return null;
}

ArgentinaProvince? provinceByShortOrName(String raw) {
  final q = raw.trim().toLowerCase();
  if (q.isEmpty) return null;
  for (final p in kArgentinaProvinces) {
    if (p.shortName.toLowerCase() == q ||
        p.name.toLowerCase() == q ||
        (q == 'caba' && p.isCaba) ||
        (q.contains('ciudad autónoma') && p.isCaba)) {
      return p;
    }
  }
  return null;
}

/// Localidad elegible (capital, barrio CABA o localidad GeoRef).
class ArgentinaLocality {
  const ArgentinaLocality({
    required this.name,
    required this.province,
    this.id,
    this.latitude,
    this.longitude,
    this.isCapital = false,
  });

  final String? id;
  final String name;
  final ArgentinaProvince province;
  final double? latitude;
  final double? longitude;
  final bool isCapital;

  String get label => '$name, ${province.shortName}';
}
