import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BlogItemShimmer extends StatelessWidget {
  const BlogItemShimmer({super.key});


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 270,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8,), //!4/8
          // padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            // boxShadow: [!isDark ? BoxShadow(color: theme.shadowColor, blurRadius: 5) : BoxShadow()], //!active
            boxShadow: [BoxShadow(color: theme.shadowColor, blurRadius: 5)], //!active
          ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Shimmer.fromColors(
          baseColor: theme.colorScheme.primaryContainer, // Light grey
          highlightColor: Colors.grey[600]!, // Lighter grey for the highlight
          child: Container(
            height: 270,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: theme.shadowColor, blurRadius: 5)], //!active
            ),
            // margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                // Shimmer effect for Image
                Expanded(
                  flex: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      // height: 140, // Match PostItem's image height
                      // width: double.infinity,
                      // decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.transparent),
                      color: Colors.white, // Color that will be shimmered
                    ),
                  ),
                ),
                SizedBox(width: 16,),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                // width: double.infinity,
                                width: MediaQuery.of(context).size.width * 0.2,
                                height: 12.0,
                                color: Colors.white,
                                // margin: const EdgeInsets.only(bottom: 4.0),
                              ),
                            ),
                          ],
                        ),
                        // SizedBox(height: 8,),
                        Spacer(),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: 22.0,
                            color: Colors.white,
                            // margin: const EdgeInsets.only(bottom: 4.0),
                          ),
                        ),
                        // SizedBox(height: 8,),
                        Spacer(),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: 14.0,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4,),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: 14.0,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4,),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: 14.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}