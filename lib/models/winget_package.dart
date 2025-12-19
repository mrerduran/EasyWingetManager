class WingetPackage {
  final String name;
  final String id;
  final String version;
  final String? available;
  final String? source;
  final bool isInstalled;

  WingetPackage({
    required this.name,
    required this.id,
    required this.version,
    this.available,
    this.source,
    this.isInstalled = false,
  });

  factory WingetPackage.fromJson(Map<String, dynamic> json) => WingetPackage(
        name: json['name'],
        id: json['id'],
        version: json['version'],
        available: json['available'],
        source: json['source'],
        isInstalled: json['isInstalled'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'id': id,
        'version': version,
        'available': available,
        'source': source,
        'isInstalled': isInstalled,
      };
}
