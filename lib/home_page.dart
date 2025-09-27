import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'home_model.dart';
import 'utils/notes.dart';

class HomePage extends StatelessWidget {
  final items = notes;

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final title = 'Beat Input';

    final mq = MediaQuery.of(context);
    final size = mq.size;
    final isPortrait = mq.orientation == Orientation.portrait;
    final isSmallWidth = size.width < 380;
    final viewInsets = mq.viewInsets.bottom;
    // iPad / tablet 判定（Flutter標準の shortestSide>=600 慣習）
    final bool isTablet = mq.size.shortestSide >= 600;

    // crossAxis と gridHeight の方針：
    //  - iPhone: 横=5固定・縦=6行固定（余白が出ない計算を後段の LayoutBuilder で実施）
    //  - iPad: 既存ロジック（縦=6 / 横=8）+ 高さは画面比率ベース
    late final int crossAxis;
    late final double adaptiveGridHeightForTablet;

    if (isTablet) {
      crossAxis = isPortrait ? 6 : 8;
      adaptiveGridHeightForTablet = (((isPortrait ? size.height * 0.30 : size.height * 0.42) - viewInsets).clamp(180.0, 320.0));
    } else {
      crossAxis = 5; // iPhoneは常に5列
      adaptiveGridHeightForTablet = 0; // 未使用
    }
    // Adaptive sizes
    final double previewFontSize = isSmallWidth ? 18 : 20;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      resizeToAvoidBottomInset: true,
      body: ChangeNotifierProvider<HomeModel>(
        create: (_) => HomeModel(),
        child: Consumer<HomeModel>(
          builder: (_, model, __) {
            model.setPreviewFontSize(previewFontSize);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Title (flex: 2)
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'title',
                            hintText: 'title du morceau',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: model.setTitle,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Part dropdown (flex: 1)
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<int>(
                          value: model.partIndex,
                          items: List.generate(model.parts.length, (i) {
                            final disp = switch (i) {
                              0 => '〆',
                              1 => '大',
                              2 => '中Ａ',
                              3 => '中Ｂ',
                              _ => '中Ｃ',
                            };
                            return DropdownMenuItem<int>(
                              value: i,
                              child: Text(disp),
                            );
                          }),
                          onChanged: (i) {
                            if (i != null) model.setPartIndex(i);
                          },
                          decoration: const InputDecoration(
                            labelText: 'part',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2) Scrollable multi-line preview (middle, expands)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Scrollbar(
                        controller: model.previewController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: model.previewController,
                          // ★追加：Scrollbar と共有
                          primary: false,
                          padding: const EdgeInsets.all(12.0),
                          child: SelectableText.rich(
                            TextSpan(children: model.buildPreviewSpans()),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3) Controls row (above keyboard)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    children: [
                      // カーソル直前削除（統一）
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: model.backspaceAtCursor,
                          icon: const Icon(Icons.backspace),
                          label: const Text('back'),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // エクスポート
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showExportSheet(context, model),
                          icon: const Icon(Icons.save),
                          label: const Text('save'),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 改行（カーソル位置に挿入）
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: model.insertNewline,
                          icon: const Icon(Icons.keyboard_return),
                          label: const Text('newline'),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4) Items Grid as a fixed-height bottom keyboard
                SafeArea(
                  top: false,
                  child: isTablet
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: adaptiveGridHeightForTablet,
                          child: GridView.count(
                            physics: const ClampingScrollPhysics(),
                            shrinkWrap: true,
                            crossAxisCount: crossAxis,
                            childAspectRatio: isSmallWidth ? 2.2 : 2.6,
                            padding: const EdgeInsets.all(8),
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            children: List.generate(items.length, (index) {
                              final label = items[index];
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                                ),
                                onPressed: label.isEmpty ? null : () => model.appendText(label),
                                child: Text(
                                  label.isEmpty ? ' ' : label,
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                              );
                            }),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // iPhone用：5列×6行がぴったり収まる高さを計算し、余白を出さない
                            const double paddingAll = 8.0;
                            const double mainAxisSpacing = 8.0;
                            const double crossAxisSpacing = 8.0;
                            final double childAspect = isSmallWidth ? 2.2 : 2.6; // width/height
                            final double totalHorizontal = paddingAll * 2 + crossAxisSpacing * (crossAxis - 1);
                            final double cellWidth = (constraints.maxWidth - totalHorizontal) / crossAxis;
                            final double cellHeight = cellWidth / childAspect;
                            const int rows = 6;
                            final double exactHeight = paddingAll * 2 + mainAxisSpacing * (rows - 1) + cellHeight * rows;

                            return SizedBox(
                              height: exactHeight,
                              child: GridView.count(
                                physics: const NeverScrollableScrollPhysics(), // 6行固定でスクロール不要
                                shrinkWrap: true,
                                crossAxisCount: crossAxis, // 5 列
                                childAspectRatio: childAspect,
                                padding: const EdgeInsets.all(paddingAll),
                                mainAxisSpacing: mainAxisSpacing,
                                crossAxisSpacing: crossAxisSpacing,
                                children: List.generate(items.length, (index) {
                                  final label = items[index];
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                                    ),
                                    onPressed: label.isEmpty ? null : () => model.appendText(label),
                                    child: Text(
                                      label.isEmpty ? ' ' : label,
                                      style: const TextStyle(fontSize: 16.0),
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  Future<String> _writeCsvToAppDocs(String filename, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, encoding: utf8);
    return file.path;
  }

  void _showExportSheet(BuildContext context, HomeModel model) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text(
              'Save?',
            ),
            onTap: () async {
              final csv = model.buildCsv();
              final name = model.exportFileName();
              final path = await _writeCsvToAppDocs(name, csv);
              if (context.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Saved!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 20),
                        ),
                    backgroundColor: Colors.white),
                );
              }
            },
          ),
        );
      },
    );
  }
}
