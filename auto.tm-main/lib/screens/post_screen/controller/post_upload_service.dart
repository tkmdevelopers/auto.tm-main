import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:get/get.dart';

class PostUploadService extends GetxService {
  static PostUploadService get to => Get.find();

  final _isUploading = false.obs;

  bool get isUploading => _isUploading.value;

  Future<void> uploadPost(Post post) async {
    if (_isUploading.value) return;

    _isUploading.value = true;

    try {
      // simulate file upload
      await Future.delayed(Duration(seconds: 3));
      // send request to server
      // await PostApi.upload(post);

      // Show upload success
  Get.snackbar('post_upload_success_title'.tr, 'post_upload_success_body'.tr);
    } catch (e) {
  Get.snackbar('common_error'.tr, 'common_retry'.tr);
    } finally {
      _isUploading.value = false;
    }
  }
}
