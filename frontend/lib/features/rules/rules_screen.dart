import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/rule.dart';
import '../../core/auth/user_provider.dart';
import '../../core/api/api_client_provider.dart';
import 'rules_provider.dart';

/// Rules screen with list and editor.
///
/// Features:
/// - List view showing all user rules (name, presetId, createdAt)
/// - Create Rule button (disabled when quota reached)
/// - Edit/Delete buttons for each rule
/// - Quota enforcement (Free: 2, Pro: 20)
///
/// Flow:
/// 1. Screen mounts → rulesProvider fetches GET /rules
/// 2. Shows loading spinner during fetch
/// 3. Displays rule list with edit/delete actions
/// 4. Create button opens modal form for new rule
/// 5. Edit button opens modal form with existing rule data
/// 6. Delete button shows confirmation dialog
///
/// The screen enforces rule quota based on user plan.
class RulesScreen extends ConsumerStatefulWidget {
  final String? jobId;
  final String? presetId;

  const RulesScreen({
    super.key,
    this.jobId,
    this.presetId,
  });

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  /// Shows create or edit rule dialog
  Future<void> _showRuleDialog({Rule? rule}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _RuleEditorDialog(
        presetId: widget.presetId ?? 'interior',
        rule: rule,
      ),
    );

    // Refresh rules list if rule was saved
    if (result == true) {
      ref.invalidate(rulesProvider);
      ref.invalidate(userProvider);
    }
  }

  /// Shows delete confirmation dialog
  Future<void> _confirmDelete(Rule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: Text('Are you sure you want to delete "${rule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(rulesProvider.notifier).deleteRule(rule.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rule "${rule.name}" deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Refresh user quota
        ref.invalidate(userProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete rule: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(rulesProvider);
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rules'),
        centerTitle: true,
        actions: [
          // Show quota info in app bar
          userAsync.when(
            data: (user) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  '${user.ruleSlots}/${(user.plan == 'pro' ? 20 : 2)} rules',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: rulesAsync.when(
              // Loading state
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),

              // Error state
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to Load Rules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(rulesProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),

              // Data state
              data: (rules) {
                if (rules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.rule_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No rules yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create your first rule to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        userAsync.when(
                          data: (user) => ElevatedButton.icon(
                            onPressed: user.ruleSlots >= (user.plan == 'pro' ? 20 : 2)
                                ? null
                                : () => _showRuleDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Rule'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          const Text(
                            'Your Rules',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Manage your concept transformation rules',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Rules list
                          ...rules.map((rule) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _RuleCard(
                                  rule: rule,
                                  onEdit: () => _showRuleDialog(rule: rule),
                                  onDelete: () => _confirmDelete(rule),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Continue to jobs button (if jobId provided)
                    if (widget.jobId != null)
                      TextButton.icon(
                        onPressed: () {
                          context.push('/jobs/${widget.jobId}');
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continue to Job'),
                      )
                    else
                      const SizedBox.shrink(),

                    // Create Rule button
                    userAsync.when(
                      data: (user) {
                        final quotaReached =
                            user.ruleSlots >= (user.plan == 'pro' ? 20 : 2);
                        return ElevatedButton.icon(
                          onPressed: quotaReached ? null : () => _showRuleDialog(),
                          icon: const Icon(Icons.add),
                          label: Text(
                            quotaReached
                                ? 'Quota Reached (${(user.plan == 'pro' ? 20 : 2)})'
                                : 'Create Rule',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        );
                      },
                      loading: () => const ElevatedButton(
                        onPressed: null,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, __) => ElevatedButton.icon(
                        onPressed: () => _showRuleDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Rule'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual rule card widget.
class _RuleCard extends StatelessWidget {
  final Rule rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.rule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rule icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.rule,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Rule details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Preset: ${rule.presetId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${_formatDate(rule.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (rule.concepts != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: rule.concepts!.entries
                              .map(
                                (entry) => Chip(
                                  label: Text(
                                    '${entry.key}: ${entry.value.action}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action buttons
                Column(
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit',
                      color: Colors.blue,
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete',
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}

/// Rule editor dialog for creating/editing rules.
class _RuleEditorDialog extends ConsumerStatefulWidget {
  final String presetId;
  final Rule? rule;

  const _RuleEditorDialog({
    required this.presetId,
    this.rule,
  });

  @override
  ConsumerState<_RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends ConsumerState<_RuleEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final Map<String, ConceptAction> _concepts = {};
  final Set<String> _protect = {};
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _availableConcepts = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule?.name ?? '');

    // Initialize with existing rule data if editing
    if (widget.rule != null) {
      if (widget.rule!.concepts != null) {
        _concepts.addAll(widget.rule!.concepts!);
      }
      if (widget.rule!.protect != null) {
        _protect.addAll(widget.rule!.protect!);
      }
    }

    // Fetch preset details to get available concepts
    _loadPresetConcepts();
  }

  Future<void> _loadPresetConcepts() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final preset = await apiClient.getPresetById(widget.presetId);
      if (mounted) {
        setState(() {
          _availableConcepts = preset.concepts ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load concepts: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_concepts.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one concept action';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.rule == null) {
        // Create new rule
        await ref.read(rulesProvider.notifier).createRule(
              name: _nameController.text,
              presetId: widget.presetId,
              concepts: _concepts,
              protect: _protect.toList(),
            );
      } else {
        // Update existing rule
        await ref.read(rulesProvider.notifier).updateRule(
              widget.rule!.id,
              name: _nameController.text,
              concepts: _concepts,
              protect: _protect.toList(),
            );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save rule: $e';
        _isLoading = false;
      });
    }
  }

  void _addConceptAction() {
    showDialog(
      context: context,
      builder: (context) => _AddConceptActionDialog(
        availableConcepts: _availableConcepts,
        existingConcepts: _concepts.keys.toList(),
        onAdd: (concept, action) {
          setState(() {
            _concepts[concept] = action;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                widget.rule == null ? 'Create Rule' : 'Edit Rule',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Rule Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Concept actions section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Concept Actions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _addConceptAction,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Concept actions list
                        if (_concepts.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'No concept actions added yet',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ...(_concepts.entries.map((entry) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.extension),
                                  title: Text(entry.key),
                                  subtitle: Text(
                                    '${entry.value.action}${entry.value.value != null ? ': ${entry.value.value}' : ''}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _concepts.remove(entry.key);
                                      });
                                    },
                                  ),
                                ),
                              ))),

                        const SizedBox(height: 24),

                        // Protected concepts section
                        const Text(
                          'Protected Concepts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select concepts to protect from transformations',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Protected concepts chips
                        if (_availableConcepts.isEmpty)
                          const Center(child: CircularProgressIndicator())
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableConcepts.map((concept) {
                              final isProtected = _protect.contains(concept);
                              return FilterChip(
                                label: Text(concept),
                                selected: isProtected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _protect.add(concept);
                                    } else {
                                      _protect.remove(concept);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.rule == null ? 'Create' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for adding a concept action.
class _AddConceptActionDialog extends StatefulWidget {
  final List<String> availableConcepts;
  final List<String> existingConcepts;
  final Function(String concept, ConceptAction action) onAdd;

  const _AddConceptActionDialog({
    required this.availableConcepts,
    required this.existingConcepts,
    required this.onAdd,
  });

  @override
  State<_AddConceptActionDialog> createState() =>
      _AddConceptActionDialogState();
}

class _AddConceptActionDialogState extends State<_AddConceptActionDialog> {
  String? _selectedConcept;
  String _selectedAction = 'recolor';
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableConcepts = widget.availableConcepts
        .where((c) => !widget.existingConcepts.contains(c))
        .toList();

    return AlertDialog(
      title: const Text('Add Concept Action'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Concept dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Concept',
                border: OutlineInputBorder(),
              ),
              items: availableConcepts
                  .map((concept) => DropdownMenuItem(
                        value: concept,
                        child: Text(concept),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedConcept = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Action dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedAction,
              decoration: const InputDecoration(
                labelText: 'Action',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'recolor', child: Text('Recolor')),
                DropdownMenuItem(value: 'tone', child: Text('Tone')),
                DropdownMenuItem(value: 'texture', child: Text('Texture')),
                DropdownMenuItem(value: 'remove', child: Text('Remove')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAction = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Value field (for recolor, tone, texture)
            if (_selectedAction != 'remove')
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Value (e.g., oak_a, warm)',
                  border: OutlineInputBorder(),
                  hintText: 'Optional',
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedConcept == null
              ? null
              : () {
                  final value = _valueController.text.trim();
                  widget.onAdd(
                    _selectedConcept!,
                    ConceptAction(
                      action: _selectedAction,
                      value: value.isEmpty ? null : value,
                    ),
                  );
                  Navigator.of(context).pop();
                },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
