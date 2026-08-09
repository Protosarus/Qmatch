import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> schema;
  late Map<String, dynamic> blueprint;

  setUpAll(() {
    schema = jsonDecode(
      File('assets/schemas/qmatch_question_schema_v3.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    blueprint = jsonDecode(
      File('assets/schemas/canonical_assessment_blueprint_v3.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  test('schema version explicit and module enums present', () {
    expect(schema['title'], contains('v3'));
    final props = schema['properties'] as Map<String, dynamic>;
    expect(props['schema_version']['const'], 'qmatch_question_schema_v3');
    expect(
        (props['module']['enum'] as List).toSet(), {'iq', 'eq', 'frequency'});
    expect(props.containsKey('question_id'), isTrue);
    expect(props.containsKey('separator_targets'), isTrue);
  });

  test('EQ/Frequency option deltas bounded and forbid correct fields', () {
    final option = (schema['\$defs'] as Map)['option'] as Map<String, dynamic>;
    final deltas =
        option['properties']['dimension_deltas'] as Map<String, dynamic>;
    final addl = deltas['additionalProperties'] as Map<String, dynamic>;
    expect(addl['minimum'], -1);
    expect(addl['maximum'], 1);
    expect(option.containsKey('not'), isTrue);
  });

  test('11 every schema version is explicit in companion blueprint', () {
    expect(blueprint['schema_version'], 'canonical_assessment_blueprint_v3');
    expect(blueprint['dimension_registry_version'],
        'canonical_dimension_registry_v1');
  });

  test('25 schema files are not listed in pubspec runtime assets', () {
    final pub = File('pubspec.yaml').readAsStringSync();
    expect(pub.contains('qmatch_question_schema_v3.json'), isFalse);
    expect(pub.contains('canonical_assessment_blueprint_v3.json'), isFalse);
  });
}
