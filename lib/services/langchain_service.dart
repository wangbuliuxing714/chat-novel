import 'package:langchain/langchain.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/story_model.dart';
import '../models/api_config_model.dart';
import 'package:provider/provider.dart';

class LangChainService {
  // 默认系统提示
  static const String _defaultSystemPrompt = 
    '你是一个交互式小说创作助手，擅长创建有趣的故事情节和生动的场景描写。'
    '你会根据用户的选择和输入继续发展故事，生成引人入胜的内容。'
    '请生成符合人类价值观和伦理观的内容，不要包含暴力、色情或其他可能引起不适的内容。'
    '每次回应生成2-3个可能的情节发展选项，让用户能够互动参与故事发展。';
  
  // 用于生成故事开头
  Future<Map<String, dynamic>> generateStoryBeginning(
    String prompt, 
    String genre, 
    ApiConfig apiConfig,
  ) async {
    try {
      // 准备消息列表
      final systemMessage = StoryMessage(
        role: 'system', 
        content: '$_defaultSystemPrompt 你需要创建一个${genre}类型的故事开头。'
      );
      
      final userMessage = StoryMessage(
        role: 'user', 
        content: '请基于以下提示创建一个${genre}类型的小说开头: $prompt'
      );
      
      // 添加到上下文历史
      final messages = [systemMessage, userMessage];
      
      if (apiConfig.apiKey.isEmpty) {
        throw Exception('API密钥未设置');
      }
      
      // 直接调用API
      final content = await _callAiApi(messages, apiConfig);
      
      // 分析回复内容，提取选项
      final List<StoryChoice> choices = _extractChoicesFromText(content);
      
      // 生成助手回复消息
      final assistantMessage = StoryMessage(role: 'assistant', content: content);
      
      // 添加到上下文历史
      final updatedMessages = [...messages, assistantMessage];
      
      // 返回生成的内容、选项和消息历史
      return {
        'content': content,
        'choices': choices,
        'messages': updatedMessages,
      };
    } catch (e) {
      throw Exception('生成故事失败: ${e.toString()}');
    }
  }
  
  // 用于继续故事情节
  Future<Map<String, dynamic>> continueStory(
    String storyId,
    String userChoice, 
    String userInput,
    List<StoryMessage> previousMessages,
    ApiConfig apiConfig,
  ) async {
    try {
      // 创建新的用户消息
      final userMessage = StoryMessage(
        role: 'user',
        content: '继续这个故事，我选择了: $userChoice。${userInput.isNotEmpty ? "我的想法是: $userInput" : ""}'
      );
      
      // 组合所有消息
      final allMessages = [...previousMessages, userMessage];
      
      if (apiConfig.apiKey.isEmpty) {
        throw Exception('API密钥未设置');
      }
      
      // 直接调用API
      final content = await _callAiApi(allMessages, apiConfig);
      
      // 分析回复内容，提取选项
      final List<StoryChoice> choices = _extractChoicesFromText(content);
      
      // 生成助手回复消息
      final assistantMessage = StoryMessage(role: 'assistant', content: content);
      
      // 返回生成的内容、选项和更新后的消息历史
      return {
        'content': content,
        'choices': choices,
        'messages': [...allMessages, assistantMessage],
      };
    } catch (e) {
      throw Exception('继续故事失败: ${e.toString()}');
    }
  }
  
  // 调用AI API
  Future<String> _callAiApi(List<StoryMessage> messages, ApiConfig apiConfig) async {
    // 准备API请求
    final apiMessages = messages.map((msg) => {
      'role': msg.role,
      'content': msg.content,
    }).toList();
    
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer ${apiConfig.apiKey}'
    };
    
    Map<String, dynamic> requestBody = {
      'model': apiConfig.model,
      'messages': apiMessages,
    };
    
    // 确保请求体使用UTF-8编码
    final encodedBody = utf8.encode(jsonEncode(requestBody));
    
    // 发送API请求
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
        // 阿里百炼API的响应格式
        content = jsonResponse['choices'][0]['message']['content'];
      } else {
        // OpenAI或其他API的响应格式
        content = jsonResponse['choices'][0]['message']['content'];
      }
      
      return content;
    } else {
      // 确保使用UTF-8解码错误响应
      final responseBody = utf8.decode(response.bodyBytes);
      throw Exception('API请求失败，状态码: ${response.statusCode}, 响应: $responseBody');
    }
  }
  
  // 从AI回复中提取选项
  List<StoryChoice> _extractChoicesFromText(String text) {
    // 默认选项，以防提取失败
    final defaultChoices = [
      StoryChoice(text: '继续当前路线'),
      StoryChoice(text: '尝试新的方向'),
      StoryChoice(text: '寻找更多信息'),
    ];
    
    try {
      // 正则表达式匹配选项模式
      // 可能的格式: 1. 选项一, 2) 选项二, 选项1:, 等
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
} 