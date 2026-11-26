/// Shared validation helper for provider external contact links.
bool isValidProviderContactLink(String value, String host) {
  final link = value.trim();
  final prefix = 'https://$host/';
  return link.isEmpty ||
      (link.length <= 500 &&
          link.startsWith(prefix) &&
          RegExp(r'^[A-Za-z0-9_.+-]+/?$').hasMatch(
            link.substring(prefix.length),
          ));
}
