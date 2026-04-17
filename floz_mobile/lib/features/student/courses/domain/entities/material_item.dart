enum MaterialType { file, link, text, unknown }

MaterialType materialTypeFromString(String? raw) {
  switch (raw) {
    case 'file':
      return MaterialType.file;
    case 'link':
      return MaterialType.link;
    case 'text':
      return MaterialType.text;
    default:
      return MaterialType.unknown;
  }
}

class MaterialItem {
  final int id;
  final String title;
  final MaterialType type;
  final String? content;
  final String? fileName;
  final int? fileSize;
  final String? fileUrl;
  final String? url;
  final int sortOrder;

  const MaterialItem({
    required this.id,
    required this.title,
    required this.type,
    this.content,
    this.fileName,
    this.fileSize,
    this.fileUrl,
    this.url,
    required this.sortOrder,
  });
}
