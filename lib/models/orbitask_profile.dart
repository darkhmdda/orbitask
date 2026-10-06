class OrbitaskProfile {
  const OrbitaskProfile({
    required this.id,
    this.displayName,
    this.username,
    this.avatarPath,
    this.avatarUrl,
  });

  final String id;
  final String? displayName;
  final String? username;
  final String? avatarPath;
  final String? avatarUrl;

  String get initials {
    final source = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : (username?.trim().isNotEmpty ?? false)
            ? username!.trim()
            : '';
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
