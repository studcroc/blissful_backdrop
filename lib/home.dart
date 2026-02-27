import 'dart:developer';
import 'dart:io';
import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:blissful_backdrop/wallpaper_platform/display_info.dart';
import 'package:blissful_backdrop/wallpaper_platform/wallpaper_platform.dart';
import 'package:blissful_backdrop/wallpaper_platform/wallpaper_platform_factory.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
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

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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

  /// Vertical offset in pixels for spanned wallpaper (macOS). Positive = content down.
  int leftOffsetMacOS = 0;
  int rightOffsetMacOS = 0;

  static const _offsetMin = -300;
  static const _offsetMax = 300;

  late final WallpaperPlatform _wallpaperPlatform =
      createWallpaperPlatform();

  @override
  void initState() {
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
      leftOffsetMacOS = prefs.getInt('macos_left_offset') ?? 0;
      rightOffsetMacOS = prefs.getInt('macos_right_offset') ?? 0;
    });

    // Aptabase.instance.trackEvent('app_launch', {'screens': noOfScreens});
  }

  Future<void> loadWallpapers() async {
    List<String> urls =
        await extractImageUrls(baseEndpoint, selectedCategory.toLowerCase());

    if (mounted) {
      setState(() {
        imageUrls.addAll(urls);
        fetchingImageUrls = false;
        loadingNextPageOfWallpaper = false;
      });
    }
  }

  Future<void> favoriteOrUnfavoriteWallpaper(String imageUrl) async {
    if (favoriteWallpapersList.contains(imageUrl)) {
      favoriteWallpapersList.remove(imageUrl);
    } else {
      favoriteWallpapersList.add(imageUrl);
      // Aptabase.instance.trackEvent('favorite_wallpaper',
      //     {'category': selectedCategory, 'wallpaper_url': imageUrl});
    }
    await _preferences.setStringList("favorites", favoriteWallpapersList);
    setState(() {
      favoriteWallpapersList = favoriteWallpapersList;
    });
  }

  Future<void> updateWallpaper(String imagePath) async {
    try {
      List<DisplayInfo> displays;
      try {
        displays = await _wallpaperPlatform.getDisplays();
      } on UnimplementedError catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'macOS support coming soon')),
          );
        }
        setState(() => updatingWallpaper = false);
        return;
      }
      if (Platform.isMacOS && displays.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Spanned wallpaper requires at least 2 displays')),
          );
        }
        setState(() => updatingWallpaper = false);
        return;
      }
      final verticalOffsets = Platform.isMacOS && displays.length >= 2
          ? [leftOffsetMacOS, rightOffsetMacOS]
          : List<int>.filled(displays.length, 0);
      await _wallpaperPlatform.generateAndApplySpannedWallpaper(
        sourceImagePath: imagePath,
        displays: displays,
        verticalOffsets: verticalOffsets,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper applied to both desktops')),
        );
      }
    } on PlatformException catch (e, st) {
      log('updateWallpaper platform error', error: e, stackTrace: st);
      if (mounted) {
        final msg = e.message ?? e.code;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wallpaper failed: $msg')),
        );
      }
    } catch (e, st) {
      log('updateWallpaper failed', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set wallpaper: $e')),
        );
      }
    } finally {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => updatingWallpaper = false);
        });
      }
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

  Future<List<String>> extractImageUrls(String baseUrl, String category,
      {bool surpriseUser = false}) async {
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
          if (surpriseUser && imageUrls.isNotEmpty) {
            return imageUrls;
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> setRandomWallpaper() async {
    setState(() {
      updatingWallpaper = true;
    });
    List<String> urls =
        await extractImageUrls(baseEndpoint, 'random', surpriseUser: true);

    String imagePath = await downloadImage(urls.first);
    await updateWallpaper(imagePath);

    await _preferences.setString("active_wallpaper", urls.first);
    // Aptabase.instance.trackEvent('update_wallpaper',
    //     {'category': 'surprise_me', 'wallpaper_url': urls.first});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setRandomWallpaper();
        },
        tooltip: 'Surprise Me',
        child: const Icon(fluent_ui.FluentIcons.giftbox_open),
      ),
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
                if (Platform.isMacOS && noOfScreens >= 2) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Left offset:', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: fluent_ui.Slider(
                          value: leftOffsetMacOS.toDouble(),
                          min: _offsetMin.toDouble(),
                          max: _offsetMax.toDouble(),
                          onChanged: (v) {
                            setState(() => leftOffsetMacOS = v.round());
                            _preferences.setInt('macos_left_offset', v.round());
                          },
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text('$leftOffsetMacOS', style: const TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 16),
                      const Text('Right offset:', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: fluent_ui.Slider(
                          value: rightOffsetMacOS.toDouble(),
                          min: _offsetMin.toDouble(),
                          max: _offsetMax.toDouble(),
                          onChanged: (v) {
                            setState(() => rightOffsetMacOS = v.round());
                            _preferences.setInt('macos_right_offset', v.round());
                          },
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text('$rightOffsetMacOS', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
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
                                                  ? fluent_ui
                                                      .FluentIcons.heart_fill
                                                  : fluent_ui.FluentIcons.heart,
                                              color: Colors.white,
                                              size: 18,
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
                                      await _preferences.setString(
                                          "active_wallpaper", imageUrl);
                                      // Aptabase.instance.trackEvent(
                                      //     'update_wallpaper', {
                                      //   'category': selectedCategory,
                                      //   'wallpaper_url': imageUrl
                                      // });
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
}
