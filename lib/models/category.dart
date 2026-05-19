class CategoryResponse {
  final int id;
  final String categoryName;

  CategoryResponse({required this.id, required this.categoryName});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    // Backend may return either `id` or `categoryId` as the identifier.
    final int parsedId = (json['id'] as num?)?.toInt() ?? (json['categoryId'] as num?)?.toInt() ?? 0;
    return CategoryResponse(
      id: parsedId,
      categoryName: json['categoryName'] as String? ?? 'Unknown',
    );
  }
}
