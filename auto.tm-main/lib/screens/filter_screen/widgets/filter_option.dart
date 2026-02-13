import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FilterOption extends StatelessWidget {
  final String title;
  final RxString value;
  final List<String> options;

  const FilterOption({
    super.key,
    required this.title,
    required this.value,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Text(value.value.isEmpty ? 'Not selected'.tr : value.value),
          ),
          Divider(thickness: 1, color: Colors.black54),
        ],
      ),
      // trailing: Icon(Icons.arrow_forward_ios),
      onTap: () {
        Get.bottomSheet(
          Container(
            height: Get.height * 0.9,
            color: Colors.white,
            child: Column(
              children: [
                // AppBar(elevation:4,title: Text('Select $title'), automaticallyImplyLeading: false),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      return Obx(
                        () => RadioListTile(
                          title: Text(options[index]),
                          value: options[index],
                          groupValue: value.value,
                          onChanged: (newValue) {
                            value.value = newValue.toString();
                            Get.back();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          isScrollControlled: true,
        );
      },
    );
  }
}
