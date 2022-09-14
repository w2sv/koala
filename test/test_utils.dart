import 'dart:io';

final outputDir = Directory('test/output');

String outputFilePath(String name) => '${outputDir.path}/$name';

String csvPath(String name) => 'test/data/$name';
