import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../data/models/rail_train.dart';
import '../../data/rail_stations.dart';
import 'rail_search_controller.dart';

/// 鐵路（台鐵/高鐵）起訖站時刻查詢頁。
class RailSearchPage extends ConsumerStatefulWidget {
  const RailSearchPage({super.key});

  @override
  ConsumerState<RailSearchPage> createState() => _RailSearchPageState();
}

class _RailSearchPageState extends ConsumerState<RailSearchPage> {
  RailOperator _operator = RailOperator.tra;
  late RailStation _from;
  late RailStation _to;
  late DateTime _date;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _time = TimeOfDay.now(); // 開啟時預設帶入目前時間
    _applyDefaultStations();
  }

  /// 依目前營運商給定合理的預設起訖站。
  void _applyDefaultStations() {
    final list = stationsFor(_operator);
    RailStation byName(String name, RailStation fallback) =>
        list.firstWhere((s) => s.name == name, orElse: () => fallback);
    _from = byName('台北', list.first);
    _to = byName(_operator == RailOperator.thsr ? '左營' : '台中', list.last);
  }

  void _onOperatorChanged(RailOperator op) {
    setState(() {
      _operator = op;
      _applyDefaultStations();
    });
    ref.read(railSearchProvider.notifier).reset();
  }

  void _swap() => setState(() {
        final t = _from;
        _from = _to;
        _to = t;
      });

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  String get _dateStr => '${_date.year}-${_two(_date.month)}-${_two(_date.day)}';
  String get _timeStr => '${_two(_time.hour)}:${_two(_time.minute)}';

  void _search() {
    if (_from.id == _to.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('起點與終點不能相同')),
      );
      return;
    }
    ref.read(railSearchProvider.notifier).search(
          operator: _operator,
          fromId: _from.id,
          toId: _to.id,
          date: _dateStr,
          afterTime: _timeStr,
        );
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(railSearchProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        title: const Text('台鐵 / 高鐵時刻'),
      ),
      body: Column(
        children: [
          _searchCard(),
          Expanded(child: _results(result)),
        ],
      ),
    );
  }

  Widget _searchCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          SegmentedButton<RailOperator>(
            segments: const [
              ButtonSegment(
                  value: RailOperator.tra,
                  label: Text('台鐵'),
                  icon: Icon(Icons.train)),
              ButtonSegment(
                  value: RailOperator.thsr,
                  label: Text('高鐵'),
                  icon: Icon(Icons.directions_railway)),
            ],
            selected: {_operator},
            onSelectionChanged: (s) => _onOperatorChanged(s.first),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _stationDropdown('起點', _from, (s) {
                      if (s != null) setState(() => _from = s);
                    }),
                    const SizedBox(height: 10),
                    _stationDropdown('終點', _to, (s) {
                      if (s != null) setState(() => _to = s);
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _swap,
                icon: const Icon(Icons.swap_vert),
                tooltip: '起訖對調',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_dateStr),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text('上車時間 $_timeStr'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
              onPressed: _search,
              icon: const Icon(Icons.search),
              label: const Text('搜尋'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stationDropdown(
      String label, RailStation value, ValueChanged<RailStation?> onChanged) {
    return DropdownButtonFormField<RailStation>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: stationsFor(_operator)
          .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _results(AsyncValue<List<RailTrain>>? result) {
    if (result == null) {
      return _hint(Icons.train, '選擇起訖站與上車時間後，按「搜尋」');
    }
    return result.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _hint(Icons.error_outline, '查詢失敗\n$e', retry: true),
      data: (trains) {
        if (trains.isEmpty) {
          return _hint(Icons.search_off, '$_timeStr 之後查無班次\n換個時間或日期再試');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          itemCount: trains.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _trainTile(trains[i]),
        );
      },
    );
  }

  Widget _trainTile(RailTrain t) {
    final accent =
        t.operator == RailOperator.thsr ? AppColors.thsr : AppColors.rail;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              children: [
                Text(t.type.isEmpty ? '車次' : t.type,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(t.trainNo,
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t.from} → ${t.to}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text('抵達 ${t.arrival}',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 12.5)),
              ],
            ),
          ),
          _ledChip(t.departure),
        ],
      ),
    );
  }

  Widget _ledChip(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ledBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            time.isEmpty ? '--:--' : time,
            style: const TextStyle(
              color: AppColors.led,
              fontFeatures: [FontFeature.tabularFigures()],
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
          const Text('出發',
              style: TextStyle(color: AppColors.led, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _hint(IconData icon, String text, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.inkSoft),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkSoft)),
            if (retry) ...[
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
                onPressed: _search,
                child: const Text('重新搜尋'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
