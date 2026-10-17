enum HealthPermissionStatus { granted, partial, denied, unavailable }

class HealthPermissionResult {
  final HealthPermissionStatus status;
  final List<String> grantedPermissions;
  final String? message;

  const HealthPermissionResult({
    required this.status,
    this.grantedPermissions = const [],
    this.message,
  });

  bool get isGranted => status == HealthPermissionStatus.granted;
  bool get isPartial => status == HealthPermissionStatus.partial;
  bool get isDenied => status == HealthPermissionStatus.denied;
  bool get isUnavailable => status == HealthPermissionStatus.unavailable;
  bool get hasAccess => isGranted || isPartial;

  factory HealthPermissionResult.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const HealthPermissionResult(
        status: HealthPermissionStatus.denied,
        message: 'No response received',
      );
    }

    final rawStatus = map['status']?.toString().toLowerCase();
    final HealthPermissionStatus status;
    switch (rawStatus) {
      case 'granted':
      case 'completed':
      case 'not_possible':
        status = HealthPermissionStatus.granted;
        break;
      case 'partial':
        status = HealthPermissionStatus.partial;
        break;
      case 'unavailable':
      case 'not_available':
        status = HealthPermissionStatus.unavailable;
        break;
      case 'denied':
      case 'cancelled':
      default:
        status = HealthPermissionStatus.denied;
        break;
    }

    final rawGranted = map['grantedPermissions'];
    final List<String> grantedList = rawGranted is List
        ? rawGranted.map((e) => e.toString()).toList()
        : const [];

    return HealthPermissionResult(
      status: status,
      grantedPermissions: grantedList,
      message: map['message']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthPermissionResult &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          message == other.message &&
          _listEquals(grantedPermissions, other.grantedPermissions);

  @override
  int get hashCode =>
      Object.hash(status, message, Object.hashAll(grantedPermissions));

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
