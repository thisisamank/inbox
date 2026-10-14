import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/compose.dart';
import '../utils/mime.dart';

abstract interface class Files {
  Future<List<OutgoingAttachment>> pick();
  Future<void> share({
    required String folder,
    required String filename,
    required String mimetype,
    required Uint8List bytes,
  });
}

class DeviceFiles implements Files {
  const DeviceFiles();

  @override
  Future<List<OutgoingAttachment>> pick() async {
    final picked = await FilePicker.pickFiles();
    return [
      for (final f in picked)
        OutgoingAttachment(
          filename: f.name,
          type: mimeTypeFor(f.name),
          bytes: await f.readAsBytes(),
        ),
    ];
  }

  @override
  Future<void> share({
    required String folder,
    required String filename,
    required String mimetype,
    required Uint8List bytes,
  }) async {
    final dir = Directory(
      '${(await getTemporaryDirectory()).path}/attachments/$folder',
    );
    await dir.create(recursive: true);
    final file = File(
      '${dir.path}/${filename.replaceAll(RegExp(r'[/\\:\x00-\x1f]'), '_')}',
    );
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: mimetype)]),
    );
  }
}
