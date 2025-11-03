import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';

/// Sealed-style state representation for Post Details screen.
abstract class PostDetailsState {
  const PostDetailsState();
}

class PostDetailsLoading extends PostDetailsState {
  const PostDetailsLoading();
}

class PostDetailsReady extends PostDetailsState {
  final Post post;
  const PostDetailsReady(this.post);
}

class PostDetailsError extends PostDetailsState {
  final String message;
  const PostDetailsError(this.message);
}
