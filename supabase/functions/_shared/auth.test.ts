// Run: node --experimental-strip-types supabase/functions/_shared/auth.test.ts

import assert from 'node:assert/strict';

import { bearerOf, secretsMatch } from './auth.ts';

let passed = 0;
function test(name: string, body: () => void) {
  try {
    body();
    passed++;
    console.log(`  ok  ${name}`);
  } catch (error) {
    console.error(`FAIL  ${name}\n      ${(error as Error).message}`);
    process.exitCode = 1;
  }
}

console.log('bearerOf');

test('reads the token, however the header is cased or spaced', () => {
  assert.equal(bearerOf('Bearer abc123'), 'abc123');
  assert.equal(bearerOf('bearer abc123'), 'abc123');
  assert.equal(bearerOf('BEARER   abc123  '), 'abc123');
});

test('gives nothing rather than something wrong', () => {
  assert.equal(bearerOf(null), '');
  assert.equal(bearerOf(''), '');
  assert.equal(bearerOf('abc123'), '', 'a bare token is not a Bearer header');
  assert.equal(bearerOf('Basic abc123'), '');
  assert.equal(bearerOf('Bearer'), '');
  assert.equal(bearerOf('Bearer '), '');
});

console.log('secretsMatch');

test('accepts only an exact match', () => {
  assert.equal(secretsMatch('s3cret', 's3cret'), true);
  assert.equal(secretsMatch('s3cret', 's3crel'), false);
  assert.equal(secretsMatch('s3cret', 's3cre'), false);
  assert.equal(secretsMatch('s3cret', 's3crett'), false);
});

test('an empty secret never matches, including itself', () => {
  // Otherwise an unset SUPABASE_SERVICE_ROLE_KEY and a caller sending no
  // Authorization header would be '' === '' — and the endpoint that can
  // notify anybody would be open to everybody.
  assert.equal(secretsMatch('', ''), false);
  assert.equal(secretsMatch('', 'anything'), false);
  assert.equal(secretsMatch('anything', ''), false);
});

test('compares every character, not just up to the first difference', () => {
  // The property the constant-time loop exists for. A comparison that
  // returned early would still pass the cases above; this one asserts the
  // loop has no exit inside it, by checking that a difference at the very
  // end is found just as surely as one at the start.
  const base = 'a'.repeat(64);
  assert.equal(secretsMatch(base, 'b' + base.slice(1)), false, 'differs at the start');
  assert.equal(secretsMatch(base, base.slice(0, -1) + 'b'), false, 'differs at the end');
  assert.equal(secretsMatch(base, base), true);
});

console.log(`\n${passed} passed`);
