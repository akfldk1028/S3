import chokidar, { type FSWatcher } from 'chokidar';
import { readFileSync, existsSync } from 'fs';
import type { BrowserWindow } from 'electron';
import { fileWatcher } from './file-watcher';
import { safeSendToRenderer } from './ipc-handlers/utils';
import { IPC_CHANNELS } from '../shared/constants';

interface DaemonTaskInfo {
  spec_id: string;
  spec_dir: string;
  pid: number;
  status: string;
  started_at: string;
  last_update: string;
  is_running: boolean;
  task_type: string;
}

interface DaemonStatus {
  running: boolean;
  running_tasks: Record<string, DaemonTaskInfo>;
  queued_tasks: Array<{ spec_id: string; priority: number }>;
  stats: { running: number; queued: number; completed: number };
  timestamp: string;
}

const daemonManagedTasks = new Map<string, string>();

/**
 * Check if a task is currently managed by the daemon process.
 * Used as fallback when agentManager.isRunning() returns false.
 */
export function isDaemonManaged(taskId: string): boolean {
  return daemonManagedTasks.has(taskId);
}

/**
 * Watches daemon_status.json and bridges daemon-managed tasks
 * to the existing fileWatcher/IPC pipeline so the UI auto-updates.
 *
 * Key design decisions:
 * - Re-sends status for ALL running tasks on every processFile call (every 10s)
 *   because the initial event may arrive before the renderer is ready.
 *   The task store deduplicates identical status updates, so no wasted renders.
 * - Sends TASK_STATUS_CHANGE for transitions (start/stop) immediately.
 * - Uses fileWatcher for implementation_plan.json progress updates.
 */
export class DaemonStatusWatcher {
  private watcher: FSWatcher | null = null;
  private watchedTasks = new Set<string>();
  private getMainWindow: (() => BrowserWindow | null) | null = null;
  private projectId: string | null = null;
  private previousRunningIds = new Set<string>();
  private previousCompleted = 0;
  private rendererReady = false;
  private readyTimer: ReturnType<typeof setTimeout> | null = null;

  start(
    statusFilePath: string,
    getMainWindow?: () => BrowserWindow | null,
    projectId?: string,
  ): void {
    this.stop();
    if (!existsSync(statusFilePath)) return;

    this.getMainWindow = getMainWindow ?? null;
    this.projectId = projectId ?? null;
    this.rendererReady = false;

    // Delay initial processing to let renderer mount first
    this.readyTimer = setTimeout(() => {
      this.rendererReady = true;
      this.processFile(statusFilePath);
    }, 5000);

    this.watcher = chokidar.watch(statusFilePath, {
      persistent: true,
      ignoreInitial: true,
      awaitWriteFinish: { stabilityThreshold: 500, pollInterval: 200 },
    });
    this.watcher.on('change', () => this.processFile(statusFilePath));
    this.watcher.on('add', () => this.processFile(statusFilePath));
  }

  stop(): void {
    if (this.readyTimer) {
      clearTimeout(this.readyTimer);
      this.readyTimer = null;
    }
    this.watcher?.close();
    this.watcher = null;
    for (const specId of this.watchedTasks) {
      fileWatcher.unwatch(specId);
    }
    this.watchedTasks.clear();
    daemonManagedTasks.clear();
    this.previousRunningIds.clear();
    this.previousCompleted = 0;
    this.rendererReady = false;
  }

  private processFile(statusPath: string): void {
    let status: DaemonStatus;
    try {
      const content = readFileSync(statusPath, 'utf-8');
      const clean = content.charCodeAt(0) === 0xFEFF ? content.slice(1) : content;
      status = JSON.parse(clean);
    } catch {
      return;
    }

    if (!status.running) {
      this.stop();
      return;
    }

    const currentIds = new Set<string>();
    for (const [specId, info] of Object.entries(status.running_tasks || {})) {
      currentIds.add(specId);
      daemonManagedTasks.set(specId, info.last_update || '');

      // Always re-send status for running tasks so renderer stays in sync.
      // The task store deduplicates identical updates (no wasted re-renders).
      if (this.rendererReady) {
        this.sendStatusChange(specId, 'in_progress');
      }

      // Start file watcher for plan progress (leverages existing IPC pipeline)
      if (!this.watchedTasks.has(specId) && !fileWatcher.isWatching(specId)) {
        if (existsSync(info.spec_dir)) {
          fileWatcher.watch(specId, info.spec_dir);
          this.watchedTasks.add(specId);
        }
      }
    }

    // Tasks that were running but are no longer → completed or stopped
    for (const specId of this.previousRunningIds) {
      if (!currentIds.has(specId)) {
        if (status.stats.completed > this.previousCompleted) {
          this.sendStatusChange(specId, 'human_review');
        } else {
          this.sendStatusChange(specId, 'error');
        }
      }
    }

    // Cleanup tasks no longer running in daemon
    for (const specId of [...this.watchedTasks]) {
      if (!currentIds.has(specId)) {
        fileWatcher.unwatch(specId);
        this.watchedTasks.delete(specId);
        daemonManagedTasks.delete(specId);
      }
    }

    // Update state for next comparison
    this.previousRunningIds = currentIds;
    this.previousCompleted = status.stats.completed;
  }

  private sendStatusChange(specId: string, status: string): void {
    if (!this.getMainWindow) return;
    console.log(`[DaemonStatusWatcher] Task ${specId} → ${status}`);
    safeSendToRenderer(
      this.getMainWindow,
      IPC_CHANNELS.TASK_STATUS_CHANGE,
      specId,
      status,
      this.projectId,
    );
  }
}

export const daemonStatusWatcher = new DaemonStatusWatcher();
