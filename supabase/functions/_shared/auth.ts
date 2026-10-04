// Who may ask for a notification to be sent.
//
// Separate from the handler so it can be tested: index.ts calls Deno.serve at
// import time, and a security check that cannot be imported is a security
// check nobody runs.

/// Equal-length, constant-time comparison.
///
/// `a === b` on a secret returns as soon as two characters differ, which
/// leaks the length of the matching prefix through timing and makes the key
/// guessable one character at a time. The length check leaks only the
/// length, which is not a secret.
export function secretsMatch(a: string, b: string): boolean {
  if (a.length !== b.length || a.length === 0) return false;
  let difference = 0;
  for (let i = 0; i < a.length; i++) difference |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return difference === 0;
}

/// The token out of an `Authorization: Bearer …` header, or ''.
export function bearerOf(header: string | null): string {
  if (!header) return '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : '';
}
