import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';
import 'package:auto_tm/utils/navigation_utils.dart';

class ViewPostPhotoScreen extends StatelessWidget {
  const ViewPostPhotoScreen({
    super.key,
    required this.imageUrls,
    this.currentIndex = 0,
  });

  final List<String> imageUrls;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageController = PageController(initialPage: currentIndex);
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_arrow_left_outlined,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => NavigationUtils.close(context),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageView.builder(
        // shrinkWrap: true,
        controller: pageController,
        physics: PageScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true, // Allow panning
            scaleEnabled: true, // Allow zooming
            minScale: 1.0,
            maxScale: 5.0,
            child: Center(
              child: Image.network(
                ApiKey.ip + imageUrls[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
