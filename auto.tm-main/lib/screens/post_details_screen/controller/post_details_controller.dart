import 'package:auto_tm/domain/models/post.dart';
import 'package:auto_tm/domain/repositories/post_repository.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailsController extends GetxController {
  final PostRepository _postRepository;
  PostDetailsController({String? uuid, PostRepository? postRepository})
    : _uuid = uuid,
      _postRepository = postRepository ?? Get.find<PostRepository>();

  final String? _uuid;
  var post = Rxn<Post>();
  var isLoading = true.obs;
  var isError = false.obs;
  var errorMessage = ''.obs;
  var currentPage = 0.obs;

  String? get uuid => _uuid;

  void retry() {
    if (_uuid != null && _uuid.isNotEmpty) {
      isError.value = false;
      errorMessage.value = '';
      fetchProductDetails(_uuid);
    }
  }

  void setCurrentPage(int index) {
    currentPage.value = index;
  }

  @override
  void onReady() {
    super.onReady();
    if (_uuid != null && _uuid.isNotEmpty) {
      fetchProductDetails(_uuid);
    }
  }

  Future<void> fetchProductDetails(String uuid) async {
    isLoading.value = true;
    isError.value = false;
    errorMessage.value = '';
    try {
      final result = await _postRepository.getPost(uuid);

      if (result != null) {
        post.value = result;
      } else {
        isError.value = true;
        errorMessage.value = 'Post not found'.tr;
        post.value = null;
      }
    } catch (e) {
      isError.value = true;
      errorMessage.value = 'Unable to load post'.tr;
      post.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void makePhoneCall(String phoneNumber) async {
    final Uri callUri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {}
  }
}
