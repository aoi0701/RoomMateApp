class FormatUtils {
  const FormatUtils._();

  static String formatMoney(num value) {
    final text = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    var count = 0;

    for (var i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
      count++;

      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }

    return '${buffer.toString().split('').reversed.join()}đ';
  }
}
