import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../services/story_service.dart';
import 'story_detail_screen.dart';
import 'story_read_screen.dart';

class StoryListScreen extends StatefulWidget {
  const StoryListScreen({Key? key}) : super(key: key);

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen> {
  final StoryService _storyService = StoryService();
  bool _isLoading = false;
  List<Story> _userStories = [];

  @override
  void initState() {
    super.initState();
    _loadUserStories();
  }

  Future<void> _loadUserStories() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      final stories = await _storyService.getUserStories(
        userModel.userId ?? 'guest',
        context: context,
      );
      
      if (mounted) {
        setState(() {
          _userStories = stories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载故事失败: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的故事'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _userStories.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.book_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '你还没有创建故事',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '返回首页创建一个新故事吧！',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('返回首页'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserStories,
                  child: ListView.builder(
                    itemCount: _userStories.length,
                    itemBuilder: (context, index) {
                      final story = _userStories[index];
                      return _buildStoryCard(story);
                    },
                  ),
                ),
    );
  }

  Widget _buildStoryCard(Story story) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryDetailScreen(story: story),
            ),
          ).then((_) => _loadUserStories());
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.indigo[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        _getGenreIcon(story.genre),
                        size: 40,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '类型: ${story.genre}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '章节: ${story.chapters.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '创建于: ${story.createdAt.year}-${story.createdAt.month}-${story.createdAt.day}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                story.chapters.first.content.length > 100
                    ? '${story.chapters.first.content.substring(0, 100)}...'
                    : story.chapters.first.content,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.book, size: 16),
                    label: const Text('阅读'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryReadScreen(story: story),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('继续写作'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryDetailScreen(story: story),
                        ),
                      ).then((_) => _loadUserStories());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGenreIcon(String genre) {
    switch (genre.toLowerCase()) {
      case '冒险':
        return Icons.explore;
      case '爱情':
        return Icons.favorite;
      case '科幻':
        return Icons.rocket;
      case '奇幻':
        return Icons.auto_fix_high;
      case '悬疑':
        return Icons.search;
      case '恐怖':
        return Icons.gps_not_fixed;
      default:
        return Icons.book;
    }
  }
} 