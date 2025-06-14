import 'package:intl/intl.dart';

class Utils {

  static String formatDate(DateTime? date) {
    if (date != null) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
    return '';
  }

}