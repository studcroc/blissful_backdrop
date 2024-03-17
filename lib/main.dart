import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as html;
import 'package:shimmer/shimmer.dart';
import 'package:window_size/window_size.dart' as window_size;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<String> imageUrls = [];
  bool fetchingImageUrls = false;
  int noOfScreens = 1;
  String selectedCategory = "Animals";
  List<String> categories = [
    "Animals",
    "Abstract",
    "Astronomy",
    "Computers",
    "Crafted-Nature",
    "Gaming",
    "Industrial",
    "Macabre",
    "Microscopic",
    "Nature",
    "Celebrities",
    "Popular-Culture",
    "Science-Fiction"
  ];

  @override
  void initState() {
    super.initState();

    loadWallpapers();
  }

  loadWallpapers() async {
    var screens = await window_size.getScreenList();
    setState(() {
      fetchingImageUrls = true;
      noOfScreens = screens.length;
    });
    String baseUrl = "https://www.dualmonitorbackgrounds.com";
    if (noOfScreens == 3) {
      baseUrl = "https://www.triplemonitorbackgrounds.com";
    }
    List<String> response =
        await extractImageUrls(baseUrl, selectedCategory.toLowerCase());
    setState(() {
      imageUrls = response;
      fetchingImageUrls = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blissfull Backdrop',
      home: Scaffold(
        backgroundColor: const Color.fromARGB(240, 255, 255, 255),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: getCategoryWidgets(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    "Displaying for ${noOfScreens == 1 ? 'single screen' : noOfScreens == 2 ? 'dual monitors' : 'triple monitors'}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: fetchingImageUrls
                    ? GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 4.24,
                        mainAxisSpacing: 8.0,
                        crossAxisSpacing: 8.0,
                        children: List.generate(
                          12,
                          (index) => Shimmer.fromColors(
                            baseColor: Colors.grey,
                            highlightColor: Colors.blueGrey,
                            child: AspectRatio(
                              aspectRatio: 4.24,
                              child: Container(
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                        ),
                      )
                    : imageUrls.isNotEmpty
                        ? GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                              childAspectRatio: 4.24,
                            ),
                            itemCount: imageUrls.length,
                            itemBuilder: (BuildContext context, int index) {
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrls[index],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                      baseColor: Colors.grey,
                                      highlightColor: Colors.blueGrey,
                                      child: AspectRatio(
                                        aspectRatio: 4.24,
                                        child: Container(
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  onTap: () async {
                                    String imageUrl = imageUrls[index];
                                    String imagePath =
                                        await downloadImage(imageUrl);
                                    updateWallpaper(imagePath);
                                  },
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Text('No wallpapers to show :('),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void updateWallpaper(String imagePath) async {
    final scriptDir = path.dirname(Platform.script.toFilePath());
    String relativePathToExecutable =
        path.join(scriptDir, 'bin', 'ConsoleApplication1.exe');
    if (kReleaseMode) {
      relativePathToExecutable = path.join(scriptDir, 'data', 'flutter_assets',
          'bin', 'ConsoleApplication1.exe');
    }
    ProcessResult result =
        await Process.run(relativePathToExecutable, [imagePath, "5"]);
    if (result.exitCode == 0) {
      log('Command executed successfully');
      log('STDOUT:');
      log(result.stdout);
    } else {
      log('Command failed with exit code ${result.exitCode}');
      log('STDERR:');
      log(result.stderr);
    }
  }

  Future<String> downloadImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    final bytes = response.bodyBytes;

    final appDir = await getTemporaryDirectory();
    final filePath = '${appDir.path}/image.jpg';

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  Future<List<String>> extractImageUrls(String baseUrl, String category) async {
    List<String> imageUrls = [];

    try {
      // Fetch HTML content
      final response = await http.get(Uri.parse("$baseUrl/$category"));
      if (response.statusCode == 200) {
        // Parse HTML
        final document = html.parse(response.body);

        // Extract image URLs
        final images = document.getElementsByTagName('img');
        for (var img in images) {
          String? src = img.attributes['src'];
          if (src != null && src.isNotEmpty && src.contains("_thumb")) {
            src = src.replaceFirst("cache", "albums");
            src = src.replaceFirst(RegExp(r"_\d+_cw\d+_ch\d+_thumb"), "");
            imageUrls.add("$baseUrl$src");
          }
        }
      } else {
        log('Failed to load HTML: ${response.statusCode}');
      }
    } catch (e) {
      log('Error parsing HTML: $e');
    }

    imageUrls.shuffle();

    return imageUrls;
  }

  List<Widget> getCategoryWidgets() {
    List<Widget> categoryWidgets = [];

    for (var i = 0; i < categories.length; i++) {
      String category = categories[i];
      categoryWidgets.add(Padding(
        padding: i == 0
            ? const EdgeInsets.only(right: 6)
            : i == categories.length - 1
                ? const EdgeInsets.only(left: 6)
                : const EdgeInsets.symmetric(horizontal: 6),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
                fetchingImageUrls = true;
              });
              loadWallpapers();
            },
            child: Text(
              category,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    category.toLowerCase() == selectedCategory.toLowerCase()
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
        ),
      ));
    }

    return categoryWidgets;
  }
}
