import 'user_model.dart';
import 'post_model.dart';
import 'comment_model.dart';

/// Mock data provider for development
class MockData {
  /// Get mock users (religious leaders)
  static List<UserModel> getMockUsers() {
    return [
      UserModel(
        id: '1',
        name: 'Rabbi Abraham Cohen',
        username: '@stjohn',
        profileImageUrl: '',
        isVerified: true,
        description: 'Curabitur interdum, justo at dignissim dignissim, nisi nisl tincidunt nulla, vitae efficitur lorem ipsum dolor sit amet.',
        community: 'Jewish',
        role: 'Temple Priest',
      ),
      UserModel(
        id: '2',
        name: 'Rabbi Aaron Kaplan',
        username: '@aaron_kaplan',
        profileImageUrl: '',
        isVerified: true,
        description: 'Consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        community: 'Jewish',
        role: 'Rabbi',
      ),
      UserModel(
        id: '3',
        name: 'Rabbi David Rosenberg',
        username: '@david_rosenberg',
        profileImageUrl: '',
        isVerified: true,
        description: 'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
        community: 'Jewish',
        role: 'Pastor',
      ),
      UserModel(
        id: '4',
        name: 'Rabbi Samuel Katz',
        username: '@samuel_katz',
        profileImageUrl: '',
        isVerified: true,
        description: 'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
        community: 'Jewish',
        role: 'Temple Priest',
      ),
      UserModel(
        id: '5',
        name: 'Rabbi Isaac Levi',
        username: '@isaac_levi',
        profileImageUrl: '',
        isVerified: true,
        description: 'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
        community: 'Jewish',
        role: 'Rabbi',
      ),
      UserModel(
        id: '6',
        name: 'Rabbi Eliyahu Weiss',
        username: '@eliyahu_weiss',
        profileImageUrl: '',
        isVerified: true,
        description: 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.',
        community: 'Jewish',
        role: 'Pastor',
      ),
    ];
  }

  /// Get mock users for "My Leaders" tab (already followed)
  static List<UserModel> getMockMyLeaders() {
    final allLeaders = getMockUsers();
    // Return first 4 leaders as "My Leaders"
    return allLeaders.take(4).toList();
  }

  /// Get mock users for "Explore" tab (not yet followed)
  static List<UserModel> getMockExploreLeaders() {
    final allLeaders = getMockUsers();
    // Return all leaders for explore
    return allLeaders;
  }

  /// Get mock posts for the home feed
  static List<PostModel> getMockPosts() {
    final users = getMockUsers();
    final now = DateTime.now();

    return [
      // Posts by Rabbi Abraham Cohen (users[0])
      PostModel(
        id: '1',
        author: users[0],
        content:
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        createdAt: now.subtract(const Duration(hours: 1)),
        likes: 160000,
        comments: 48800,
        shares: 12000,
        views: 82000,
      ),
      PostModel(
        id: '1a',
        author: users[0],
        content:
            'Today I want to share a message of hope and faith. Remember that difficult times are temporary, and your faith will guide you through.',
        createdAt: now.subtract(const Duration(hours: 5)),
        likes: 8500,
        comments: 1200,
        shares: 340,
        views: 15000,
      ),
      // Reels by Rabbi Aaron Kaplan (users[1])
      PostModel(
        id: '2',
        author: users[1],
        content:
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        videoUrl: 'video_url_placeholder',
        createdAt: now.subtract(const Duration(hours: 2)),
        likes: 12000,
        comments: 20200,
        shares: 16000,
        views: 42000,
      ),
      PostModel(
        id: '2a',
        author: users[1],
        content:
            'A special message for the community. Watch this video to learn more about spiritual growth.',
        videoUrl: 'video_url_placeholder',
        createdAt: now.subtract(const Duration(hours: 8)),
        likes: 5600,
        comments: 890,
        shares: 450,
        views: 12000,
      ),
      // Posts by Rabbi David Rosenberg (users[2])
      PostModel(
        id: '3',
        author: users[2],
        content:
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        createdAt: now.subtract(const Duration(hours: 2)),
        likes: 11000,
        comments: 20000,
        shares: 14000,
        views: 30000,
      ),
      PostModel(
        id: '3a',
        author: users[2],
        content:
            'Gratitude is the key to happiness. Take a moment today to appreciate the blessings in your life.',
        createdAt: now.subtract(const Duration(hours: 6)),
        likes: 7200,
        comments: 1450,
        shares: 280,
        views: 18000,
      ),
      // Post by Rabbi Samuel Katz (users[3])
      PostModel(
        id: '4',
        author: users[3],
        content:
            'Wisdom comes from experience and reflection. Let us take time to reflect on our spiritual journey.',
        createdAt: now.subtract(const Duration(hours: 4)),
        likes: 9300,
        comments: 1650,
        shares: 520,
        views: 22000,
      ),
    ];
  }

  /// Get mock comments for posts
  static List<CommentModel> getMockComments() {
    final users = getMockUsers();
    final now = DateTime.now();

    return [
      CommentModel(
        id: '1',
        userId: '5',
        text:
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        createdAt: now.subtract(const Duration(hours: 13)),
        author: UserModel(
          id: '5',
          name: 'Willard Gleichner',
          username: '@willard_gleichner',
          profileImageUrl: '',
          isVerified: false,
        ),
      ),
      CommentModel(
        id: '2',
        userId: '6',
        text:
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        createdAt: now.subtract(const Duration(days: 1)),
        author: UserModel(
          id: '6',
          name: 'Kristie Stiedemann',
          username: '@kristie_stiedemann',
          profileImageUrl: '',
          isVerified: false,
        ),
      ),
      CommentModel(
        id: '3',
        userId: users[0].id,
        text: 'Thank you for sharing this wonderful message. It really touched my heart.',
        createdAt: now.subtract(const Duration(hours: 3)),
        author: users[0],
      ),
      CommentModel(
        id: '4',
        userId: '7',
        text: 'Great post! Looking forward to more content like this.',
        createdAt: now.subtract(const Duration(hours: 5)),
        author: UserModel(
          id: '7',
          name: 'John Smith',
          username: '@john_smith',
          profileImageUrl: '',
          isVerified: false,
        ),
      ),
      CommentModel(
        id: '5',
        userId: users[2].id,
        text: 'This is exactly what I needed to hear today. Thank you for your wisdom.',
        createdAt: now.subtract(const Duration(hours: 8)),
        author: users[2],
      ),
    ];
  }
}