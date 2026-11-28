import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// External apps a homeowner can use to contact a provider (DISC-2).
enum ProviderContactChannel {
  telegram('t.me'),
  messenger('m.me');

  const ProviderContactChannel(this.host);

  /// The only host a saved link for this channel may point to.
  final String host;
}

/// A saved provider contact link that is safe to open externally.
class ProviderContactLink {
  const ProviderContactLink({required this.channel, required this.uri});

  final ProviderContactChannel channel;
  final Uri uri;
}

/// The provider's contact links that can be opened.
///
/// Missing, blank or malformed links are left out, so the profile never
/// offers an action that would fail or open an unexpected site.
List<ProviderContactLink> providerContactLinks(ProviderModel provider) {
  final saved = {
    ProviderContactChannel.telegram: provider.telegramUrl,
    ProviderContactChannel.messenger: provider.messengerUrl,
  };
  return [
    for (final entry in saved.entries)
      if (_contactUri(entry.value, entry.key) case final uri?)
        ProviderContactLink(channel: entry.key, uri: uri),
  ];
}

Uri? _contactUri(String? value, ProviderContactChannel channel) {
  final link = value?.trim() ?? '';
  if (link.isEmpty || !isValidProviderContactLink(link, channel.host)) {
    return null;
  }
  return Uri.tryParse(link);
}

/// Opens [uri] outside the app and reports whether it was handed off.
typedef ExternalLinkLauncher = Future<bool> Function(Uri uri);

/// Opens contact links in Telegram, Messenger or the browser.
///
/// Overridden in tests so no platform channel is needed.
final externalLinkLauncherProvider = Provider<ExternalLinkLauncher>(
  (ref) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  },
);
