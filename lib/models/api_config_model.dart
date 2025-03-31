import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiConfig {
  final String id;
  final String name;
  final String apiKey;
  final String apiUrl;
  final String apiPath;
  final String model;
  final ApiType apiType;
  final bool useProxy;

  ApiConfig({
    String? id,
    required this.name,
    required this.apiKey,
    required this.apiUrl,
    required this.apiPath,
    required this.model,
    required this.apiType,
    this.useProxy = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '未命名',
      apiKey: json['apiKey'] ?? '',
      apiUrl: json['apiUrl'] ?? 'https://api.openai.com/v1',
      apiPath: json['apiPath'] ?? '/chat/completions',
      model: json['model'] ?? 'gpt-4o',
      apiType: ApiType.values.firstWhere(
        (e) => e.toString() == json['apiType'],
        orElse: () => ApiType.openAi,
      ),
      useProxy: json['useProxy'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'apiKey': apiKey,
      'apiUrl': apiUrl,
      'apiPath': apiPath,
      'model': model,
      'apiType': apiType.toString(),
      'useProxy': useProxy,
    };
  }

  ApiConfig copyWith({
    String? id,
    String? name,
    String? apiKey,
    String? apiUrl,
    String? apiPath,
    String? model,
    ApiType? apiType,
    bool? useProxy,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      apiKey: apiKey ?? this.apiKey,
      apiUrl: apiUrl ?? this.apiUrl,
      apiPath: apiPath ?? this.apiPath,
      model: model ?? this.model,
      apiType: apiType ?? this.apiType,
      useProxy: useProxy ?? this.useProxy,
    );
  }
}

enum ApiType {
  openAi,
  azure,
  dashScope,
  custom,
}

class ApiConfigModel extends ChangeNotifier {
  static const String _prefsKey = 'api_configs';
  static const String _activeConfigIdKey = 'active_config_id';
  
  List<ApiConfig> _configs = [];
  String? _activeConfigId;
  
  // 所有配置
  List<ApiConfig> get configs => _configs;
  
  // 当前激活的配置
  ApiConfig get currentConfig {
    if (_activeConfigId != null) {
      final matchingConfig = _configs.firstWhere(
        (config) => config.id == _activeConfigId,
        orElse: () => _configs.isNotEmpty ? _configs.first : _createDefaultConfig(),
      );
      return matchingConfig;
    }
    
    return _configs.isNotEmpty ? _configs.first : _createDefaultConfig();
  }
  
  // 创建默认配置
  ApiConfig _createDefaultConfig() {
    final defaultConfig = ApiConfig(
      name: '阿里百炼默认配置',
      apiKey: '',
      apiUrl: 'https://dashscope.aliyuncs.com',
      apiPath: '/compatible-mode/v1/chat/completions',
      model: 'qwen-max',
      apiType: ApiType.dashScope,
    );
    
    // 如果配置列表为空，添加这个默认配置
    if (_configs.isEmpty) {
      _configs.add(defaultConfig);
      _activeConfigId = defaultConfig.id;
      _saveToPrefs();
    }
    
    return defaultConfig;
  }
  
  // 初始化，从SharedPreferences加载配置
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configsJson = prefs.getString(_prefsKey);
    final String? activeId = prefs.getString(_activeConfigIdKey);
    
    if (configsJson != null) {
      try {
        final List<dynamic> configsList = json.decode(configsJson);
        _configs = configsList.map((config) => ApiConfig.fromJson(config)).toList();
        _activeConfigId = activeId;
        
        // 如果没有配置，创建一个默认配置
        if (_configs.isEmpty) {
          _addDefaultConfig();
        }
        
        notifyListeners();
      } catch (e) {
        print('加载API配置失败: $e');
        // 如果加载失败，创建默认配置
        _addDefaultConfig();
      }
    } else {
      // 如果没有保存的配置，创建默认配置
      _addDefaultConfig();
    }
  }
  
  // 添加默认配置
  void _addDefaultConfig() {
    final defaultOpenAIConfig = ApiConfig(
      name: 'OpenAI默认配置',
      apiKey: '',
      apiUrl: 'https://api.openai.com/v1',
      apiPath: '/chat/completions',
      model: 'gpt-4o',
      apiType: ApiType.openAi,
    );
    
    final defaultDashScopeConfig = ApiConfig(
      name: '阿里百炼默认配置',
      apiKey: '',
      apiUrl: 'https://dashscope.aliyuncs.com',
      apiPath: '/compatible-mode/v1/chat/completions',
      model: 'qwen-max',
      apiType: ApiType.dashScope,
    );
    
    _configs = [defaultOpenAIConfig, defaultDashScopeConfig];
    _activeConfigId = defaultDashScopeConfig.id; // 设置阿里百炼为默认激活配置
    notifyListeners();
    _saveToPrefs();
  }
  
  // 保存配置到SharedPreferences
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(_configs.map((c) => c.toJson()).toList()));
    
    if (_activeConfigId != null) {
      await prefs.setString(_activeConfigIdKey, _activeConfigId!);
    }
  }
  
  // 添加新配置
  Future<void> addConfig(ApiConfig config) async {
    _configs.add(config);
    notifyListeners();
    await _saveToPrefs();
  }
  
  // 更新配置
  Future<void> updateConfig(ApiConfig updatedConfig) async {
    final index = _configs.indexWhere((config) => config.id == updatedConfig.id);
    if (index != -1) {
      _configs[index] = updatedConfig;
      notifyListeners();
      await _saveToPrefs();
    }
  }
  
  // 删除配置
  Future<void> deleteConfig(String configId) async {
    _configs.removeWhere((config) => config.id == configId);
    
    // 如果删除的是当前激活的配置，重新设置激活配置
    if (_activeConfigId == configId) {
      _activeConfigId = _configs.isNotEmpty ? _configs.first.id : null;
    }
    
    notifyListeners();
    await _saveToPrefs();
  }
  
  // 设置激活的配置
  Future<void> setActiveConfig(String configId) async {
    if (_configs.any((config) => config.id == configId)) {
      _activeConfigId = configId;
      notifyListeners();
      await _saveToPrefs();
    }
  }
  
  // 复制配置并添加
  Future<void> duplicateConfig(String configId) async {
    final configToDuplicate = _configs.firstWhere(
      (config) => config.id == configId,
      orElse: () => throw Exception('配置不存在'),
    );
    
    final newConfig = configToDuplicate.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${configToDuplicate.name} 副本',
    );
    
    await addConfig(newConfig);
  }
} 