import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/llm_config.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../utils/l10n.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirm_dialog.dart';

class LLMSettingsScreen extends StatefulWidget {
  const LLMSettingsScreen({super.key});

  @override
  State<LLMSettingsScreen> createState() => _LLMSettingsScreenState();
}

class _LLMSettingsScreenState extends State<LLMSettingsScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<LLMConfig> _configs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    _configs = await _db.getAllLLMConfigs();
    setState(() => _isLoading = false);
  }

  Future<void> _addConfig() async {
    final result = await _showConfigDialog();
    if (result != null) { await _db.insertLLMConfig(result); await _loadConfigs(); }
  }

  Future<void> _editConfig(LLMConfig config) async {
    final result = await _showConfigDialog(existing: config);
    if (result != null) { await _db.updateLLMConfig(result); await _loadConfigs(); }
  }

  Future<void> _deleteConfig(LLMConfig config) async {
    final confirm = await ConfirmDialog.show(context, title: context.tr('删除配置', 'Delete config'), message: context.tr('确定要删除"${config.name}"吗？', 'Delete "${config.name}"?'), confirmLabel: context.tr('删除', 'Delete'), isDestructive: true);
    if (confirm == true && mounted) { await _db.deleteLLMConfig(config.id!); await _loadConfigs(); }
  }

  Future<void> _setActive(LLMConfig config) async {
    await _db.setActiveLLMConfig(config.id!);
    await _loadConfigs();
  }

  Future<LLMConfig?> _showConfigDialog({LLMConfig? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final urlController = TextEditingController(text: existing?.baseUrl ?? '');
    final keyController = TextEditingController(text: existing?.apiKey ?? '');
    final modelController = TextEditingController(text: existing?.model ?? '');

    String selectedProvider = existing?.provider ?? 'openai';

    // Provider URL defaults
    const providerUrls = {
      'openai': 'https://api.openai.com/v1/chat/completions',
      'anthropic': 'https://api.anthropic.com/v1/messages',
      'google': 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
      'deepseek': 'https://api.deepseek.com/v1/chat/completions',
      'custom': '',
    };
    const providerModels = {
      'openai': 'gpt-4o',
      'anthropic': 'claude-sonnet-4-6',
      'google': 'gemini-pro',
      'deepseek': 'deepseek-chat',
      'custom': '',
    };

    // Initialize URL if empty
    if (urlController.text.isEmpty && selectedProvider != 'custom') {
      urlController.text = providerUrls[selectedProvider] ?? '';
    }

    return showDialog<LLMConfig>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> fetchModels() async {
            final apiKey = keyController.text.trim();
            final baseUrl = urlController.text.trim();
            if (apiKey.isEmpty || baseUrl.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('请先填写API Key和API URL', 'Please fill in API Key and API URL first'))));
              return;
            }
            try {
              final fetchUrl = _getModelsUrl(selectedProvider, baseUrl, apiKey);
              final headers = _getFetchHeaders(selectedProvider, apiKey);
              final response = await http.get(Uri.parse(fetchUrl), headers: headers).timeout(const Duration(seconds: 15));
              if (response.statusCode == 200) {
                final models = _parseModelList(response.body, selectedProvider);
                if (models.isNotEmpty && context.mounted) {
                  final chosen = await showDialog<String>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(context.tr('选择模型', 'Select Model')),
                      content: SizedBox(width: double.maxFinite, height: 400, child: ListView(
                        children: models.map((m) => ListTile(title: Text(m.id ?? m.name ?? ''), onTap: () => Navigator.pop(c, m.id ?? m.name))).toList(),
                      )),
                      actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(context.tr('取消', 'Cancel')))],
                    ),
                  );
                  if (chosen != null && chosen.isNotEmpty) {
                    modelController.text = chosen;
                    setDialogState(() {});
                  }
                } else {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('未获取到模型列表', 'No models found'))));
                }
              } else {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('获取失败', 'Fetch failed')}: HTTP ${response.statusCode}')));
              }
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('获取模型列表失败', 'Failed to fetch models')}: $e')));
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(existing != null ? context.tr('编辑配置', 'Edit Config') : context.tr('添加配置', 'Add Config')),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // 1. Name
                TextField(controller: nameController, decoration: InputDecoration(labelText: context.tr('名称', 'Name'), hintText: context.tr('如: 我的GPT', 'e.g. My GPT'))),
                const SizedBox(height: 12),
                // 2. Provider dropdown
                DropdownButtonFormField<String>(
                  value: selectedProvider,
                  decoration: InputDecoration(labelText: context.tr('提供商', 'Provider')),
                  items: [
                    DropdownMenuItem(value: 'openai', child: Text(context.tr('OpenAI', 'OpenAI'))),
                    DropdownMenuItem(value: 'anthropic', child: Text(context.tr('Anthropic', 'Anthropic'))),
                    DropdownMenuItem(value: 'google', child: Text(context.tr('Google', 'Google'))),
                    DropdownMenuItem(value: 'deepseek', child: Text(context.tr('DeepSeek', 'DeepSeek'))),
                    DropdownMenuItem(value: 'custom', child: Text(context.tr('自定义', 'Custom'))),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setDialogState(() {
                      selectedProvider = v;
                      if (urlController.text.isEmpty || providerUrls.containsKey(v)) {
                        urlController.text = providerUrls[v] ?? '';
                      }
                      // Model left empty by default — user fills in or uses Fetch button
                    });
                  },
                ),
                const SizedBox(height: 12),
                // 3. API URL
                TextField(controller: urlController, decoration: InputDecoration(labelText: context.tr('API URL', 'API URL'), hintText: context.tr('输入API地址', 'Enter API URL'))),
                const SizedBox(height: 8),
                // 4. API Key
                TextField(controller: keyController, decoration: InputDecoration(labelText: context.tr('API Key', 'API Key'), hintText: context.tr('输入API密钥', 'Enter API key')), obscureText: true),
                const SizedBox(height: 8),
                // 5. Model with fetch button
                Row(children: [
                  Expanded(child: TextField(controller: modelController, decoration: InputDecoration(labelText: context.tr('模型', 'Model'), hintText: context.tr('输入模型名', 'Enter model name')))),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: fetchModels,
                      icon: const Icon(Icons.download, size: 16),
                      label: Text(context.tr('获取模型', 'Fetch')),
                    ),
                  ),
                ]),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('取消', 'Cancel'))),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty || keyController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('请填写名称和API Key', 'Please fill in Name and API Key'))));
                    return;
                  }
                  Navigator.pop(ctx, LLMConfig(
                    id: existing?.id,
                    name: nameController.text.trim(),
                    provider: selectedProvider,
                    apiKey: keyController.text.trim(),
                    model: modelController.text.trim(),
                    baseUrl: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
                    isActive: existing?.isActive ?? false,
                  ));
                },
                child: Text(context.tr('保存', 'Save')),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getModelsUrl(String provider, String baseUrl, String apiKey) {
    switch (provider) {
      case 'google':
        return 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
      case 'anthropic':
        return 'https://api.anthropic.com/v1/models?limit=100';
      case 'deepseek':
      case 'openai':
      default:
        // OpenAI-compatible endpoint: replace /chat/completions with /models
        final base = baseUrl.replaceAll('/chat/completions', '').replaceAll('/messages', '');
        return '$base/models';
    }
  }

  Map<String, String> _getFetchHeaders(String provider, String apiKey) {
    switch (provider) {
      case 'anthropic':
        return {'x-api-key': apiKey, 'anthropic-version': '2023-06-01'};
      case 'google':
        return {};
      default:
        return {'Authorization': 'Bearer $apiKey'};
    }
  }

  List<_ModelInfo> _parseModelList(String body, String provider) {
    try {
      final data = jsonDecode(body);
      switch (provider) {
        case 'google':
          final models = data['models'] as List? ?? [];
          return models.map((m) => _ModelInfo(name: (m['name']?.toString() ?? '').replaceAll('models/', ''))).where((m) => (m.name ?? '').isNotEmpty).toList();
        case 'anthropic':
          final models = data['data'] as List? ?? [];
          return models.map((m) => _ModelInfo(id: m['id']?.toString() ?? '', name: m['display_name']?.toString() ?? '')).toList();
        default:
          // OpenAI-compatible
          final models = data['data'] as List? ?? [];
          return models.map((m) => _ModelInfo(id: m['id']?.toString() ?? '')).toList();
      }
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('LLM 设置', 'LLM Settings')), actions: [IconButton(icon: const Icon(Icons.add), onPressed: _addConfig)]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _configs.isEmpty
              ? EmptyState(icon: Icons.smart_toy_outlined, title: context.t('还没有AI配置', 'No AI config'), subtitle: context.t('添加LLM配置以使用AI导入功能', 'Add LLM config for AI import'), actionLabel: context.t('添加配置', 'Add Config'), onAction: _addConfig)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _configs.length,
                  itemBuilder: (context, index) {
                    final c = _configs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
                          side: c.isActive ? const BorderSide(color: AppConstants.successColor, width: 2) : BorderSide.none),
                      child: ExpansionTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        leading: Container(width: 40, height: 40,
                          decoration: BoxDecoration(color: AppConstants.primaryColor.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.smart_toy, color: AppConstants.primaryColor, size: 20)),
                        title: Row(children: [
                          Expanded(child: Text(c.name)),
                          if (c.isActive) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppConstants.successColor.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                            child: Text(context.t('使用中', 'Active'), style: const TextStyle(color: AppConstants.successColor, fontSize: 12))),
                        ]),
                        subtitle: Text('${c.provider} · ${c.model}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              if (!c.isActive) OutlinedButton(onPressed: () => _setActive(c), child: Text(context.t('启用', 'Activate'))),
                              const SizedBox(width: 8),
                              OutlinedButton(onPressed: () => _editConfig(c), child: Text(context.t('编辑', 'Edit'))),
                              const SizedBox(width: 8),
                              OutlinedButton(onPressed: () => _deleteConfig(c),
                                style: OutlinedButton.styleFrom(foregroundColor: AppConstants.errorColor), child: Text(context.t('删除', 'Delete'))),
                            ]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _ModelInfo {
  final String? id;
  final String? name;
  _ModelInfo({this.id, this.name});
}
