import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/rail_train.dart';

/// 鐵路搜尋結果狀態：null = 尚未搜尋；其餘為載入/資料/錯誤。
class RailSearchNotifier extends Notifier<AsyncValue<List<RailTrain>>?> {
  @override
  AsyncValue<List<RailTrain>>? build() => null;

  /// 查詢起訖站當日班表，並只保留 [afterTime]（HH:mm）之後的班次、依出發時間排序。
  Future<void> search({
    required RailOperator operator,
    required String fromId,
    required String toId,
    required String date,
    required String afterTime,
  }) async {
    state = const AsyncValue.loading();
    try {
      final all = await ref.read(transitRepositoryProvider).railTimetable(
            operator: operator,
            from: fromId,
            to: toId,
            date: date,
          );
      final filtered = all
          .where((t) =>
              t.departure.isNotEmpty && t.departure.compareTo(afterTime) >= 0)
          .toList()
        ..sort((a, b) => a.departure.compareTo(b.departure));
      state = AsyncValue.data(filtered);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = null;
}

final railSearchProvider =
    NotifierProvider<RailSearchNotifier, AsyncValue<List<RailTrain>>?>(
  RailSearchNotifier.new,
);
