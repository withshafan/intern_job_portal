import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../providers/auth_provider.dart' as app_auth;

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  final TextEditingController _commentCtrl = TextEditingController();
  bool _sendingComment = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final auth = context.read<app_auth.AuthProvider>();
    final name = auth.currentUser?.name ?? user.email ?? 'User';

    setState(() => _sendingComment = true);
    await _taskService.addComment(
      taskId: widget.task.id,
      text: text,
      authorId: user.uid,
      authorName: name,
    );
    _commentCtrl.clear();
    setState(() => _sendingComment = false);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(widget.task.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
      ),
      body: Column(
        children: [
          // ── Task Info ──────────────────────────────────────────
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Hero(
                    tag: 'task_${widget.task.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Status
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.task.title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    AppTheme.statusLabel(widget.task.status),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Meta info
                            _metaRow(
                              Icons.calendar_today_outlined,
                              'Deadline',
                              '${widget.task.deadline.day}/${widget.task.deadline.month}/${widget.task.deadline.year}',
                              widget.task.isOverdue ? Colors.red : null,
                            ),
                            const SizedBox(height: 8),
                            _metaRow(
                              Icons.access_time,
                              'Created',
                              '${widget.task.createdAt.day}/${widget.task.createdAt.month}/${widget.task.createdAt.year}',
                            ),
                            if (widget.task.assignedToName != null) ...[
                              const SizedBox(height: 8),
                              _metaRow(
                                Icons.person_outline,
                                'Assigned To',
                                widget.task.assignedToName!,
                              ),
                            ],
                            const SizedBox(height: 20),

                            // Description
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkCard
                                    : AppTheme.lightBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.task.description,
                                style: TextStyle(
                                  height: 1.6,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Comments header
                            const Text(
                              'Comments',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Comments Stream ────────────────────────────
                StreamBuilder<List<TaskComment>>(
                  stream: _taskService.getComments(widget.task.id),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }
                    final comments = snap.data ?? [];
                    if (comments.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'No comments yet. Be the first!',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final c = comments[i];
                          final isMe = c.authorId ==
                              FirebaseAuth.instance.currentUser?.uid;
                          return _commentBubble(c, isMe);
                        },
                        childCount: comments.length,
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          // ── Comment Input ──────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add a comment…',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _sendingComment
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child:
                            CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : IconButton.filled(
                        onPressed: _sendComment,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primaryIndigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value,
      [Color? valueColor]) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _commentBubble(TaskComment comment, bool isMe) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryIndigo.withValues(alpha: 0.1),
              child: Text(
                comment.authorName[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryIndigo,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      comment.authorName,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryIndigo),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppTheme.primaryIndigo
                        : Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkCard
                            : const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    comment.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : null,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
