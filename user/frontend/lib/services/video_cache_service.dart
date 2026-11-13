import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class VideoCacheService {
  const VideoCacheService();

  Future<File?> getCachedVideo(String name, String url) async {
    try {
      final directory = await getApplicationSupportDirectory();
      final videosDirectory = Directory('${directory.path}/videos');
      await videosDirectory.create(recursive: true);

      final file = File('${videosDirectory.path}/$name.mp4');
      if (await file.exists() && await file.length() > 0) {
        return file;
      }

      final temporaryFile = File('${file.path}.download');
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }

      final client = http.Client();
      try {
        final response = await client.send(http.Request('GET', Uri.parse(url)));
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'Video download failed with HTTP ${response.statusCode}',
            uri: Uri.parse(url),
          );
        }

        final output = temporaryFile.openWrite();
        await response.stream.pipe(output);
        await temporaryFile.rename(file.path);
      } finally {
        client.close();
      }

      return file;
    } catch (error) {
      stderr.writeln('Video cache error for $name: $error');
      return null;
    }
  }
}
