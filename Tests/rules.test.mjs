import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { test } from 'node:test';

const require = createRequire(import.meta.url);
const rules = require('../InstaLite/Resources/rules.js');
const cases = JSON.parse(readFileSync(new URL('./rules-cases.json', import.meta.url), 'utf8'));

test('yönlendirme kuralları', () => {
  for (const { from, to, expected } of cases.redirect) {
    assert.equal(rules.redirect(from, to), expected, `${from} → ${to}`);
  }
});
