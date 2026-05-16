import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/result.dart';
import '../../providers/assignment_providers.dart';

class AssignmentSubmitScreen extends ConsumerStatefulWidget {
  const AssignmentSubmitScreen({super.key, required this.assignmentId});
  final int assignmentId;

  @override
  ConsumerState<AssignmentSubmitScreen> createState() =>
      _AssignmentSubmitScreenState();
}

class _AssignmentSubmitScreenState
    extends ConsumerState<AssignmentSubmitScreen> {
  final _textCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text =
        _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim();
    final link =
        _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim();

    if (text == null && link == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi jawaban atau link terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final result = await ref
        .read(assignmentRepositoryProvider)
        .submit(widget.assignmentId, answerText: text, answerLink: link);
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case Success():
        // Invalidate detail so parent screen refreshes on pop
        ref.invalidate(assignmentDetailProvider(widget.assignmentId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tugas berhasil dikumpulkan!')),
        );
        Navigator.of(context).pop(true);
      case FailureResult(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kumpulkan Tugas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('answer_text_field'),
              controller: _textCtrl,
              decoration: const InputDecoration(
                labelText: 'Jawaban',
                hintText: 'Tulis jawabanmu di sini...',
                border: OutlineInputBorder(),
              ),
              minLines: 4,
              maxLines: 12,
              maxLength: 10000,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('answer_link_field'),
              controller: _linkCtrl,
              decoration: const InputDecoration(
                labelText: 'Link (opsional)',
                hintText: 'https://drive.google.com/...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('submit_button'),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kumpulkan'),
            ),
          ],
        ),
      ),
    );
  }
}
