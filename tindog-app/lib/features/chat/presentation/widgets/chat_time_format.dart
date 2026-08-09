/// True si [a] y [b] caen el mismo día local (ignora hora).
bool isSameCalendarDay(DateTime a, DateTime b) {
  final al = a.toLocal();
  final bl = b.toLocal();
  return al.year == bl.year && al.month == bl.month && al.day == bl.day;
}

/// Formatos cortos de fecha/hora para lista y presencia del chat.
String formatChatListTime(DateTime dt, {DateTime? now}) {
  final local = dt.toLocal();
  final n = (now ?? DateTime.now()).toLocal();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(local.year, local.month, local.day);
  final diffDays = today.difference(day).inDays;
  if (diffDays == 0) return _hhmm(local);
  if (diffDays == 1) return 'Ayer';
  if (diffDays < 7) {
    const weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    return weekdays[local.weekday - 1];
  }
  return '${_two(local.day)}/${_two(local.month)}';
}

/// Etiqueta de presencia: En línea / Últ. vez … / Desconectado.
String formatPresenceLabel({
  required bool online,
  DateTime? lastActive,
  DateTime? now,
}) {
  if (online) return 'En línea';
  if (lastActive == null) return 'Desconectado';

  final local = lastActive.toLocal();
  final n = (now ?? DateTime.now()).toLocal();
  final elapsed = n.difference(local);
  if (elapsed.isNegative || elapsed.inMinutes < 1) {
    return 'Últ. vez ahora';
  }
  if (elapsed.inMinutes < 60) {
    return 'Últ. vez hace ${elapsed.inMinutes} min';
  }

  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(local.year, local.month, local.day);
  final diffDays = today.difference(day).inDays;
  if (diffDays == 0) return 'Últ. vez a las ${_hhmm(local)}';
  if (diffDays == 1) return 'Últ. vez ayer';
  if (diffDays < 7) {
    const weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    return 'Últ. vez ${weekdays[local.weekday - 1]}';
  }
  return 'Últ. vez ${_two(local.day)}/${_two(local.month)}';
}

String _hhmm(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';

String _two(int n) => n.toString().padLeft(2, '0');
