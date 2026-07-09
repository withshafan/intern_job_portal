import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onStatusUpdate;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusUpdate,
    this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _pressController;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(widget.task.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Hero(
      tag: 'task_${widget.task.id}',
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onTapDown: (_) => _pressController.reverse(),
            onTapUp: (_) => _pressController.forward(),
            onTapCancel: () => _pressController.forward(),
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: isDark ? 0.0 : 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ── Gradient Status Bar ─────────────────────────
                  Container(
                    width: 5,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor,
                          statusColor.withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                  ),
                  // ── Content ──────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.task.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.task.isOverdue)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.shade600,
                                        Colors.red.shade400,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Overdue',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.task.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Assigned to name (admin view)
                          if (widget.task.assignedToName != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.person_outline,
                                    size: 12,
                                    color: AppTheme.primaryIndigo
                                        .withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                Text(
                                  widget.task.assignedToName!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryIndigo
                                        .withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Status chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          statusColor.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  AppTheme.statusLabel(widget.task.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Deadline
                              Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: widget.task.isOverdue
                                    ? Colors.red.shade400
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDeadline(widget.task.deadline),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.task.isOverdue
                                      ? Colors.red.shade400
                                      : Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Menu ─────────────────────────────────────────
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        color: Colors.grey.shade400, size: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    onSelected: (val) {
                      if (val == 'status') widget.onStatusUpdate?.call();
                      if (val == 'delete') widget.onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'status',
                        child: Row(children: [
                          Icon(Icons.sync_rounded,
                              size: 18, color: AppTheme.primaryIndigo),
                          const SizedBox(width: 10),
                          const Text('Update Status'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red.shade400),
                          const SizedBox(width: 10),
                          Text('Delete',
                              style: TextStyle(color: Colors.red.shade400)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDeadline(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return '${-diff}d ago';
    if (diff <= 7) return 'In ${diff}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
