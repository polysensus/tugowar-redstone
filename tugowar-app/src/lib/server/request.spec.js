import { describe, it, expect } from 'vitest';

import { deriveOptions } from './request.js';

describe('server/request', function () {
  it('Should return empty object for undefined paramaters', function () {
    const o = deriveOptions();
    expect(o).toBeDefined();
    expect(Object.keys(o).length).to.eq(0);
  });
  it('Should clone only request options from request instance', function () {
    const o = deriveOptions({ method: true, xxx: true });
    expect(Object.keys(o).length).to.eq(1);
    expect(o.method).to.eq(true);
  });

  it('Should add update options that are not request options', function () {
    const o = deriveOptions({ method: true }, { xxx: true });
    expect(Object.keys(o).length).to.eq(2);
    expect(o.method).to.eq(true);
    expect(o.xxx).to.eq(true);
  });

  it('Should not copy body from request', function () {
    const o = deriveOptions({ body: true }, { xxx: true });
    expect(Object.keys(o).length).to.eq(1);
    expect(o.xxx).to.eq(true);
  });

  it('Should copy body from options', function () {
    const o = deriveOptions({ xxx: true }, { body: true });
    expect(Object.keys(o).length).to.eq(1);
    expect(o.body).to.eq(true);
  });
});
