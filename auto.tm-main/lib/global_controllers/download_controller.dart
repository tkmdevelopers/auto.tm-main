// download_controller.dart
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

// class DownloadController extends GetxController {
//   var progress = 0.obs;
//   var isDownloading = false.obs;
//   var taskId = ''.obs;

//   final ReceivePort _port = ReceivePort();

//   @override
//   void onInit() {
//     super.onInit();
//     IsolateNameServer.registerPortWithName(
//       _port.sendPort,
//       'downloader_send_port',
//     );
//     _port.listen((dynamic data) {
//       String id = data[0];
//       DownloadTaskStatus status = data[1];
//       int prog = data[2];

//       if (taskId.value == id) {
//         progress.value = prog;
//         isDownloading.value = status == DownloadTaskStatus.running;
//       }
//     });
//     FlutterDownloader.registerCallback(DownloadController.downloadCallback);
//   }

//   @pragma('vm:entry-point')
//   static void downloadCallback(String id, int status, int progress) {
//     final SendPort? send = IsolateNameServer.lookupPortByName(
//       'downloader_send_port',
//     );
//     send?.send([id, status, progress]);
//   }

//   Future<void> startDownload(String url, String fileName) async {
//     final directory = await getExternalStorageDirectory();
//     final saveDir = Directory("${directory!.path}/AutoTM/cars");

//     if (!await saveDir.exists()) {
//       await saveDir.create(recursive: true);
//     }

//     final id = await FlutterDownloader.enqueue(
//       url: url,
//       savedDir: saveDir.path,
//       fileName: fileName,
//       showNotification: true,
//       openFileFromNotification: true,
//       requiresStorageNotLow: false,
//       saveInPublicStorage: true,
//     );

//     taskId.value = id ?? '';
//   }

//   @override
//   void onClose() {
//     IsolateNameServer.removePortNameMapping('downloader_send_port');
//     super.onClose();
//   }
// }


class DownloadController extends GetxController {
  var progress = 0.obs;
  var isDownloading = false.obs;
  var taskId = ''.obs;
  var isInitialized = false.obs;

  final ReceivePort _port = ReceivePort();

  DownloadTaskStatus _mapStatus(int value) {
    switch (value) {
      case 0:
        return DownloadTaskStatus.undefined;
      case 1:
        return DownloadTaskStatus.enqueued;
      case 2:
        return DownloadTaskStatus.running;
      case 3:
        return DownloadTaskStatus.complete;
      case 4:
        return DownloadTaskStatus.failed;
      case 5:
        return DownloadTaskStatus.canceled;
      case 6:
        return DownloadTaskStatus.paused;
      default:
        return DownloadTaskStatus.undefined;
    }
  }

  /// Lazy initialize FlutterDownloader only when needed
  Future<void> _ensureInitialized() async {
    if (isInitialized.value) return;
    
    try {
      await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
      isInitialized.value = true;
      
      IsolateNameServer.registerPortWithName(
        _port.sendPort,
        'downloader_send_port',
      );
      _port.listen((dynamic data) async {
        String id = data[0];
        int statusRaw = data[1];
        int prog = data[2];

        DownloadTaskStatus status = _mapStatus(statusRaw);

        if (taskId.value == id) {
          if (status == DownloadTaskStatus.failed) {
            final task = await FlutterDownloader.loadTasksWithRawQuery(
              query: "SELECT * FROM task WHERE task_id='$id'"
            );
            if (task != null && task.isNotEmpty) {
              final file = File("${task.first.savedDir}/${task.first.filename}");
              if (await file.exists()) {
                status = DownloadTaskStatus.complete;
              }
            }
          }

          progress.value = prog;
          isDownloading.value = status == DownloadTaskStatus.running;
        }
      });
      FlutterDownloader.registerCallback(DownloadController.downloadCallback);
    } catch (e) {
      // FlutterDownloader failed to initialize - download feature will be unavailable
      print('[DownloadController] FlutterDownloader initialization failed: $e');
      isInitialized.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Don't initialize FlutterDownloader on startup - wait until user actually needs it
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  Future<void> startDownload(String url, String fileName) async {
    // Initialize FlutterDownloader only when user actually wants to download
    await _ensureInitialized();
    
    if (!isInitialized.value) {
      throw Exception('Download feature is not available. FlutterDownloader failed to initialize.');
    }

    final directory = await getExternalStorageDirectory();
    final saveDir = Directory("${directory!.path}/AutoTM/cars");

    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    final filePath = "${saveDir.path}/$fileName";
    final existingFile = File(filePath);
    if (await existingFile.exists()) {
      await existingFile.delete();
    }

    final id = await FlutterDownloader.enqueue(
      url: url,
      savedDir: saveDir.path,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
      requiresStorageNotLow: false,
      saveInPublicStorage: true,
    );

    taskId.value = id ?? '';
  }

  @override
  void onClose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.onClose();
  }
}
