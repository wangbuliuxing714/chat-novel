import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';
import 'story_detail_screen.dart';

class StoryCreateScreen extends StatefulWidget {
  const StoryCreateScreen({Key? key}) : super(key: key);

  @override
  State<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends State<StoryCreateScreen> {
  final TextEditingController _promptController = TextEditingController();
  final StoryService _storyService = StoryService();
  String _selectedGenre = '冒险';
  bool _isGenerating = false;

  final List<String> _genres = [
    '冒险',
    '爱情',
    '科幻',
    '奇幻',
    '悬疑',
    '恐怖',
    '历史',
    '都市',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateStory() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入故事提示词')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final story = await _storyService.createStory(
        _promptController.text.trim(),
        _selectedGenre,
        context: context,
      );

      // 添加到故事列表中
      Provider.of<StoryListModel>(context, listen: false).addStory(story);

      if (mounted) {
        setState(() {
          _isGenerating = false;
        });

        // 导航到故事详情页
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StoryDetailScreen(story: story),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成故事失败: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建新故事'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '创建属于你的AI互动小说',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '输入一句话描述，AI将为你创建一个全新的互动故事。你可以通过选择或输入自己的想法来引导故事的发展。',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '故事提示词',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  hintText: '例如：一个年轻人意外获得了穿越时空的能力',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                '故事类型',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildGenreSelector(),
              const SizedBox(height: 8),
              _buildExamplePrompts(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateStory,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isGenerating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('正在创作故事...'),
                          ],
                        )
                      : const Text('生成故事'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenreSelector() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _genres.map((genre) {
        final isSelected = genre == _selectedGenre;
        return ChoiceChip(
          label: Text(genre),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedGenre = genre;
              });
            }
          },
          backgroundColor: Colors.grey[200],
          selectedColor: Colors.indigo[100],
          labelStyle: TextStyle(
            color: isSelected ? Colors.indigo : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExamplePrompts() {
    final examples = [
      '一位探险家在古老的洞穴中发现了未知文明',
      '一个普通上班族意外获得了心灵感应能力',
      '未来世界，AI与人类共存的社会',
      '一封来自过去的神秘信件改变了主角的命运',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '示例提示词',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...examples.map((example) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _promptController.text = example;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        example,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
} 