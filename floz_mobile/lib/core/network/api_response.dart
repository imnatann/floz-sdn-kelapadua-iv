class ApiResponse<T> {
  final T data;
  final ApiMeta? meta;

  const ApiResponse({required this.data, this.meta});

  static ApiResponse<T> single<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser,
  ) {
    final raw = json['data'];
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Expected single object under "data"');
    }
    return ApiResponse<T>(data: parser(raw));
  }

  static ApiResponse<List<T>> list<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser,
  ) {
    final raw = json['data'];
    if (raw is! List) {
      throw const FormatException('Expected list under "data"');
    }
    final parsed = raw
        .whereType<Map<String, dynamic>>()
        .map(parser)
        .toList(growable: false);
    final metaJson = json['meta'];
    return ApiResponse<List<T>>(
      data: parsed,
      meta: metaJson is Map<String, dynamic> ? ApiMeta.fromJson(metaJson) : null,
    );
  }
}

class ApiMeta {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const ApiMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory ApiMeta.fromJson(Map<String, dynamic> json) => ApiMeta(
        currentPage: json['current_page'] as int? ?? 1,
        perPage: json['per_page'] as int? ?? 20,
        total: json['total'] as int? ?? 0,
        lastPage: json['last_page'] as int? ?? 1,
      );
}
