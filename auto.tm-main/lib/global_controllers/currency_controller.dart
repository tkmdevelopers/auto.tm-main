import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CurrencyController extends GetxController {
  final GetStorage storage = GetStorage();

  var selectedCurrency = 'Dollar'.obs;

  void updateCurrency(String currencyName) {
    selectedCurrency.value = currencyName;
    storage.write('curr_selected', selectedCurrency.value);
  }
}
