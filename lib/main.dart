import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as html;
import 'package:shimmer/shimmer.dart';
import 'package:window_size/window_size.dart' as window_size;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<String> imageUrls = [];
  bool fetchingImageUrls = true;
  bool updatingWallpaper = false;
  bool loadingNextPageOfWallpaper = false;
  int noOfScreens = 1;
  String selectedCategory = "Animals";
  int selectedCategoryPage = 1;
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
  final ScrollController _scrollController = ScrollController();
  String baseEndpoint = "https://www.dualmonitorbackgrounds.com";
  double currentScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();

    initialize();

    loadWallpapers();

    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        selectedCategoryPage += 1;
        setState(() {
          loadingNextPageOfWallpaper = true;
        });
        loadWallpapers();
      }
    });
  }

  initialize() async {
    var screens = await window_size.getScreenList();
    setState(() {
      noOfScreens = screens.length;
      if (noOfScreens == 3) {
        baseEndpoint = "https://www.triplemonitorbackgrounds.com";
      }
    });
  }

  Future<void> loadWallpapers() async {
    List<String> urls =
        await extractImageUrls(baseEndpoint, selectedCategory.toLowerCase());

    setState(() {
      imageUrls.addAll(urls);
      fetchingImageUrls = false;
      loadingNextPageOfWallpaper = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Disclaimer & Terms'),
          content: Text(
            "This application retrieves wallpapers from various websites for display purposes only. We do not claim ownership or rights to any of the images displayed within the application. The wallpapers are sourced from publicly available websites (https://www.dualmonitorbackgrounds.com, https://www.triplemonitorbackgrounds.com) and are displayed under the principles of fair use. We make every effort to ensure that the wallpapers displayed are appropriate and do not infringe upon any copyrights or trademarks. However, if you believe that any content displayed within the application violates your intellectual property rights, please contact us immediately so that we can take appropriate action. Please note that the availability and quality of wallpapers may vary, as they are sourced from external websites. We do not endorse or guarantee the accuracy, reliability, or legality of any content provided by third-party websites. By using this application, you acknowledge and agree that we shall not be held responsible for any issues arising from the use of the wallpapers displayed within the application. Thank you for using Blissful Backdrop responsibly.",
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blissfull Backdrop',
      home: Scaffold(
        floatingActionButton: SizedBox(
          height: 48,
          width: 48,
          child: FloatingActionButton(
            onPressed: () {
              _showDialog(context);
            },
            child: const Icon(Icons.info),
          ),
        ),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
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
                                controller: _scrollController,
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
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          CachedNetworkImage(
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
                                          Positioned(
                                            bottom: 0,
                                            child: Text(
                                              "${imageUrls[index].split('/').last.split('.').first[0].toUpperCase()}${imageUrls[index].split('/').last.split('.').first.substring(1)}",
                                              style: TextStyle(
                                                color: Colors.white,
                                                backgroundColor: Colors.black
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      onTap: () async {
                                        setState(() {
                                          updatingWallpaper = true;
                                        });
                                        String imageUrl = imageUrls[index];
                                        String imagePath =
                                            await downloadImage(imageUrl);
                                        await updateWallpaper(imagePath);
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
            if (updatingWallpaper)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white.withOpacity(0.5),
                  child: Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: const Color.fromARGB(255, 29, 156, 230),
                      size: 224,
                    ),
                  ),
                ),
              ),
            if (loadingNextPageOfWallpaper)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white.withOpacity(0.5),
                  child: const LinearProgressIndicator(minHeight: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> updateWallpaper(String imagePath) async {
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
    setState(() {
      updatingWallpaper = false;
    });
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
      final response = await http
          .get(Uri.parse("$baseUrl/$category/page/$selectedCategoryPage"));
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

    // imageUrls.shuffle();

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
              _scrollController.jumpTo(0);
              setState(() {
                selectedCategory = category;
                selectedCategoryPage = 1;
                fetchingImageUrls = true;
                imageUrls = [];
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
