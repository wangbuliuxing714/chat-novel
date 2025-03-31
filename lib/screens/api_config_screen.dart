import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_config_model.dart';

class ApiConfigScreen extends StatefulWidget {
  const ApiConfigScreen({Key? key}) : super(key: key);

  @override
  State<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends State<ApiConfigScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _apiPathController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  bool _showApiKey = false;
  ApiType _selectedApiType = ApiType.openAi;
  bool _useProxy = false;
  
  String? _currentConfigId;
  bool _isCreatingNew = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // 当屏幕初始化时，加载现有配置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentConfig();
    });
  }
  
  void _loadCurrentConfig() {
    final apiConfigModel = Provider.of<ApiConfigModel>(context, listen: false);
    final currentConfig = apiConfigModel.currentConfig;
    
    if (currentConfig != null) {
      setState(() {
        _currentConfigId = currentConfig.id;
        _nameController.text = currentConfig.name;
        _apiUrlController.text = currentConfig.apiUrl;
        _apiPathController.text = currentConfig.apiPath;
        _apiKeyController.text = currentConfig.apiKey;
        _modelController.text = currentConfig.model;
        _selectedApiType = currentConfig.apiType;
        _useProxy = currentConfig.useProxy;
        _isCreatingNew = false;
      });
    }
  }
  
  // 使用指定的配置
  void _loadConfig(ApiConfig config) {
    setState(() {
      _currentConfigId = config.id;
      _nameController.text = config.name;
      _apiUrlController.text = config.apiUrl;
      _apiPathController.text = config.apiPath;
      _apiKeyController.text = config.apiKey;
      _modelController.text = config.model;
      _selectedApiType = config.apiType;
      _useProxy = config.useProxy;
      _isCreatingNew = false;
    });
  }
  
  // 创建新配置
  void _createNew() {
    setState(() {
      _currentConfigId = null;
      _nameController.text = '新配置';
      _apiUrlController.text = 'https://api.openai.com/v1';
      _apiPathController.text = '/chat/completions';
      _apiKeyController.text = '';
      _modelController.text = 'gpt-4o';
      _selectedApiType = ApiType.openAi;
      _useProxy = false;
      _isCreatingNew = true;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _apiUrlController.dispose();
    _apiPathController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  // 保存当前配置
  void _saveConfig() {
    final apiConfigModel = Provider.of<ApiConfigModel>(context, listen: false);
    
    final newConfig = ApiConfig(
      id: _currentConfigId,
      name: _nameController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      apiUrl: _apiUrlController.text.trim(),
      apiPath: _apiPathController.text.trim(),
      model: _modelController.text.trim(),
      apiType: _selectedApiType,
      useProxy: _useProxy,
    );
    
    if (_isCreatingNew) {
      apiConfigModel.addConfig(newConfig).then((_) {
        _isCreatingNew = false;
        _currentConfigId = newConfig.id;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('新配置已创建')),
        );
      });
    } else {
      apiConfigModel.updateConfig(newConfig).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置已更新')),
        );
      });
    }
  }
  
  // 复制当前配置
  void _duplicateConfig() {
    if (_currentConfigId == null) return;
    
    final apiConfigModel = Provider.of<ApiConfigModel>(context, listen: false);
    apiConfigModel.duplicateConfig(_currentConfigId!).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已复制')),
      );
    });
  }
  
  // 删除当前配置
  void _deleteConfig() {
    if (_currentConfigId == null) return;
    
    final apiConfigModel = Provider.of<ApiConfigModel>(context, listen: false);
    
    // 如果只有一个配置，不允许删除
    if (apiConfigModel.configs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法删除唯一的配置')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: const Text('确定要删除这个配置吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              apiConfigModel.deleteConfig(_currentConfigId!).then((_) {
                // 删除后加载新的当前配置
                _loadCurrentConfig();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('配置已删除')),
                );
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  // 设置当前配置为激活配置
  void _setAsActive() {
    if (_currentConfigId == null) return;
    
    final apiConfigModel = Provider.of<ApiConfigModel>(context, listen: false);
    apiConfigModel.setActiveConfig(_currentConfigId!).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已设置为当前使用的配置')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.model_training), text: '模型'),
            Tab(icon: Icon(Icons.visibility), text: '显示'),
            Tab(icon: Icon(Icons.chat), text: '对话'),
            Tab(icon: Icon(Icons.settings_applications), text: '其他'),
            Tab(icon: Icon(Icons.extension), text: '扩展'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 模型设置选项卡
          _buildModelTab(),
          
          // 其他选项卡（示例空内容）
          const Center(child: Text('显示设置')),
          const Center(child: Text('对话设置')),
          const Center(child: Text('其他设置')),
          const Center(child: Text('扩展设置')),
        ],
      ),
    );
  }

  Widget _buildModelTab() {
    return Consumer<ApiConfigModel>(
      builder: (context, apiConfigModel, child) {
        final allConfigs = apiConfigModel.configs;
        final activeConfig = apiConfigModel.currentConfig;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 配置选择器
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '已保存的配置',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('新建'),
                            onPressed: _createNew,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allConfigs.length,
                        itemBuilder: (context, index) {
                          final config = allConfigs[index];
                          final isActive = activeConfig?.id == config.id;
                          final isSelected = _currentConfigId == config.id;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isSelected ? Colors.indigo.withOpacity(0.1) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected 
                                    ? Colors.indigo 
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _loadConfig(config),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  children: [
                                    if (isActive)
                                      const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                    else
                                      const SizedBox(width: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        config.name,
                                        style: TextStyle(
                                          fontWeight: isSelected || isActive 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      config.apiType.toString().split('.').last,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            
              const Text(
                '编辑配置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // API 模式选择
              Card(
                margin: const EdgeInsets.symmetric(vertical: 12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('API 模式'),
                      DropdownButton<ApiType>(
                        isExpanded: true,
                        value: _selectedApiType,
                        onChanged: (ApiType? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedApiType = newValue;
                              
                              // 根据选择的API类型设置默认值
                              if (newValue == ApiType.openAi) {
                                _apiUrlController.text = 'https://api.openai.com/v1';
                                _apiPathController.text = '/chat/completions';
                              } else if (newValue == ApiType.azure) {
                                _apiUrlController.text = 'https://YOUR_RESOURCE_NAME.openai.azure.com';
                                _apiPathController.text = '/openai/deployments/YOUR_DEPLOYMENT_NAME/chat/completions';
                              } else if (newValue == ApiType.dashScope) {
                                _apiUrlController.text = 'https://dashscope.aliyuncs.com';
                                _apiPathController.text = '/compatible-mode/v1/chat/completions';
                                _modelController.text = 'qwen-max';
                              }
                            });
                          }
                        },
                        items: ApiType.values.map<DropdownMenuItem<ApiType>>((ApiType value) {
                          String displayText;
                          switch (value) {
                            case ApiType.openAi:
                              displayText = 'OpenAI API 密钥';
                              break;
                            case ApiType.azure:
                              displayText = 'Azure OpenAI 密钥';
                              break;
                            case ApiType.dashScope:
                              displayText = '阿里百炼 API 密钥';
                              break;
                            case ApiType.custom:
                              displayText = '自定义后端';
                              break;
                          }
                          
                          return DropdownMenuItem<ApiType>(
                            value: value,
                            child: Text(displayText),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 名称
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '名称',
                          border: OutlineInputBorder(),
                          hintText: '未命名',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // API 地址
                      TextField(
                        controller: _apiUrlController,
                        decoration: const InputDecoration(
                          labelText: 'API 地址',
                          border: OutlineInputBorder(),
                          hintText: 'https://api.openai.com/v1',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // API 路径
                      TextField(
                        controller: _apiPathController,
                        decoration: const InputDecoration(
                          labelText: 'API 路径',
                          border: OutlineInputBorder(),
                          hintText: '/chat/completions',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // API 密钥
                      TextField(
                        controller: _apiKeyController,
                        obscureText: !_showApiKey,
                        decoration: InputDecoration(
                          labelText: 'API 密钥',
                          border: const OutlineInputBorder(),
                          hintText: '您的API密钥',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showApiKey ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _showApiKey = !_showApiKey;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 模型
                      TextField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: '模型',
                          border: OutlineInputBorder(),
                          hintText: 'gpt-4o',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 使用网络代理
                      SwitchListTile(
                        title: const Text('改善网络连接性能'),
                        subtitle: const Text('用于改善网络连接访问能力和速度'),
                        value: _useProxy,
                        onChanged: (bool value) {
                          setState(() {
                            _useProxy = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('保存配置'),
                      onPressed: _saveConfig,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 设为当前使用的配置
              if (!_isCreatingNew)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('设为当前使用的配置'),
                    onPressed: _setAsActive,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // 复制和删除按钮
              if (!_isCreatingNew)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('复制'),
                        onPressed: _duplicateConfig,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('删除'),
                        onPressed: _deleteConfig,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
} 