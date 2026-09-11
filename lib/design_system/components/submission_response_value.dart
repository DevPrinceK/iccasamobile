import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

class SubmissionResponseValue extends StatelessWidget {
  const SubmissionResponseValue({
    required this.label,
    required this.value,
    super.key,
    this.authorizationHeaders = const {},
    this.signedBy,
  });

  final String label;
  final dynamic value;
  final Map<String, String> authorizationHeaders;
  final String? signedBy;

  @override
  Widget build(BuildContext context) {
    final attachment = _SubmissionAttachment.fromValue(value);
    if (attachment == null) {
      return Text(
        formatSubmissionValue(value),
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      );
    }

    final signature =
        label.toLowerCase().contains('signature') ||
        attachment.filename.toLowerCase().startsWith('signature-');
    final image = attachment.isImage || signature;
    if (!image) {
      return Row(
        children: [
          const Icon(Icons.attach_file_rounded),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              attachment.filename,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    final preview = _attachmentImage(
      attachment,
      headers: authorizationHeaders,
      fit: BoxFit.contain,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: signature
              ? 'Open signature image'
              : 'Open ${attachment.filename}',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showImage(context, attachment, signature: signature),
            child: Ink(
              width: signature ? 190 : 230,
              height: signature ? 92 : 140,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: preview,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Tap image to expand',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (signature && signedBy?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            'Signed by ${signedBy!.trim()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showImage(
    BuildContext context,
    _SubmissionAttachment attachment, {
    required bool signature,
  }) => showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      signature ? 'Captured signature' : attachment.filename,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: InteractiveViewer(
                  minScale: 0.7,
                  maxScale: 5,
                  child: Center(
                    child: _attachmentImage(
                      attachment,
                      headers: authorizationHeaders,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            if (signature && signedBy?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Text(
                  'Signed by ${signedBy!.trim()}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _attachmentImage(
  _SubmissionAttachment attachment, {
  required Map<String, String> headers,
  required BoxFit fit,
}) {
  Widget errorBuilder(BuildContext context, Object error, StackTrace? stack) =>
      Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 34,
        ),
      );

  if (attachment.bytes != null) {
    return Image.memory(
      attachment.bytes!,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
  return Image.network(
    attachment.url!,
    headers: headers,
    fit: fit,
    errorBuilder: errorBuilder,
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}

String formatSubmissionValue(dynamic value) {
  if (value == null) return 'Not provided';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is Map) {
    if (value['latitude'] != null) {
      return '${value['latitude']}, ${value['longitude']}';
    }
    return value.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }
  if (value is Iterable) return value.join(', ');
  return value.toString();
}

class _SubmissionAttachment {
  const _SubmissionAttachment({
    required this.filename,
    this.url,
    this.bytes,
    this.contentType,
  });

  final String filename;
  final String? url;
  final Uint8List? bytes;
  final String? contentType;

  bool get isImage {
    if (contentType?.toLowerCase().startsWith('image/') == true) return true;
    final lower = filename.toLowerCase();
    return const ['.png', '.jpg', '.jpeg', '.webp'].any(lower.endsWith);
  }

  static _SubmissionAttachment? fromValue(dynamic raw) {
    dynamic value = raw;
    if (value is String && value.trimLeft().startsWith('{')) {
      try {
        value = jsonDecode(value);
      } catch (_) {
        return null;
      }
    }
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final filename = map['filename']?.toString() ?? '';
    final rawUrl = (map['download_url'] ?? map['url'])?.toString();
    Uint8List? bytes;
    final encoded = map['_upload_bytes']?.toString();
    if (encoded != null && encoded.isNotEmpty) {
      try {
        bytes = base64Decode(encoded);
      } catch (_) {
        bytes = null;
      }
    }
    final url = rawUrl == null || rawUrl.isEmpty
        ? null
        : AppConfig.absoluteUrl(rawUrl);
    if (filename.isEmpty || (bytes == null && url == null)) return null;
    return _SubmissionAttachment(
      filename: filename,
      url: url,
      bytes: bytes,
      contentType: map['content_type']?.toString(),
    );
  }
}
