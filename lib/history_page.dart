import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'database_helper.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'File History',
          style: TextStyle(
            fontFamily: "DriodSansMono.tff",
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getFileLinks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'Nothing to see here..',
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ));
          } else {
            final data = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 10),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final deleteTokenUrl = item['delete_token_url'];

                return Slidable(
                  key: ValueKey(index),
                  startActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    dismissible: DismissiblePane(onDismissed: () {
                      _deleteFile(item['id'], deleteTokenUrl);
                    }),
                    children: [
                      SlidableAction(
                        onPressed: (BuildContext ctx) {
                          //_deleteFileLink(item['id']); // Call delete function
                        },
                        backgroundColor: const Color(0xFFFE4A49),
                        foregroundColor: Colors.white,
                        icon: Icons.delete_forever,
                        label: 'Delete File',
                      ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    dismissible: DismissiblePane(onDismissed: () {
                      _deleteFileLink(item['id']);
                    }),
                    children: [
                      SlidableAction(
                        flex: 2,
                        onPressed: (BuildContext ctx) {
                          //_deleteFileLink(item['id']);
                        },
                        backgroundColor: const Color(0xFF7BC043),
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Remove from List',
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      item['file_name'],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item['link'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _copyLinkToClipboard(item['link']);
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _deleteFileLink(int id) async {
    await DatabaseHelper.instance.deleteFileLink(id);
    // Refresh the UI or handle any other necessary updates
  }

  Future<void> _deleteFile(int id, String deleteTokenUrl) async {
    final deleteUri = Uri.parse(deleteTokenUrl);
    final deleteResponse = await http.delete(deleteUri);
    if (deleteResponse.statusCode == 200) {
      print(deleteResponse.body);
      await DatabaseHelper.instance.deleteFileLink(id);
    } else {
      Get.snackbar("Error", "There was an Error Deleting the File");
    }
  }

  void _copyLinkToClipboard(String link) {
    Clipboard.setData(ClipboardData(text: link));
  }
}
