import 'package:flutter/material.dart';

class SymptomChip extends StatefulWidget {
  final String label;
  final Function(bool) onSelected;
  final bool initialSelected;

  const SymptomChip({
    Key? key,
    required this.label,
    required this.onSelected,
    this.initialSelected = false,
  }) : super(key: key);

  @override
  State<SymptomChip> createState() => _SymptomChipState();
}

class _SymptomChipState extends State<SymptomChip> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(widget.label),
      selected: _isSelected,
      onSelected: (selected) {
        setState(() => _isSelected = selected);
        widget.onSelected(selected);
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: const Color(0xFFE91E63).withOpacity(0.3),
      labelStyle: TextStyle(
        color: _isSelected ? const Color(0xFFE91E63) : Colors.black,
        fontWeight: _isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _isSelected ? const Color(0xFFE91E63) : Colors.transparent,
        ),
      ),
    );
  }
}






