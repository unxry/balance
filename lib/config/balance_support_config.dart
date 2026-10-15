abstract final class BalanceSupportConfig {
  static const destination = String.fromEnvironment('BALANCE_SUPPORT_URL');

  static Uri? get uri {
    final value = destination.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.scheme == 'mailto' && uri.path.isNotEmpty) return uri;
    if (uri.scheme == 'https' && uri.host.isNotEmpty) return uri;
    return null;
  }
}
