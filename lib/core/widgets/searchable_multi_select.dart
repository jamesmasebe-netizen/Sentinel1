import 'package:flutter/material.dart';

class SearchableStringMultiSelect extends StatefulWidget {
  final List<String> availableItems;
  final List<String> selectedItems;
  final void Function(List<String>) onChanged;
  final String hintText;
  final String label;
  final Map<String, String>? itemLabels;

  const SearchableStringMultiSelect({
    super.key,
    this.availableItems = const [],
    required this.selectedItems,
    required this.onChanged,
    required this.label,
    this.hintText = 'Search or add new...',
    this.itemLabels,
  });

  @override
  State<SearchableStringMultiSelect> createState() => _SearchableStringMultiSelectState();
}

class _SearchableStringMultiSelectState extends State<SearchableStringMultiSelect> {
  late List<String> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  void _showSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _SelectionDialog(
          items: widget.availableItems,
          initialSelected: _selectedItems,
          hintText: widget.hintText,
          itemLabels: widget.itemLabels,
          onApply: (selected) {
            setState(() {
              _selectedItems = selected;
            });
            widget.onChanged(_selectedItems);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._selectedItems.map((item) {
                final displayLabel = widget.itemLabels != null && widget.itemLabels!.containsKey(item)
                    ? '$item (${widget.itemLabels![item]})'
                    : item;
                return Chip(
                  label: Text(displayLabel),
                  onDeleted: () {
                    setState(() {
                      _selectedItems.remove(item);
                    });
                    widget.onChanged(_selectedItems);
                  },
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                onPressed: _showSelectionDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectionDialog extends StatefulWidget {
  final List<String> items;
  final List<String> initialSelected;
  final String hintText;
  final Map<String, String>? itemLabels;
  final void Function(List<String>) onApply;

  const _SelectionDialog({
    required this.items,
    required this.initialSelected,
    required this.hintText,
    this.itemLabels,
    required this.onApply,
  });

  @override
  State<_SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<_SelectionDialog> {
  late List<String> _selected;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addCustom() {
    final val = _searchQuery.trim();
    if (val.isNotEmpty && !_selected.contains(val)) {
      setState(() {
        _selected.add(val);
        _searchQuery = '';
        _searchCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      final displayLabel = widget.itemLabels != null && widget.itemLabels!.containsKey(item)
          ? '$item (${widget.itemLabels![item]})'
          : item;
      return displayLabel.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AlertDialog(
      title: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        onSubmitted: (_) => _addCustom(),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            if (_searchQuery.trim().isNotEmpty && !widget.items.contains(_searchQuery.trim()))
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                title: Text('Add "${_searchQuery.trim()}" as custom ID'),
                onTap: _addCustom,
              ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final displayLabel = widget.itemLabels != null && widget.itemLabels!.containsKey(item)
                      ? '$item (${widget.itemLabels![item]})'
                      : item;
                  final isSelected = _selected.contains(item);
                  return CheckboxListTile(
                    title: Text(displayLabel),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selected.add(item);
                        } else {
                          _selected.remove(item);
                        }
                      });
                    },
                  );
                },
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
        FilledButton(
          onPressed: () {
            widget.onApply(_selected);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
