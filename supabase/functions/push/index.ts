// The push function's entry point.
//
// Deliberately thin. Everything worth testing is in handler.ts, because this
// file calls Deno.serve at import time and names Deno.env — so anything here
// is beyond the reach of a test that has to import it.

import { handlePush } from './handler.ts';

Deno.serve((request: Request) =>
  handlePush(request, (key) => Deno.env.get(key), fetch),
);
