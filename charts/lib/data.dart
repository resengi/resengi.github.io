import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

/// Bundle of parsed CSV data passed to the chart builders.
class FinancialData {
  final List<ExpenseRow> expenses;
  FinancialData({required this.expenses});
}

/// One row from expenses.csv.
class ExpenseRow {
  final DateTime date;
  final String description;
  final String category;
  final double fullAmount;
  final double businessUsePercent;
  final double companyAmount;
  final String notes;

  ExpenseRow({
    required this.date,
    required this.description,
    required this.category,
    required this.fullAmount,
    required this.businessUsePercent,
    required this.companyAmount,
    required this.notes,
  });
}

/// Fetches the expenses CSV and returns typed rows. The path is absolute
/// so it resolves against the site root regardless of where this is mounted.
Future<FinancialData> loadFinancialData() async {
  final csvText = await _fetchCsv('/data/expenses.csv');
  return FinancialData(expenses: _parseExpenses(csvText));
}

Future<String> _fetchCsv(String path) async {
  final response = await http.get(Uri.parse(path));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch $path (status ${response.statusCode})');
  }
  return response.body;
}

List<ExpenseRow> _parseExpenses(String csvText) {
  // csv v8: `Csv()` handles `\r`, `\n`, and `\r\n` line endings automatically,
  // and `dynamicTyping` defaults to false (values come back as strings), which
  // is what we want (we parse the numeric fields explicitly below).
  final rows = Csv().decode(csvText);
  if (rows.isEmpty) return [];

  return rows
      .skip(1) // header
      .where((r) => r.length >= 6 && r[0].toString().trim().isNotEmpty)
      .map((row) => ExpenseRow(
            date: DateTime.parse(row[0].toString().trim()),
            description: row[1].toString(),
            category: row[2].toString().trim(),
            fullAmount: double.parse(row[3].toString()),
            businessUsePercent: double.parse(row[4].toString()),
            companyAmount: double.parse(row[5].toString()),
            notes: row.length > 6 ? row[6].toString() : '',
          ))
      .toList();
}