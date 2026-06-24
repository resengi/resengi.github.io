import 'package:analytics_toolkit/analytics_toolkit.dart';

import 'data.dart';

/// The four financial-chart queries, expressed against the expenses source.
///
/// Each is a [SingleQuerySpec] wrapping an [AnalyticsQuerySpec] that the bridge
/// widgets run and map to chart data. All four aggregate `companyAmount`, the
/// business-use portion of each expense.

/// 1. Monthly company expenses: stacked bar, one segment per category per
/// month. Two group-bys (month primary → x axis, category secondary → stacked
/// segments) over one measure yields a `MultiSeriesResult`.
SingleQuerySpec monthlyExpensesQuery() => SingleQuerySpec(
  query: AnalyticsQuerySpec(
    source: kExpensesSourceId,
    measures: [
      FieldMeasure(
        fieldRef: companyAmountRef,
        aggregation: const SumAgg(),
        label: 'Company amount',
      ),
    ],
    groupBys: [
      TimeGroupBy(dateFieldRef: dateRef, grain: TimeGrain.month),
      FieldGroupBy(fieldRef: categoryRef),
    ],
  ),
);

/// 2. Total spend by category: single bar per category, sorted by value
/// descending. One group-by + one measure yields a `SeriesResult`.
SingleQuerySpec categoryTotalsQuery() => SingleQuerySpec(
  query: AnalyticsQuerySpec(
    source: kExpensesSourceId,
    measures: [
      FieldMeasure(
        fieldRef: companyAmountRef,
        aggregation: const SumAgg(),
        label: 'Company amount',
      ),
    ],
    groupBys: [FieldGroupBy(fieldRef: categoryRef)],
    sort: Sort(
      target: const MeasureValueSort(),
      direction: SortDirection.descending,
    ),
  ),
);

/// 3. Cumulative spend: running total by month, via `CumulativeSumOp`.
SingleQuerySpec cumulativeSpendQuery() => SingleQuerySpec(
  query: AnalyticsQuerySpec(
    source: kExpensesSourceId,
    measures: [
      FieldMeasure(
        fieldRef: companyAmountRef,
        aggregation: const SumAgg(),
        label: 'Company amount',
      ),
    ],
    groupBys: [TimeGroupBy(dateFieldRef: dateRef, grain: TimeGrain.month)],
    derivedOperation: const CumulativeSumOp(),
  ),
);

/// 4. Company books: running net by month.
///
/// Net is the negated running spend: each month's summed spend is negated by
/// `NegateOp`, then accumulated by `CumulativeSumOp`. The line trends downward,
/// and its signed values draw against a zero-crossing axis.
SingleQuerySpec companyBooksQuery() => SingleQuerySpec(
  query: AnalyticsQuerySpec(
    source: kExpensesSourceId,
    measures: [
      TransformedMeasure(
        operand: FieldMeasure(
          fieldRef: companyAmountRef,
          aggregation: const SumAgg(),
        ),
        op: const NegateOp(),
        label: 'Company net',
      ),
    ],
    groupBys: [TimeGroupBy(dateFieldRef: dateRef, grain: TimeGrain.month)],
    derivedOperation: const CumulativeSumOp(),
  ),
);
