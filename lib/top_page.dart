import 'package:flutter/material.dart';
import 'hint_page.dart';
import 'home_page.dart';
import 'edit_page.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import 'info.dart';


class TopPage extends StatefulWidget {
  const TopPage({super.key});

  @override
  TopPageState createState() => TopPageState();
}

class TopPageState extends State<TopPage> {
  List<File> _csvFiles = [];
  bool _loading = true;

  Future<void> _refreshCsvList() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final d = Directory(dir.path);
      final entries = await d.list().toList();
      final files = entries.whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.csv'))
          .toList()
        ..sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
      if (!mounted) return;
      setState(() {
        _csvFiles = files;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _csvFiles = [];
        _loading = false;
      });
    }
  }

  Future<void> _exportFile(File file) async {
    try {
      final tmp = await getTemporaryDirectory();
      final copyPath = p.join(tmp.path, p.basename(file.path));
      await file.copy(copyPath);
      await Share.shareXFiles([
        XFile(copyPath, mimeType: 'text/csv', name: p.basename(file.path)),
      ], text: 'Taiko score CSV');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _confirmDelete(File file) async {
    final name = p.basename(file.path);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this file?'),
        content: Text(name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await file.delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted: $name')),
        );
        _refreshCsvList();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshCsvList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("せっとんどん"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InfoPage(),
                ),
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HintPage(),
                ),
              );
            },
            icon: const Icon(Icons.question_mark_sharp),
          ),
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const Image(image: AssetImage("assets/images/taiko-g.png")),
              ),
            ),
            const SizedBox(height: 12),
            // CSV tiles list (expands to fill the remaining space)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshCsvList,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_csvFiles.isEmpty)
                    ? const Center(child: Text('No CSV files saved yet.'))
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _csvFiles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final file = _csvFiles[index];
                    final name = p.basename(file.path);
                    return ListTile(
                      title: Text(name),
                      leading: const Icon(Icons.description_outlined),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.ios_share),
                            tooltip: 'Export',
                            onPressed: () => _exportFile(file),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete',
                            onPressed: () => _confirmDelete(file),
                          ),
                        ],
                      ),
                      onTap: () async {
                        final content = await file.readAsString();
                        if (!mounted) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CsvEditPage(file: file, initialText: content),
                          ),
                        );
                        // Reload list in case file was renamed/removed/added externally
                        _refreshCsvList();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),


      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
        },
        child: const Icon(Icons.add),
    ),
    );
  }
}