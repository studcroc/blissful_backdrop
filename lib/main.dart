import 'dart:developer';
import 'dart:io';
import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:blissful_backdrop/about.dart';
import 'package:blissful_backdrop/check_update.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:window_size/window_size.dart' as window_size;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initilize the analytics
  await Aptabase.init("A-EU-0224880831");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Blissful Backdrop',
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
  String selectedCategory = "Random";
  int selectedCategoryPage = 1;
  List<String> categories = [
    "Favorites",
    "Random",
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
  late PackageInfo packageInfo;
  late SharedPreferences _preferences;
  List<String> favoriteWallpapersList = [];

  static const platform = MethodChannel('blissful_backdrop.native/wallpaper');

  Future<void> callNativeSetDesktopWallpaperMethod(
      String wallpaperFilePath, int fitMode) async {
    try {
      final result = await platform.invokeMethod<bool>('setDesktopWallpaper',
          {"filePath": wallpaperFilePath, "fitMode": fitMode});
      log(result.toString());
    } on PlatformException catch (e) {
      log(e.message.toString());
    }
  }

  @override
  void initState() {
    Aptabase.instance.trackEvent('app_launch');

    super.initState();

    initialize();

    loadWallpapers();

    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        if (selectedCategory.toLowerCase() != "random" &&
            selectedCategory.toLowerCase() != "favorites") {
          selectedCategoryPage += 1;
          setState(() {
            loadingNextPageOfWallpaper = true;
          });
          loadWallpapers();
        }
      }
    });
  }

  initialize() async {
    if (await appUpdateAvailable()) {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => const AppUpdater(),
      );
    }

    PackageInfo pckgInfo = await PackageInfo.fromPlatform();
    var screens = await window_size.getScreenList();
    var prefs = await SharedPreferences.getInstance();
    var favorites = prefs.getStringList("favorites");

    setState(() {
      noOfScreens = screens.length;
      if (noOfScreens == 3) {
        baseEndpoint = "https://www.triplemonitorbackgrounds.com";
      }
      packageInfo = pckgInfo;
      _preferences = prefs;

      favoriteWallpapersList = favorites ?? [];
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
      builder: (context) => AboutApp(
        appVersion: packageInfo.version,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                              backgroundColor:
                                                  Colors.black.withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            onPressed: () async {
                                              await favoriteOrUnfavoriteWallpaper(
                                                  imageUrls[index]);
                                            },
                                            icon: Icon(
                                              favoriteWallpapersList.contains(
                                                      imageUrls[index])
                                                  ? Icons.favorite
                                                  : Icons
                                                      .favorite_outline_outlined,
                                              color: Colors.white,
                                              shadows: favoriteWallpapersList
                                                      .contains(
                                                          imageUrls[index])
                                                  ? [
                                                      const Shadow(
                                                        color: Colors.black,
                                                        offset: Offset(1, 1),
                                                        blurRadius: 8,
                                                      ),
                                                    ]
                                                  : [],
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
    );
  }

  Future<void> favoriteOrUnfavoriteWallpaper(String imageUrl) async {
    if (favoriteWallpapersList.contains(imageUrl)) {
      favoriteWallpapersList.remove(imageUrl);
    } else {
      favoriteWallpapersList.add(imageUrl);
    }
    await _preferences.setStringList("favorites", favoriteWallpapersList);
    setState(() {
      favoriteWallpapersList = favoriteWallpapersList;
    });
  }

  Future<void> updateWallpaper(String imagePath) async {
    setState(() {
      updatingWallpaper = true;
    });
    await callNativeSetDesktopWallpaperMethod(imagePath, 5);
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        updatingWallpaper = false;
      });
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
      String url = "$baseUrl/$category/page/$selectedCategoryPage";
      if (category.toLowerCase() == "random") {
        url = "$baseUrl/$category";
      } else if (category.toLowerCase() == "favorites") {
        return favoriteWallpapersList;
      }
      // Fetch HTML content
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Parse HTML
        final document = html.parse(response.body);

        // Extract image URLs
        final images = document.getElementsByTagName('li a img');
        for (var img in images) {
          String? imagePath =
              img.parent!.attributes['href']!.replaceAll(".php", "");
          if (imagePath.isNotEmpty) {
            imageUrls.add("$baseEndpoint/albums$imagePath");
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
      categoryWidgets.add(
        Padding(
          padding: i == 0
              ? const EdgeInsets.only(right: 6)
              : i == categories.length - 1
                  ? const EdgeInsets.only(left: 6)
                  : const EdgeInsets.symmetric(horizontal: 6),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(0);
                }
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
        ),
      );
    }

    return categoryWidgets;
  }
}
