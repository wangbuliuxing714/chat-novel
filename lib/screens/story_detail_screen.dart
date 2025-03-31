import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class StoryDetailScreen extends StatefulWidget {
  final Story story;

  const StoryDetailScreen({
    Key? key,
    required this.story,
  }) : super(key: key);

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final StoryService _storyService = StoryService();
  final TextEditingController _userInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late Story _currentStory;
  bool _isGenerating = false;
  String? _selectedChoice;
  bool _showInput = false;

  @override
  void initState() {
    super.initState();
    _currentStory = widget.story;
  }

  @override
  void dispose() {
    _userInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _continueStory() async {
    if (_selectedChoice == null && _userInputController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择一个选项或输入你的想法')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final userInput = _userInputController.text.trim().isEmpty
          ? _selectedChoice!
          : _userInputController.text.trim();
      
      final newChapter = await _storyService.continueStory(
        _currentStory.id,
        _selectedChoice ?? '自定义',
        userInput,
        context: context,
        story: _currentStory,
      );

      if (mounted) {
        setState(() {
          final updatedChapters = [..._currentStory.chapters, newChapter];
          
          // 更新当前故事
          final userMessage = StoryMessage(
            role: 'user',
            content: '继续这个故事，我选择了: ${_selectedChoice ?? "自定义"}。${userInput.isNotEmpty ? "我的想法是: $userInput" : ""}'
          );
          
          final assistantMessage = StoryMessage(
            role: 'assistant',
            content: newChapter.content
          );
          
          final updatedHistory = [..._currentStory.chatHistory, userMessage, assistantMessage];
          
          _currentStory = _currentStory.copyWith(
            chapters: updatedChapters,
            chatHistory: updatedHistory,
          );

          // 更新故事列表中的故事
          // 不需要Provider，因为已经在StoryService中更新了本地存储

          _isGenerating = false;
          _selectedChoice = null;
          _showInput = false;
          _userInputController.clear();
        });

        // 滚动到底部
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('继续故事失败: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStory.title),
      ),
      body: Column(
        children: [
          // 故事内容区域
          Expanded(
            child: _buildStoryContent(),
          ),
          
          // 交互区域
          _buildInteractionArea(),
        ],
      ),
    );
  }

  Widget _buildStoryContent() {
    return Container(
      color: const Color(0xFFF7F7F7),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: _currentStory.chapters.length,
        itemBuilder: (context, index) {
          final chapter = _currentStory.chapters[index];
          final isLastChapter = index == _currentStory.chapters.length - 1;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MarkdownBody(
                    data: chapter.content,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
              ),
              if (isLastChapter && chapter.choices.isNotEmpty && !_isGenerating)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: _buildChoices(chapter.choices),
                ),
              if (!isLastChapter)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Icon(
                      Icons.arrow_downward,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChoices(List<StoryChoice> choices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择下一步',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...choices.map((choice) {
          final isSelected = _selectedChoice == choice.text;
          return Card(
            color: isSelected ? Colors.indigo[50] : Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? Colors.indigo : Colors.transparent,
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedChoice = choice.text;
                  _showInput = false;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Colors.indigo : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        choice.text,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        // 自定义选择
        Card(
          color: _showInput ? Colors.indigo[50] : Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _showInput ? Colors.indigo : Colors.transparent,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedChoice = null;
                _showInput = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(
                    _showInput ? Icons.check_circle : Icons.circle_outlined,
                    color: _showInput ? Colors.indigo : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('自定义剧情发展...'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_showInput)
            TextField(
              controller: _userInputController,
              decoration: const InputDecoration(
                hintText: '请输入你的剧情发展想法...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              minLines: 1,
            ),
          if (_showInput) 
            const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _continueStory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isGenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SpinKitThreeBounce(
                          color: Colors.white,
                          size: 20.0,
                        ),
                        SizedBox(width: 12),
                        Text('AI正在创作...'),
                      ],
                    )
                  : Text(_selectedChoice != null || _showInput ? '继续故事' : '请选择或输入剧情发展'),
            ),
          ),
        ],
      ),
    );
  }
} 