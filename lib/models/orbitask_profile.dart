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
}
