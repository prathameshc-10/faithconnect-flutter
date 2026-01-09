import 'package:flutter/material.dart';
import '../../models/comment_model.dart';
import 'comment_item.dart';

/// CommentsBottomSheet Widget
/// Modal bottom sheet displaying comments for a post
/// - Scrollable list of comments
/// - Fixed input field at bottom with send icon
class CommentsBottomSheet extends StatefulWidget {
  final List<CommentModel> comments;
  final String postTitle;

  const CommentsBottomSheet({
    super.key,
    required this.comments,
    this.postTitle = 'Comments',
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
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
                onSubmitted: (_) {
                  // Handle send action (no logic required per requirements)
                  _commentController.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Send icon button
            Material(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () {
                  // Handle send action (no logic required per requirements)
                  _commentController.clear();
                  _focusNode.unfocus();
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const Icon(
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
            child: widget.comments.isEmpty
                ? Center(
                    child: Text(
                      'No comments yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.comments.length,
                    itemBuilder: (context, index) {
                      return CommentItem(comment: widget.comments[index]);
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
  required List<CommentModel> comments,
  String postTitle = 'Comments',
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CommentsBottomSheet(
      comments: comments,
      postTitle: postTitle,
    ),
  );
}
