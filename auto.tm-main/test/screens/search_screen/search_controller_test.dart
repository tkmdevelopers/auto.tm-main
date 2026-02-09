import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get/get_instance/src/lifecycle.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:auto_tm/screens/search_screen/controller/search_controller.dart';
import 'package:auto_tm/services/search_service.dart';
import 'package:auto_tm/screens/search_screen/model/search_model.dart';
import 'search_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SearchService>()])
void main() {
  late MockSearchService mockService;
  late SearchScreenController controller;

  setUp(() {
     Get.reset();
     mockService = MockSearchService();
     
     // Stub GetxService lifecycle methods with safe Fakes
     when(mockService.onStart).thenReturn(FakeInternalFinalCallbackVoid());
     when(mockService.onDelete).thenReturn(FakeInternalFinalCallbackVoid());

     // Stub RxBools
     when(mockService.indexReady).thenReturn(false.obs);
     when(mockService.indexBuilding).thenReturn(false.obs);
     
     Get.put<SearchService>(mockService);
     controller = SearchScreenController();
  });

  tearDown(() {
    Get.reset();
  });

  test('searchHints calls service and updates hints', () async {
     final mockResult = [
       SearchModel(
         label: 'BMW X5', 
         brandLabel: 'BMW', 
         modelLabel: 'X5',
         brandUuid: '1', 
         modelUuid: '2', 
         compare: 'bmw x5'
      )
     ];

     when(mockService.search(any, offset: anyNamed('offset'), limit: anyNamed('limit')))
        .thenAnswer((_) async => mockResult);
     
     controller.searchTextController.text = 'bmw';
     await controller.searchHints();
     
     verify(mockService.search('bmw', offset: 0, limit: 20)).called(1);
     expect(controller.hints.length, 1);
     expect(controller.hints.first.label, 'BMW X5');
  });

  test('forwards index status from service', () {
    final ready = true.obs;
    final building = true.obs;
    when(mockService.indexReady).thenReturn(ready);
    when(mockService.indexBuilding).thenReturn(building);

    expect(controller.indexReady.value, true);
    expect(controller.indexBuilding.value, true);
  });
}

class FakeInternalFinalCallbackVoid extends Fake implements InternalFinalCallback<void> {
  @override
  void call() {}
}
