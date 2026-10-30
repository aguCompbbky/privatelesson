import 'package:flutter/services.dart';
import 'package:privatelesson/features/lesson_listings/data/datasources/external_contact_data_source.dart';

/// Adapts injected URI launching and Flutter clipboard access to the source.
final class PlatformExternalContactDataSource
    implements ExternalContactDataSource {
  /// Uses the platform clipboard by default; URI launching must be supplied.
  const PlatformExternalContactDataSource({
    Future<bool> Function(Uri uri)? uriLauncher,
    Future<void> Function(String text)? clipboardWriter,
  }) : _uriLauncher = uriLauncher,
       _clipboardWriter = clipboardWriter;

  final Future<bool> Function(Uri uri)? _uriLauncher;
  final Future<void> Function(String text)? _clipboardWriter;

  /// Reports failure when no actual URI launcher has been connected.
  @override
  Future<bool> launchUri(Uri uri) async {
    final launcher = _uriLauncher;
    if (launcher == null) {
      return false;
    }
    return launcher(uri);
  }

  /// Delegates to the injected writer or Flutter's platform clipboard.
  @override
  Future<void> copyToClipboard(String text) async {
    final writer = _clipboardWriter;
    if (writer != null) {
      return writer(text);
    }
    return Clipboard.setData(ClipboardData(text: text));
  }
}
