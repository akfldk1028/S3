import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client_provider.dart';
import '../../core/models/preset.dart';
import 'palette_provider.dart';

/// Palette (concept selection) screen.
///
/// Allows users to:
/// 1. Select concepts from the chosen preset (via chips)
/// 2. Choose instance number (#1-#N) for each selected concept
/// 3. Toggle "protect" flag to prevent modifications
/// 4. Proceed to upload screen with selected state
///
/// Flow:
/// 1. Receives presetId via route query parameter
/// 2. Fetches preset detail (GET /presets/{id}) to get concepts list
/// 3. User toggles concept chips on/off
/// 4. For selected concepts, shows instance selector and protect toggle
/// 5. "Next" button navigates to /upload with palette state
///
/// The palette state (selectedConcepts, protectConcepts) is managed by
/// PaletteProvider and passed to the upload screen for job configuration.
class PaletteScreen extends ConsumerWidget {
  final String? presetId;

  const PaletteScreen({
    super.key,
    this.presetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Validate presetId
    if (presetId == null || presetId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Select Concepts'),
        ),
        body: Center(
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
                'No preset selected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/domain-select');
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Domains'),
              ),
            ],
          ),
        ),
      );
    }

    final apiClient = ref.watch(apiClientProvider);
    final paletteState = ref.watch(paletteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Concepts'),
        centerTitle: true,
        actions: [
          // Reset button to clear all selections
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset selections',
            onPressed: () {
              ref.read(paletteProvider.notifier).reset();
            },
          ),
        ],
      ),
      body: FutureBuilder<Preset>(
        // Fetch preset detail to get concepts list
        future: apiClient.getPresetById(presetId!),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
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
                    'Failed to Load Preset',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate back to domain select
                      context.go('/domain-select');
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Domains'),
                  ),
                ],
              ),
            );
          }

          // Data state
          final preset = snapshot.data!;
          final concepts = preset.concepts ?? [];

          if (concepts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No concepts available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Main content area with concept chips
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Text(
                            preset.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select concepts to modify in your images',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Concept chips section
                          const Text(
                            'Available Concepts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: concepts.map((concept) {
                              final isSelected = paletteState.selectedConcepts.containsKey(concept);
                              return _ConceptChip(
                                concept: concept,
                                isSelected: isSelected,
                                onTap: () {
                                  ref.read(paletteProvider.notifier).toggleConcept(concept);
                                },
                              );
                            }).toList(),
                          ),

                          // Selected concepts configuration section
                          if (paletteState.selectedConcepts.isNotEmpty) ...[
                            const SizedBox(height: 40),
                            const Divider(),
                            const SizedBox(height: 24),
                            const Text(
                              'Configure Selected Concepts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...paletteState.selectedConcepts.entries.map((entry) {
                              final conceptName = entry.key;
                              final instanceIndex = entry.value;
                              final isProtected = paletteState.protectConcepts.contains(conceptName);

                              return _ConceptControl(
                                conceptName: conceptName,
                                instanceIndex: instanceIndex,
                                isProtected: isProtected,
                                onInstanceChanged: (newIndex) {
                                  ref.read(paletteProvider.notifier).setInstance(conceptName, newIndex);
                                },
                                onProtectToggled: () {
                                  ref.read(paletteProvider.notifier).toggleProtect(conceptName);
                                },
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom action bar with Next button
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
                        // Selection count
                        Text(
                          '${paletteState.selectedConcepts.length} concept(s) selected',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        // Next button
                        ElevatedButton.icon(
                          onPressed: paletteState.selectedConcepts.isEmpty
                              ? null
                              : () {
                                  // Navigate to upload screen
                                  context.push('/upload?presetId=$presetId');
                                },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next: Upload Images'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Individual concept chip widget.
///
/// Displays a chip for a concept that can be toggled on/off.
/// Selected chips are highlighted with primary color.
class _ConceptChip extends StatelessWidget {
  final String concept;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConceptChip({
    required this.concept,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        concept,
        style: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

/// Control widget for a selected concept.
///
/// Shows:
/// - Concept name
/// - Instance selector dropdown (#1-#N)
/// - Protect toggle switch
class _ConceptControl extends StatelessWidget {
  final String conceptName;
  final int instanceIndex;
  final bool isProtected;
  final Function(int) onInstanceChanged;
  final VoidCallback onProtectToggled;

  // Maximum number of instances available per concept
  static const int maxInstances = 5;

  const _ConceptControl({
    required this.conceptName,
    required this.instanceIndex,
    required this.isProtected,
    required this.onInstanceChanged,
    required this.onProtectToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Concept name
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    conceptName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Instance selector
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Text(
                    'Instance:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: instanceIndex,
                    underline: Container(),
                    items: List.generate(maxInstances, (index) {
                      final instanceNum = index + 1;
                      return DropdownMenuItem(
                        value: instanceNum,
                        child: Text('#$instanceNum'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        onInstanceChanged(value);
                      }
                    },
                  ),
                ],
              ),
            ),

            // Protect toggle
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Protect',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isProtected,
                    onChanged: (_) => onProtectToggled(),
                    activeTrackColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
