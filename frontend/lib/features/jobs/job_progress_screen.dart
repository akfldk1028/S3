import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client_provider.dart';
import '../../core/models/job.dart';
import '../workspace/theme.dart';

/// Job progress screen with 3-second polling.
///
/// Flow:
/// 1. Mounts → GET /jobs/:id (initial fetch)
/// 2. Starts 3-second polling timer
/// 3. Shows progress bar based on doneItems/totalItems
/// 4. Status chip: created → queued → running → done/failed/canceled
/// 5. Done → "View Results" button
/// 6. Failed → "Retry" + error message
/// 7. Cancel button available while running
class JobProgressScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobProgressScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobProgressScreen> createState() => _JobProgressScreenState();
}

class _JobProgressScreenState extends ConsumerState<JobProgressScreen> {
  Timer? _pollTimer;
  Job? _job;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchJob();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_job != null && _isTerminal(_job!.status)) {
        _pollTimer?.cancel();
        return;
      }
      _fetchJob();
    });
  }

  bool _isTerminal(String status) {
    return status == 'done' || status == 'failed' || status == 'canceled';
  }

  Future<void> _fetchJob() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final job = await apiClient.getJob(widget.jobId);
      if (mounted) {
        setState(() {
          _job = job;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _cancelJob() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.cancelJob(widget.jobId);
      await _fetchJob();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancel failed: $e')),
        );
      }
    }
  }

  double get _progress {
    if (_job == null || _job!.totalItems == 0) return 0.0;
    return _job!.doneItems / _job!.totalItems;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'canceled':
        return Colors.orange;
      case 'running':
        return WsColors.accent1;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'done':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'canceled':
        return Icons.cancel;
      case 'running':
        return Icons.sync;
      case 'queued':
        return Icons.hourglass_empty;
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Progress'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading && _job == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _job == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Failed to Load Job',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchJob,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final job = _job!;
    final status = job.status;
    final isDone = status == 'done';
    final isFailed = status == 'failed';
    final isCanceled = status == 'canceled';
    final isRunning = status == 'running' || status == 'queued';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status icon
              Icon(
                _statusIcon(status),
                size: 72,
                color: _statusColor(status),
              ),
              const SizedBox(height: 24),

              // Status text
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _statusColor(status),
                ),
              ),
              const SizedBox(height: 8),

              // Job ID
              Text(
                'Job: ${job.jobId}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Progress bar
              if (!isCanceled) ...[
                LinearProgressIndicator(
                  value: isDone ? 1.0 : _progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                  color: _statusColor(status),
                  backgroundColor: Colors.grey.shade200,
                ),
                const SizedBox(height: 12),
                Text(
                  '${job.doneItems} / ${job.totalItems} items${job.failedItems > 0 ? ' (${job.failedItems} failed)' : ''}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toInt()}% complete',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],

              const SizedBox(height: 40),

              // Action buttons
              if (isDone)
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),

              if (isFailed) ...[
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],

              if (isRunning) ...[
                OutlinedButton.icon(
                  onPressed: _cancelJob,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Job'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],

              if (isCanceled)
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
