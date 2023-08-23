import 'dart:io';
import 'package:anon_uplaod/history_page.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:anon_uplaod/database_helper.dart';

class HomeController extends GetxController {
  final RxString selectedFileName = RxString('');
  final RxString fileLink = RxString('');
  Uint8List? fileBytes;
  final RxBool isUploading = false.obs;
  final RxBool isUploadEnable = false.obs;

  void updateSelectedFileName(String fileName) {
    selectedFileName.value = fileName;
  }

  void updateFileLink(String link) {
    fileLink.value = link;
  }

  Future<bool> _checkNetworkConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi;
  }

  Future<void> uploadFile() async {
    isUploadEnable.value = true;

    bool isConnected = await _checkNetworkConnection();
    if (!isConnected) {
      Get.snackbar(
        "No Network Connection",
        "Please connect to the internet to upload.",
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      isUploading.value = false;
      return;
    }

    if (fileBytes != null) {
      final url = Uri.parse('https://transfer.sh/${selectedFileName.value}');

      final headers = {
        'Content-Type': 'application/octet-stream',
      };

      final res = await http.put(url, headers: headers, body: fileBytes);
      final status = res.statusCode;

      if (status == 200) {
        updateFileLink(res.body);
        await Clipboard.setData(ClipboardData(text: res.body));

        final deleteTokenMatch = res.headers['x-url-delete'];
        print('Delete Token Match: $deleteTokenMatch');
        if (deleteTokenMatch != null) {
          // Store the file link and delete token URL in the database
          await DatabaseHelper.instance.insertFileLink(
              selectedFileName.value, res.body, deleteTokenMatch);
        }
        Get.snackbar(
          "Link Copied to Clipboard",
          "",
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.black,
          backgroundColor: Colors.white,
        );
      } else {
        updateFileLink('');
      }
    } else {
      updateFileLink('');
    }

    isUploading.value = false;
  }
}

class HomePage extends StatelessWidget {
  Future<void> _clearCacheDirectory() async {
    try {
      final appDir = await getTemporaryDirectory();
      appDir.list().forEach((file) async {
        if (file is File) {
          await file.delete();
        }
      });
    } catch (e) {
      print('Error clearing cache directory: $e');
    }
  }

  final HomeController controller = Get.put(HomeController());

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Get.to(HistoryPage());
            },
            icon: const Icon(Icons.history_edu_outlined),
          ),
        ],
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
                padding: EdgeInsets.only(top: 0),
                child: Text(
                  "transfer.sh",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DroidSansMono.ttf',
                    fontSize: 62,
                  ),
                )),
            const SizedBox(
              height: 40,
            ),
            Obx(() {
              if (controller.selectedFileName.value.isNotEmpty) {
                return Text(
                  "File Name: ${controller.selectedFileName.value}\n\nFile Size: ${(controller.fileBytes?.length ?? 0) / 1000000} MB",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                );
              } else {
                return const SizedBox
                    .shrink(); // Hide the widget when no file is selected
              }
            }),
            const SizedBox(
              height: 40,
            ),
            Obx(
              () => Text(
                controller.fileLink.value, // Display the link
                style: TextStyle(
                  fontFamily: 'DroidSansMono.ttf',
                  fontWeight: FontWeight.bold,
                  color: controller.fileLink.value.isNotEmpty
                      ? Colors.green
                      : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(
              height: 90,
            ),
            ElevatedButton(
              onPressed: () async {
                await _clearCacheDirectory();

                controller.fileLink.value = "";
                controller.selectedFileName.value = "";
                controller.fileLink.value = "";
                controller.fileBytes = null;
                controller.isUploadEnable.value = false;
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();

                if (result != null && result.files.isNotEmpty) {
                  // Update fileBytes and selectedFileName
                  File file = File(result.files.first.path!);
                  controller.fileBytes = await file.readAsBytes();
                  controller.updateSelectedFileName(result.files.first.name);
                  debugPrint(result.files.first.name);
                } else {}
              },
              style: ButtonStyle(
                padding: MaterialStateProperty.all(const EdgeInsets.all(20)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: const BorderSide(
                      width: 2.0,
                    ),
                  ),
                ),
              ),
              child: const Text(
                "Select File",
                style: TextStyle(fontSize: 32, fontFamily: 'DroidSansMono'),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Obx(() => ElevatedButton(
                  onPressed: controller.isUploadEnable.value
                      ? null
                      : () {
                          controller.isUploading.value = true;
                          controller.uploadFile();
                        },
                  style: ButtonStyle(
                    padding:
                        MaterialStateProperty.all(const EdgeInsets.all(20)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: const BorderSide(
                          color: Colors.teal,
                          width: 2.0,
                        ),
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                      controller.fileLink.value.isNotEmpty
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  child: const Text(
                    "Upload",
                    style: TextStyle(fontSize: 32, fontFamily: 'DroidSansMono'),
                  ),
                )),
            const SizedBox(
              height: 30,
            ),
            Obx(
              () => Visibility(
                visible: controller.isUploading.value,
                child: const SpinKitDualRing(
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
