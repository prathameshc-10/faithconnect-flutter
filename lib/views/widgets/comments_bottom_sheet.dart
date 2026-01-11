import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/comment_model.dart';
import '../../providers/posts_provider.dart';
import '../../providers/app_state_provider.dart';
import 'comment_item.dart';

/// CommentsBottomSheet Widget
/// Modal bottom sheet displaying comments for a post
/// - Scrollable list of comments
/// - Fixed input field at bottom with send icon
class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final String postTitle;
  final bool isReel;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    this.postTitle = 'Comments',
    this.isReel = false,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Fetch comments when bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postsProvider = context.read<PostsProvider>();
      postsProvider.fetchComments(widget.postId, isReel: widget.isReel);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    final postsProvider = context.read<PostsProvider>();
    final appState = context.read<AppStateProvider>();

    if (appState.userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to comment'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await postsProvider.addComment(
        postId: widget.postId,
        userId: appState.userId!,
        text: text,
        isReel: widget.isReel,
      );
      _commentController.clear();
      _focusNode.unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add comment. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Build the input field at the bottom
  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text input field
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Type comment',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                enabled: !_isSubmitting,
              ),
            ),
            const SizedBox(width: 8),
            // Send icon button
            Material(
              color: _isSubmitting ? Colors.grey : Colors.blue,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _isSubmitting ? null : _handleSend,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  widget.postTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  iconSize: 24,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable comments list
          Expanded(
            child: Consumer<PostsProvider>(
              builder: (context, postsProvider, child) {
                final comments = postsProvider.getComments(widget.postId);
                final isLoading = postsProvider.isLoadingComments(widget.postId);

                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    // Only show if author is loaded
                    if (comment.author == null) {
                      return const SizedBox.shrink();
                    }
                    return CommentItem(comment: comment);
                  },
                );
              },
            ),
          ),
          // Fixed input field at bottom
          _buildInputField(),
        ],
      ),
    );
  }
}

/// Function to show comments bottom sheet
/// This can be called from anywhere to display the comments modal
void showCommentsBottomSheet(
  BuildContext context, {
  required String postId,
  String postTitle = 'Comments',
  bool isReel = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CommentsBottomSheet(
      postId: postId,
      postTitle: postTitle,
      isReel: isReel,
    ),
  );
}