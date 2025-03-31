import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/story_model.dart';
import '../models/api_config_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'langchain_service.dart';
import 'package:langchain/langchain.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoryService {
  final LangChainService _langchainService = LangChainService();
  final Uuid _uuid = Uuid();
  // 本地存储的键名
  static const String _storiesKey = 'user_stories';
  
  // 创建默认配置
  ApiConfig _getDefaultConfig() {
    return ApiConfig(
      name: '阿里百炼',
      apiKey: '',
      apiUrl: 'https://dashscope.aliyuncs.com',
      apiPath: '/compatible-mode/v1/chat/completions',
      model: 'qwen-max',
      apiType: ApiType.dashScope,
    );
  }
  
  // 从ApiConfigModel获取API配置
  Future<ApiConfig> _getApiConfig(BuildContext? context) async {
    if (context != null) {
      final apiConfigModel = Provider.of<ApiConfigModel>(context, listen: false);
      return apiConfigModel.currentConfig ?? _getDefaultConfig();
    }
    
    // 如果上下文为空，则使用默认配置
    return _getDefaultConfig();
  }
  
  // 生成唯一ID
  String _generateId() {
    return _uuid.v4();
  }
  
  // 创建新故事
  Future<Story> createStory(String prompt, String genre, {BuildContext? context}) async {
    // 获取API配置
    final apiConfig = await _getApiConfig(context);
    
    try {
      // 使用LangChain生成故事开头
      final result = await _generateStoryContent(prompt, genre, apiConfig);
      
      final title = '${genre}故事: ${prompt.length > 20 ? prompt.substring(0, 20) + '...' : prompt}';
      
      final story = Story(
        id: _generateId(),
        title: title,
        coverPrompt: prompt,
        genre: genre,
        createdAt: DateTime.now(),
        chapters: [
          StoryChapter(
            content: result['content'],
            choices: result['choices'],
          ),
        ],
        chatHistory: result['messages'],
      );
      
      // 保存故事到本地存储
      await _saveStory(story);
      
      return story;
    } catch (e) {
      // 如果API调用失败，返回模拟数据
      final story = _createFallbackStory(prompt, genre);
      // 保存故事到本地存储
      await _saveStory(story);
      return story;
    }
  }
  
  // 保存故事到本地存储
  Future<void> _saveStory(Story story) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取现有故事列表
      final List<String> storedStories = prefs.getStringList(_storiesKey) ?? [];
      
      // 将新故事序列化为JSON字符串
      final storyJson = jsonEncode(story.toJson());
      
      // 添加到列表中
      storedStories.add(storyJson);
      
      // 保存更新后的列表
      await prefs.setStringList(_storiesKey, storedStories);
    } catch (e) {
      print('保存故事失败: ${e.toString()}');
    }
  }
  
  // 更新已有故事
  Future<void> updateStory(Story story) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取现有故事列表
      List<String> storedStories = prefs.getStringList(_storiesKey) ?? [];
      
      // 查找并更新故事
      for (int i = 0; i < storedStories.length; i++) {
        try {
          final Map<String, dynamic> storyMap = jsonDecode(storedStories[i]);
          if (storyMap['id'] == story.id) {
            // 更新找到的故事
            storedStories[i] = jsonEncode(story.toJson());
            break;
          }
        } catch (e) {
          print('解析故事JSON失败: ${e.toString()}');
        }
      }
      
      // 保存更新后的列表
      await prefs.setStringList(_storiesKey, storedStories);
    } catch (e) {
      print('更新故事失败: ${e.toString()}');
    }
  }
  
  // 获取特定故事
  Future<Story?> getStory(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取现有故事列表
      final List<String> storedStories = prefs.getStringList(_storiesKey) ?? [];
      
      // 查找特定故事
      for (final storyJson in storedStories) {
        try {
          final Map<String, dynamic> storyMap = jsonDecode(storyJson);
          if (storyMap['id'] == storyId) {
            return Story.fromJson(storyMap);
          }
        } catch (e) {
          print('解析故事JSON失败: ${e.toString()}');
        }
      }
      
      return null;
    } catch (e) {
      print('获取故事失败: ${e.toString()}');
      return null;
    }
  }
  
  // 删除故事
  Future<bool> deleteStory(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取现有故事列表
      List<String> storedStories = prefs.getStringList(_storiesKey) ?? [];
      
      // 查找并删除故事
      bool found = false;
      storedStories = storedStories.where((storyJson) {
        try {
          final Map<String, dynamic> storyMap = jsonDecode(storyJson);
          if (storyMap['id'] == storyId) {
            found = true;
            return false; // 删除这个故事
          }
          return true; // 保留这个故事
        } catch (e) {
          print('解析故事JSON失败: ${e.toString()}');
          return true; // 保留这个故事
        }
      }).toList();
      
      // 保存更新后的列表
      await prefs.setStringList(_storiesKey, storedStories);
      
      return found;
    } catch (e) {
      print('删除故事失败: ${e.toString()}');
      return false;
    }
  }
  
  // 生成故事内容的实际API调用
  Future<Map<String, dynamic>> _generateStoryContent(String prompt, String genre, ApiConfig apiConfig) async {
    if (apiConfig.apiKey.isEmpty) {
      // 如果API密钥为空，生成模拟数据
      return _generateMockStoryContent(prompt, genre);
    }
    
    try {
      // 使用LangChain生成内容
      return await _langchainService.generateStoryBeginning(prompt, genre, apiConfig);
    } catch (e) {
      // 如果LangChain调用失败，则直接调用API
      return await _callApiDirectly(prompt, genre, apiConfig);
    }
  }
  
  // 如果LangChain调用失败，则直接调用API
  Future<Map<String, dynamic>> _callApiDirectly(String prompt, String genre, ApiConfig apiConfig) async {
    final messages = [
      {'role': 'system', 'content': '你是一个交互式小说创作助手，擅长创建有趣的故事开头。'},
      {'role': 'user', 'content': '请基于以下提示创建一个${genre}类型的小说开头: $prompt'}
    ];
    
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer ${apiConfig.apiKey}'
    };
    
    Map<String, dynamic> requestBody = {
      'model': apiConfig.model,
      'messages': messages,
    };
    
    // 确保请求体使用UTF-8编码
    final encodedBody = utf8.encode(jsonEncode(requestBody));
    
    final response = await http.post(
      Uri.parse('${apiConfig.apiUrl}${apiConfig.apiPath}'),
      headers: headers,
      body: encodedBody,
    );
    
    if (response.statusCode == 200) {
      // 确保使用UTF-8解码响应
      final responseBody = utf8.decode(response.bodyBytes);
      final jsonResponse = jsonDecode(responseBody);
      
      String content;
      if (apiConfig.apiType == ApiType.dashScope) {
        content = jsonResponse['choices'][0]['message']['content'];
      } else {
        content = jsonResponse['choices'][0]['message']['content'];
      }
      
      // 提取选项
      final List<StoryChoice> choices = _extractChoicesFromText(content);
      
      // 创建聊天历史
      final chatHistory = [
        StoryMessage(role: 'system', content: '你是一个交互式小说创作助手，擅长创建有趣的故事开头。'),
        StoryMessage(role: 'user', content: '请基于以下提示创建一个${genre}类型的小说开头: $prompt'),
        StoryMessage(role: 'assistant', content: content),
      ];
      
      return {
        'content': content,
        'choices': choices,
        'messages': chatHistory,
      };
    } else {
      // 确保使用UTF-8解码错误响应
      final responseBody = utf8.decode(response.bodyBytes);
      throw Exception('API请求失败，状态码: ${response.statusCode}, 响应: $responseBody');
    }
  }
  
  // 从文本中提取选项
  List<StoryChoice> _extractChoicesFromText(String text) {
    // 默认选项，以防提取失败
    final defaultChoices = [
      StoryChoice(text: '继续当前路线'),
      StoryChoice(text: '尝试新的方向'),
      StoryChoice(text: '寻找更多信息'),
    ];
    
    try {
      // 正则表达式匹配选项模式
      final choiceRegex = RegExp(r'(?:\d+[\.\)、]|\*|\-)\s*([^\n\d\.\)]+)');
      final matches = choiceRegex.allMatches(text);
      
      if (matches.isEmpty) {
        return defaultChoices;
      }
      
      final choices = matches.map((match) {
        return StoryChoice(text: match.group(1)?.trim() ?? '');
      }).where((choice) => choice.text.isNotEmpty).toList();
      
      return choices.isNotEmpty ? choices : defaultChoices;
    } catch (e) {
      return defaultChoices;
    }
  }
  
  // 生成模拟故事内容
  Future<Map<String, dynamic>> _generateMockStoryContent(String prompt, String genre) async {
    await Future.delayed(const Duration(seconds: 2));
    
    final content = '这是一个关于$prompt的${genre}故事。故事刚刚开始，主角正在面临人生中的重要选择...';
    
    final choices = [
      StoryChoice(text: '勇敢面对挑战'),
      StoryChoice(text: '寻求帮助'),
      StoryChoice(text: '另辟蹊径'),
    ];
    
    final messages = [
      StoryMessage(role: 'system', content: '你是一个交互式小说创作助手，擅长创建有趣的故事开头。'),
      StoryMessage(role: 'user', content: '请基于以下提示创建一个${genre}类型的小说开头: $prompt'),
      StoryMessage(role: 'assistant', content: content),
    ];
    
    return {
      'content': content,
      'choices': choices,
      'messages': messages,
    };
  }
  
  // 创建模拟故事（如果API调用失败）
  Story _createFallbackStory(String prompt, String genre) {
    final content = '这是一个关于$prompt的${genre}故事。故事刚刚开始，主角正在面临人生中的重要选择...';
    
    final chatHistory = [
      StoryMessage(role: 'system', content: '你是一个交互式小说创作助手，擅长创建有趣的故事开头。'),
      StoryMessage(role: 'user', content: '请基于以下提示创建一个${genre}类型的小说开头: $prompt'),
      StoryMessage(role: 'assistant', content: content),
    ];
    
    return Story(
      id: _generateId(),
      title: '${genre}故事: $prompt',
      coverPrompt: prompt,
      genre: genre,
      createdAt: DateTime.now(),
      chapters: [
        StoryChapter(
          content: content,
          choices: [
            StoryChoice(text: '勇敢面对挑战'),
            StoryChoice(text: '寻求帮助'),
            StoryChoice(text: '另辟蹊径'),
          ],
        ),
      ],
      chatHistory: chatHistory,
    );
  }
  
  // 继续故事
  Future<StoryChapter> continueStory(String storyId, String choice, String userInput, {BuildContext? context, Story? story}) async {
    // 获取API配置
    final apiConfig = await _getApiConfig(context);
    
    try {
      if (story == null) {
        // 尝试从存储中获取故事
        story = await getStory(storyId);
        if (story == null) {
          throw Exception('未找到故事数据，无法继续');
        }
      }
      
      // 使用LangChain继续故事
      final result = await _continueStoryContent(storyId, choice, userInput, story.chatHistory, apiConfig);
      
      // 创建新的章节
      final newChapter = StoryChapter(
        content: result['content'],
        choices: result['choices'],
      );
      
      // 更新故事
      final updatedStory = Story(
        id: story.id,
        title: story.title,
        coverPrompt: story.coverPrompt,
        genre: story.genre,
        createdAt: story.createdAt,
        chapters: [...story.chapters, newChapter], // 添加新章节
        chatHistory: result['messages'], // 更新消息历史
      );
      
      // 保存更新后的故事
      await updateStory(updatedStory);
      
      return newChapter;
    } catch (e) {
      // 如果API调用失败，返回模拟数据
      return _createFallbackChapter(choice, userInput);
    }
  }
  
  // 继续故事内容的实际API调用
  Future<Map<String, dynamic>> _continueStoryContent(
    String storyId, 
    String choice, 
    String userInput, 
    List<StoryMessage> chatHistory, 
    ApiConfig apiConfig
  ) async {
    if (apiConfig.apiKey.isEmpty) {
      // 如果API密钥为空，生成模拟数据
      return _generateMockContinuationContent(choice, userInput, chatHistory);
    }
    
    try {
      // 使用LangChain继续故事
      return await _langchainService.continueStory(
        storyId, 
        choice, 
        userInput, 
        chatHistory, 
        apiConfig
      );
    } catch (e) {
      // 如果LangChain调用失败，则直接调用API
      return await _callApiDirectlyForContinuation(choice, userInput, chatHistory, apiConfig);
    }
  }
  
  // 如果LangChain调用失败，则直接调用API继续故事
  Future<Map<String, dynamic>> _callApiDirectlyForContinuation(
    String choice, 
    String userInput, 
    List<StoryMessage> previousMessages, 
    ApiConfig apiConfig
  ) async {
    // 将StoryMessage转换为API所需的消息格式
    final messages = previousMessages.map((msg) => {
      'role': msg.role,
      'content': msg.content,
    }).toList();
    
    // 添加新的用户消息
    messages.add({
      'role': 'user',
      'content': '继续这个故事，我选择了: $choice。${userInput.isNotEmpty ? "我的想法是: $userInput" : ""}'
    });
    
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer ${apiConfig.apiKey}'
    };
    
    Map<String, dynamic> requestBody = {
      'model': apiConfig.model,
      'messages': messages,
    };
    
    // 确保请求体使用UTF-8编码
    final encodedBody = utf8.encode(jsonEncode(requestBody));
    
    final response = await http.post(
      Uri.parse('${apiConfig.apiUrl}${apiConfig.apiPath}'),
      headers: headers,
      body: encodedBody,
    );
    
    if (response.statusCode == 200) {
      // 确保使用UTF-8解码响应
      final responseBody = utf8.decode(response.bodyBytes);
      final jsonResponse = jsonDecode(responseBody);
      
      String content;
      if (apiConfig.apiType == ApiType.dashScope) {
        content = jsonResponse['choices'][0]['message']['content'];
      } else {
        content = jsonResponse['choices'][0]['message']['content'];
      }
      
      // 提取选项
      final List<StoryChoice> choices = _extractChoicesFromText(content);
      
      // 创建聊天历史
      final newUserMessage = StoryMessage(
        role: 'user',
        content: '继续这个故事，我选择了: $choice。${userInput.isNotEmpty ? "我的想法是: $userInput" : ""}'
      );
      
      final newAssistantMessage = StoryMessage(
        role: 'assistant',
        content: content
      );
      
      final updatedMessages = [...previousMessages, newUserMessage, newAssistantMessage];
      
      return {
        'content': content,
        'choices': choices,
        'messages': updatedMessages,
      };
    } else {
      // 确保使用UTF-8解码错误响应
      final responseBody = utf8.decode(response.bodyBytes);
      throw Exception('API请求失败，状态码: ${response.statusCode}, 响应: $responseBody');
    }
  }
  
  // 生成模拟故事继续内容
  Future<Map<String, dynamic>> _generateMockContinuationContent(
    String choice, 
    String userInput, 
    List<StoryMessage> previousMessages
  ) async {
    await Future.delayed(const Duration(seconds: 2));
    
    String newContent;
    List<StoryChoice> newChoices;
    
    if (choice.contains('勇敢')) {
      newContent = '主角决定勇敢面对挑战。$userInput。这个决定让主角踏上了一段未知的旅程，前方充满了危险但也蕴含着宝贵的机遇...';
      newChoices = [
        StoryChoice(text: '探索神秘的洞穴'),
        StoryChoice(text: '与当地人交流获取信息'),
        StoryChoice(text: '休整并制定详细计划'),
      ];
    } else if (choice.contains('帮助')) {
      newContent = '主角决定寻求帮助。$userInput。这个决定让主角结识了新的盟友，但同时也暴露了自己的处境，引来了一些不怀好意的目光...';
      newChoices = [
        StoryChoice(text: '与新盟友共同制定计划'),
        StoryChoice(text: '谨慎行事，提防背叛'),
        StoryChoice(text: '利用自己的优势取得主动'),
      ];
    } else {
      newContent = '主角决定另辟蹊径。$userInput。这个出人意料的决定让事情出现了转机，但同时也带来了新的复杂局面...';
      newChoices = [
        StoryChoice(text: '继续坚持自己的计划'),
        StoryChoice(text: '适时调整策略'),
        StoryChoice(text: '寻找隐藏的真相'),
      ];
    }
    
    // 创建聊天历史
    final newUserMessage = StoryMessage(
      role: 'user',
      content: '继续这个故事，我选择了: $choice。${userInput.isNotEmpty ? "我的想法是: $userInput" : ""}'
    );
    
    final newAssistantMessage = StoryMessage(
      role: 'assistant',
      content: newContent
    );
    
    return {
      'content': newContent,
      'choices': newChoices,
      'messages': [...previousMessages, newUserMessage, newAssistantMessage],
    };
  }
  
  // 创建模拟故事章节（如果API调用失败）
  StoryChapter _createFallbackChapter(String choice, String userInput) {
    String newContent;
    List<StoryChoice> newChoices;
    
    if (choice.contains('勇敢')) {
      newContent = '主角决定勇敢面对挑战。$userInput。这个决定让主角踏上了一段未知的旅程，前方充满了危险但也蕴含着宝贵的机遇...';
      newChoices = [
        StoryChoice(text: '探索神秘的洞穴'),
        StoryChoice(text: '与当地人交流获取信息'),
        StoryChoice(text: '休整并制定详细计划'),
      ];
    } else if (choice.contains('帮助')) {
      newContent = '主角决定寻求帮助。$userInput。这个决定让主角结识了新的盟友，但同时也暴露了自己的处境，引来了一些不怀好意的目光...';
      newChoices = [
        StoryChoice(text: '与新盟友共同制定计划'),
        StoryChoice(text: '谨慎行事，提防背叛'),
        StoryChoice(text: '利用自己的优势取得主动'),
      ];
    } else {
      newContent = '主角决定另辟蹊径。$userInput。这个出人意料的决定让事情出现了转机，但同时也带来了新的复杂局面...';
      newChoices = [
        StoryChoice(text: '继续坚持自己的计划'),
        StoryChoice(text: '适时调整策略'),
        StoryChoice(text: '寻找隐藏的真相'),
      ];
    }
    
    return StoryChapter(
      content: newContent,
      choices: newChoices,
    );
  }
  
  // 获取用户的故事列表
  Future<List<Story>> getUserStories(String userId, {BuildContext? context}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取本地存储的故事列表
      final List<String> storedStories = prefs.getStringList(_storiesKey) ?? [];
      
      // 将JSON字符串转换为Story对象
      final List<Story> stories = [];
      for (final storyJson in storedStories) {
        try {
          final Map<String, dynamic> storyMap = jsonDecode(storyJson);
          stories.add(Story.fromJson(storyMap));
        } catch (e) {
          print('解析故事JSON失败: ${e.toString()}');
        }
      }
      
      // 按创建时间排序，最新的排在前面
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return stories;
    } catch (e) {
      print('获取故事列表失败: ${e.toString()}');
      
      // 如果出错，返回一些模拟数据
    return [
      Story(
        id: 'story1',
        title: '神秘岛屿的冒险',
        coverPrompt: '一个年轻人在神秘岛屿上的冒险',
        chapters: [
          StoryChapter(
            content: '这是一个关于神秘岛屿的冒险故事。主角意外流落到一个未知的岛屿，发现这里有着奇特的生物和未解之谜...',
            choices: [],
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        genre: '冒险',
          chatHistory: [
            StoryMessage(role: 'system', content: '你是一个交互式小说创作助手，擅长创建有趣的故事开头。'),
            StoryMessage(role: 'user', content: '请基于以下提示创建一个冒险类型的小说开头: 一个年轻人在神秘岛屿上的冒险'),
            StoryMessage(role: 'assistant', content: '这是一个关于神秘岛屿的冒险故事。主角意外流落到一个未知的岛屿，发现这里有着奇特的生物和未解之谜...'),
          ],
      ),
      Story(
        id: 'story2',
        title: '都市爱情',
        coverPrompt: '都市里的爱情故事',
        chapters: [
          StoryChapter(
            content: '这是一个现代都市爱情故事。主角在繁忙的工作中邂逅了命中注定的那个人，但现实的压力让这段感情面临挑战...',
            choices: [],
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        genre: '爱情',
          chatHistory: [
            StoryMessage(role: 'system', content: '你是一个交互式小说创作助手，擅长创建有趣的故事开头。'),
            StoryMessage(role: 'user', content: '请基于以下提示创建一个爱情类型的小说开头: 都市里的爱情故事'),
            StoryMessage(role: 'assistant', content: '这是一个现代都市爱情故事。主角在繁忙的工作中邂逅了命中注定的那个人，但现实的压力让这段感情面临挑战...'),
          ],
      ),
    ];
    }
  }
} 