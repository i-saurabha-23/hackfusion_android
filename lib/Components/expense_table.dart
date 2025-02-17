import 'package:flutter/material.dart';
import 'package:hackfusion/admin/models/organization_data.dart';

class ExpenseTable extends StatelessWidget {
  final List<ExpenseItem> expenseItems;

  const ExpenseTable({
    Key? key,
    required this.expenseItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(
        color: Colors.grey,
        width: 1,
      ),
      columnWidths: const {
        0: FixedColumnWidth(150), // Adjust as needed
        1: FlexColumnWidth(),
      },
      children: [
        // Header Row
        TableRow(
          decoration: const BoxDecoration(color: Colors.blueAccent),
          children: [
            _buildHeaderCell("Expense Name"),
            _buildHeaderCell("Expected Cost"),
          ],
        ),
        // Data Rows
        ...expenseItems.map(
          (item) => TableRow(
            children: [
              _buildDataCell(item.name),
              _buildDataCell("\$${item.expectedCost.toStringAsFixed(2)}"),
            ],
          ),
        ),
      ],
    );
  }

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

  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text),
    );
  }
}
