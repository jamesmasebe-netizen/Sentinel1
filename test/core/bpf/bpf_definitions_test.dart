// Well-formedness checks for the 6 domain-flow BpfDefinition constants
// (lead_to_cash_bpf.dart, procure_to_pay_bpf.dart, asset_lifecycle_bpf.dart,
// issue_to_resolution_bpf.dart, hire_to_retire_bpf.dart,
// project_lifecycle_bpf.dart) and the bpfDefinitionsById registry that's
// built from them.
//
// Why this matters (see T1-004's "Fixed 2026-08-06" note in
// docs/testing/TEST_BACKLOG.md): BpfService.startBpf/advanceStage now call
// _assertKnownStage(bpfTypeId, stageId), which looks a definition up in
// bpfDefinitionsById by bpfTypeId and then checks whether stageId is one of
// definition.stages[].id. That gating logic silently depends on every
// definition being well-formed:
//   - a non-empty stages list (otherwise every advanceStage/startBpf call
//     for that type would be rejected — no valid stage could ever exist)
//   - non-empty, unique stage ids within a definition (a duplicate id would
//     make _assertKnownStage's `.any((s) => s.id == stageId)` pass for the
//     wrong stage's data being intended, and an empty id is indistinguishable
//     from "no stage id supplied")
//   - definition.id matching the map key it's registered under (otherwise
//     BpfService would validate a bpfTypeId's stage ids against the WRONG
//     definition, or fail to find a definition it should have)
//
// No Firestore/Riverpod needed — bpf_definitions.dart and the 6 *_bpf.dart
// files are pure data (const/final BpfDefinition literals with no service
// dependencies), per TEST_STRATEGY.md's unit-test-for-pure-logic guidance.
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/bpf/bpf_definitions.dart';

void main() {
  group('bpfDefinitionsById registry well-formedness', () {
    test('has all 6 domain flow definitions registered', () {
      expect(bpfDefinitionsById.keys.toSet(), {
        'lead_to_cash',
        'procure_to_pay',
        'asset_lifecycle',
        'issue_to_resolution',
        'hire_to_retire',
        'project_lifecycle',
      });
    });

    for (final entry in {
      'lead_to_cash': 5,
      'procure_to_pay': 5,
      'asset_lifecycle': 4,
      'issue_to_resolution': 4,
      'hire_to_retire': 4,
      'project_lifecycle': 6,
    }.entries) {
      test('${entry.key} has ${entry.value} stages', () {
        final definition = bpfDefinitionsById[entry.key]!;
        expect(definition.stages, hasLength(entry.value));
      });
    }

    bpfDefinitionsById.forEach((key, definition) {
      group('"$key"', () {
        test('map key matches the definition\'s own .id', () {
          expect(
            definition.id,
            key,
            reason: 'bpfDefinitionsById registers "$key" -> a definition '
                'whose own .id is "${definition.id}" — BpfService looks up '
                'by bpfTypeId (the map key), so a mismatch here means a '
                "definition validates against the wrong flow's stage ids "
                '(or its own bpfTypeId can never find it).',
          );
        });

        test('stages list is non-empty', () {
          expect(
            definition.stages,
            isNotEmpty,
            reason: 'an empty stages list means _assertKnownStage would '
                'reject every startBpf/advanceStage call for "$key" — no '
                'stage id could ever pass the `.any((s) => s.id == stageId)` '
                'check.',
          );
        });

        test('every stage id is non-empty', () {
          for (final stage in definition.stages) {
            expect(
              stage.id.trim(),
              isNotEmpty,
              reason: 'stage "${stage.title}" in "$key" has a blank/empty '
                  'id, which _assertKnownStage cannot meaningfully '
                  'distinguish from "no stage id supplied".',
            );
          }
        });

        test('every stage id is unique within the definition', () {
          final ids = definition.stages.map((s) => s.id).toList();
          final uniqueIds = ids.toSet();
          expect(
            uniqueIds,
            hasLength(ids.length),
            reason: 'duplicate stage ids in "$key": '
                '${ids.where((id) => ids.where((x) => x == id).length > 1).toSet()} '
                '— _assertKnownStage would accept a stage id that maps to '
                "more than one BpfStageDefinition, making the definition's "
                'title/description/expectedRecordType for that id ambiguous.',
          );
        });

        test('every stage has a non-empty title and expectedRecordType', () {
          for (final stage in definition.stages) {
            expect(stage.title.trim(), isNotEmpty,
                reason: 'stage "${stage.id}" in "$key" has a blank title.');
            expect(stage.expectedRecordType.trim(), isNotEmpty,
                reason: 'stage "${stage.id}" in "$key" has a blank '
                    'expectedRecordType.');
          }
        });
      });
    });
  });
}
