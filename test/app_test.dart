@TestOn('browser')
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:scraper/results_component.dart';
import 'package:scraper/results_component.template.dart' as ng;

void main() {
  final testBed =
      NgTestBed.forComponent<ResultsComponent>(ng.ResultsComponentNgFactory);
  NgTestFixture<ResultsComponent> fixture;

  setUp(() async {
    fixture = await testBed.create();
  });

  tearDown(disposeAnyRunningTest);

  test('heading', () {
    expect(fixture.text, contains('My First AngularDart App'));
  });
}
