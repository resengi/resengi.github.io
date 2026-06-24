import 'package:analytics_toolkit/analytics_toolkit.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

// ── Source identity ──────────────────────────────────────────────────────────

/// The analytics source id for the expenses data. Shared by the schema, the
/// record adapter, and every query spec.
const String kExpensesSourceId = 'expenses';

/// Field ids for the expenses source. Centralized so the schema, the adapter,
/// and the queries can never drift on a string literal.
abstract final class ExpenseFields {
  static const date = 'date';
  static const description = 'description';
  static const category = 'category';
  static const fullAmount = 'fullAmount';
  static const businessUsePercent = 'businessUsePercent';
  static const companyAmount = 'companyAmount';
  static const notes = 'notes';
}

FieldRef _ref(String fieldId) =>
    FieldRef(sourceId: kExpensesSourceId, fieldId: fieldId);

/// Field refs the query specs build against.
final FieldRef dateRef = _ref(ExpenseFields.date);
final FieldRef categoryRef = _ref(ExpenseFields.category);
final FieldRef companyAmountRef = _ref(ExpenseFields.companyAmount);

// ── Schema ───────────────────────────────────────────────────────────────────

/// The analytics schema for the expenses source.
///
/// `date` is the primary date field, so `TimeGroupBy` and date-range projection
/// resolve against it. `companyAmount` is the aggregatable measure the charts
/// sum; `category` is the groupable dimension.
final SourceDef expensesSource = SourceDef(
  sourceId: kExpensesSourceId,
  displayName: 'Company expenses',
  primaryDateFieldId: ExpenseFields.date,
  fields: [
    FieldDef(
      fieldId: ExpenseFields.date,
      sourceId: kExpensesSourceId,
      displayName: 'Date',
      fieldType: FieldType.dateTime,
      filterable: true,
      groupable: true,
      aggregatable: false,
      sortable: true,
    ),
    FieldDef(
      fieldId: ExpenseFields.category,
      sourceId: kExpensesSourceId,
      displayName: 'Category',
      fieldType: FieldType.enumeration,
      filterable: true,
      groupable: true,
      aggregatable: false,
      sortable: true,
    ),
    FieldDef(
      fieldId: ExpenseFields.companyAmount,
      sourceId: kExpensesSourceId,
      displayName: 'Company amount',
      fieldType: FieldType.double,
      filterable: false,
      groupable: false,
      aggregatable: true,
      sortable: true,
    ),
    // Declared for completeness; not used by the four charts.
    FieldDef(
      fieldId: ExpenseFields.fullAmount,
      sourceId: kExpensesSourceId,
      displayName: 'Full amount',
      fieldType: FieldType.double,
      filterable: false,
      groupable: false,
      aggregatable: true,
      sortable: true,
    ),
    FieldDef(
      fieldId: ExpenseFields.businessUsePercent,
      sourceId: kExpensesSourceId,
      displayName: 'Business use %',
      fieldType: FieldType.double,
      filterable: false,
      groupable: false,
      aggregatable: true,
      sortable: true,
    ),
    FieldDef(
      fieldId: ExpenseFields.description,
      sourceId: kExpensesSourceId,
      displayName: 'Description',
      fieldType: FieldType.string,
      filterable: true,
      groupable: false,
      aggregatable: false,
      sortable: false,
    ),
    FieldDef(
      fieldId: ExpenseFields.notes,
      sourceId: kExpensesSourceId,
      displayName: 'Notes',
      fieldType: FieldType.string,
      filterable: false,
      groupable: false,
      aggregatable: false,
      sortable: false,
    ),
  ],
);

// ── Row model + record adapter ────────────────────────────────────────────────

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

  /// Normalizes this row into a [SourceRecord] keyed by the source's field ids.
  SourceRecord toRecord() => SourceRecord(
    fields: {
      ExpenseFields.date: DateTimeValue(date),
      ExpenseFields.description: StringValue(description),
      ExpenseFields.category: EnumValue(category),
      ExpenseFields.fullAmount: DoubleValue(fullAmount),
      ExpenseFields.businessUsePercent: DoubleValue(businessUsePercent),
      ExpenseFields.companyAmount: DoubleValue(companyAmount),
      ExpenseFields.notes: StringValue(notes),
    },
  );
}

/// The `SourceSnapshotCache` fetcher: loads the CSV once and returns it as
/// normalized records. Signature matches `SourceSnapshotCache(fetcher: ...)`.
///
/// [dateBound] is ignored. The financials charts render the full history
/// (the scope uses `NoDateRange`), so there is no page-level window to apply.
Future<List<SourceRecord>> fetchExpenseRecords(
  String sourceId, {
  (DateTime, DateTime)? dateBound,
}) async {
  final rows = await _loadExpenseRows();
  return [for (final r in rows) r.toRecord()];
}

/// The inclusive `(earliest, latest)` date span of the expense records, used to
/// build the charts' date range. Falls back to today for both bounds when there
/// are no records, so the span is always valid.
(DateTime, DateTime) expenseDateSpan(List<SourceRecord> records) {
  DateTime? earliest;
  DateTime? latest;
  for (final record in records) {
    final value = record[ExpenseFields.date];
    if (value is! DateTimeValue) continue;
    final date = value.value;
    if (earliest == null || date.isBefore(earliest)) earliest = date;
    if (latest == null || date.isAfter(latest)) latest = date;
  }
  final now = DateTime.now();
  return (earliest ?? now, latest ?? now);
}

// ── CSV loading ──────────────────────────────────────────────────────────────

Future<List<ExpenseRow>> _loadExpenseRows() async {
  final csvText = await _fetchCsv('/data/expenses.csv');
  return _parseExpenses(csvText);
}

Future<String> _fetchCsv(String path) async {
  final response = await http.get(Uri.parse(path));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch $path (status ${response.statusCode})');
  }
  return response.body;
}

List<ExpenseRow> _parseExpenses(String csvText) {
  final rows = Csv().decode(csvText);
  if (rows.isEmpty) return [];

  return rows
      .skip(1) // header
      .where((r) => r.length >= 6 && r[0].toString().trim().isNotEmpty)
      .map(
        (row) => ExpenseRow(
          date: DateTime.parse(row[0].toString().trim()),
          description: row[1].toString(),
          category: row[2].toString().trim(),
          fullAmount: double.parse(row[3].toString()),
          businessUsePercent: double.parse(row[4].toString()),
          companyAmount: double.parse(row[5].toString()),
          notes: row.length > 6 ? row[6].toString() : '',
        ),
      )
      .toList();
}
