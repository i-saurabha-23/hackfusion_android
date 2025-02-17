import 'package:flutter/material.dart';
import 'package:hackfusion/admin/models/organization_data.dart';

class ScheduleTable extends StatelessWidget {
  final List<ScheduleItem> scheduleItems;

  const ScheduleTable({
    Key? key,
    required this.scheduleItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We use a Table widget for full control over borders, widths, etc.
    return Table(
      // Gives borders around each cell (horizontal + vertical)
      border: TableBorder.all(
        color: Colors.grey,
        width: 1,
      ),
      // Adjust column widths:
      // For example, the first column has a fixed width of 100,
      // and the second column expands to fill remaining space.
      columnWidths: const {
        0: FixedColumnWidth(100),
        1: FlexColumnWidth(),
      },
      children: [
        // Header Row
        TableRow(
          decoration: const BoxDecoration(color: Colors.blueAccent),
          children: [
            _buildHeaderCell("Time"),
            _buildHeaderCell("Activity"),
          ],
        ),
        // Data Rows
        ...scheduleItems.map(
              (item) => TableRow(
            children: [
              _buildDataCell(item.time),
              _buildDataCell(item.activity),
            ],
          ),
        ),
      ],
    );
  }

  // Helper to build a header cell with white, bold text.
  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper to build a regular data cell.
  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text),
    );
  }
}
