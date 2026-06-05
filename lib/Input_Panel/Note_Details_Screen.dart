import 'package:flutter/material.dart';
import 'package:notepad/Input_Panel/Note_Details_Controller.dart';
import 'Message_List.dart';

import '../Data_Base/database.dart';
import 'Input_Panel.dart';
// только сам экран, без виджетов:
class NoteDetailsScreen extends StatefulWidget {
  final Note note;
  const NoteDetailsScreen({super.key, required this.note});

  @override
  State<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {
  late NoteDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NoteDetailsController(noteId: widget.note.id, onUpdate: () => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          _controller.isSelectionMode
              ? 'Выбрано: ${_controller.selectedMessageIds.length}'
              : widget.note.content,
          style: TextStyle(
            color: _controller.isSelectionMode
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurface,
          ),
        ),
        backgroundColor: _controller.isSelectionMode
            ? colorScheme.secondaryContainer
            : (isDark ? colorScheme.surface : Colors.blue.shade100),
        elevation: 0,
        actions: [
          if (_controller.isSelectionMode) ...[
            IconButton(
              icon: Icon(
                _controller.allSelectedAreFavorite ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: _controller.toggleSelectedFavorites,
            ),
            if (_controller.selectedMessageIds.length == 1)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _controller.changeMessage(
                  context,
                  _controller.currentMessages.firstWhere(
                        (m) => m.id == _controller.selectedMessageIds.first,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _controller.deleteSelectedMessages,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MessageList(controller: _controller, noteId: widget.note.id),
          ),
          if (!_controller.isSelectionMode)
            SafeArea(child: InputPanel(controller: _controller)),
        ],
      ),
    );
  }
}