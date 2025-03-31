import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/story_model.dart';

class StoryReadScreen extends StatefulWidget {
  final Story story;

  const StoryReadScreen({
    Key? key,
    required this.story,
  }) : super(key: key);

  @override
  State<StoryReadScreen> createState() => _StoryReadScreenState();
}

class _StoryReadScreenState extends State<StoryReadScreen> {
  final ScrollController _scrollController = ScrollController();
  late List<String> _storyContent;
  
  @override
  void initState() {
    super.initState();
    // 只提取AI回复的内容
    _storyContent = _extractAssistantMessages(widget.story.chatHistory);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  // 从聊天历史中提取所有AI助手回复的内容
  List<String> _extractAssistantMessages(List<StoryMessage> chatHistory) {
    return chatHistory
        .where((message) => message.role == 'assistant')
        .map((message) => message.content)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.story.title),
        actions: [
          // 添加字体大小调整按钮
          IconButton(
            icon: const Icon(Icons.format_size),
            onPressed: () {
              _showFontSizeDialog();
            },
          ),
        ],
      ),
      body: _buildStoryReadView(),
    );
  }

  // 阅读视图
  Widget _buildStoryReadView() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: _storyContent.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 章节标题
                  if (index == 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '第 ${index + 1} 章',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '第 ${index + 1} 章',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  // 章节内容
                  MarkdownBody(
                    data: _storyContent[index],
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // 显示字体大小调整对话框
  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('调整字体大小'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('小'),
                onTap: () {
                  // 实现字体大小调整功能
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('中'),
                onTap: () {
                  // 实现字体大小调整功能
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('大'),
                onTap: () {
                  // 实现字体大小调整功能
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
} 