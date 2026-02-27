/// Immutable info for a single display (monitor).
class DisplayInfo {
  final String id;
  final int width;
  final int height;
  final int x;
  final int y;

  const DisplayInfo({
    required this.id,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
  });

  @override
  String toString() =>
      'DisplayInfo(id: $id, ${width}x$height, x: $x, y: $y)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'width': width,
        'height': height,
        'x': x,
        'y': y,
      };

  factory DisplayInfo.fromJson(Map<String, dynamic> json) {
    return DisplayInfo(
      id: json['id'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
    );
  }
}
