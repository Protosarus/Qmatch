'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const {
  APPLY_CONFIRM,
  parseGrandfatherCliArgs,
} = require('../src/assessment_trust_grandfather_v1');

const TOOL_PATH = path.join(
  __dirname,
  '../../tool/grandfather_assessment_trust_v1.js',
);

describe('grandfather_assessment_trust_v1 CLI safety', () => {
  const src = fs.readFileSync(TOOL_PATH, 'utf8');

  it('default tool invocation is dry-run and require.main gated', () => {
    assert.strictEqual(src.includes("if (require.main === module)"), true);
    assert.strictEqual(src.includes('--apply'), true);
    assert.strictEqual(src.includes(APPLY_CONFIRM), true);
    assert.strictEqual(
      src.includes('Phase 7G.1: implement and test the apply path. Do NOT run --apply against'),
      true,
    );
    const parsed = parseGrandfatherCliArgs([]);
    assert.strictEqual(parsed.writeEnabled, false);
  });

  it('apply without confirmation cannot write', () => {
    const parsed = parseGrandfatherCliArgs(['node', TOOL_PATH, '--apply']);
    assert.strictEqual(parsed.writeEnabled, false);
    assert.strictEqual(parsed.ok, false);
  });

  it('confirmation without apply cannot write', () => {
    const parsed = parseGrandfatherCliArgs([
      'node',
      TOOL_PATH,
      `--confirm=${APPLY_CONFIRM}`,
    ]);
    assert.strictEqual(parsed.writeEnabled, false);
    assert.strictEqual(parsed.mode, 'dry-run');
  });

  it('only apply + exact confirmation enables writer', () => {
    const parsed = parseGrandfatherCliArgs([
      'node',
      TOOL_PATH,
      '--apply',
      `--confirm=${APPLY_CONFIRM}`,
    ]);
    assert.strictEqual(parsed.writeEnabled, true);
    assert.strictEqual(src.includes('writeEnabled: parsed.writeEnabled'), true);
    assert.strictEqual(
      src.includes('commitGrandfatherPage(db, writes, { writeEnabled: true })'),
      true,
    );
  });

  it('dry-run output is aggregate-only and does not print PII fields', () => {
    assert.strictEqual(src.includes('user.email'), false);
    assert.strictEqual(src.includes('phone_number'), false);
    assert.strictEqual(src.includes('data.email'), false);
    assert.strictEqual(src.includes('profile data'), false);
    assert.strictEqual(src.includes('DRY-RUN complete. No Firestore writes.'), true);
    assert.strictEqual(src.includes('orderBy(FieldPath.documentId())'), true);
    assert.strictEqual(src.includes('startAfter'), true);
  });

  it('does not mutate Discover, completion mirrors, or Frequency V2', () => {
    assert.strictEqual(src.includes('discover_eligible:'), false);
    assert.strictEqual(src.includes('test_completed:'), false);
    assert.strictEqual(src.includes('assessment_flow_completed:'), false);
    assert.strictEqual(src.includes('finalizeFrequencyV2'), false);
    assert.strictEqual(src.includes('frequency_behavior_v2'), false);
    assert.strictEqual(src.includes('runtime_selectable'), false);
  });

  it('requiring the tool does not write Firestore', () => {
    const tool = require(TOOL_PATH);
    assert.strictEqual(typeof tool.parseGrandfatherCliArgs, 'function');
    assert.strictEqual(tool.APPLY_CONFIRM, APPLY_CONFIRM);
    const parsed = tool.parseGrandfatherCliArgs(['--apply']);
    assert.strictEqual(parsed.writeEnabled, false);
  });
});
