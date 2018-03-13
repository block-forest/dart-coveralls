library dart_coveralls.test.mocks;

import 'dart:io' show ProcessResult;

import 'package:dart_coveralls/dart_coveralls.dart';
import 'package:file/file.dart';
import 'package:mockito/mockito.dart';

@proxy
class FileSystemMock extends Mock implements FileSystem {}

@proxy
class FileMock extends Mock implements File {}

@proxy
class DirectoryMock extends Mock implements Directory {}

@proxy
class ProcessResultMock extends Mock implements ProcessResult {}

@proxy
class ProcessSystemMock extends Mock implements ProcessSystem {}
