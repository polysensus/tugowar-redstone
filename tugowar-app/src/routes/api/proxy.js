// import { Request } from '@sveltejs/kit'
import { json } from '@sveltejs/kit';
// import { env } from '$env/dynamic/private'

const API_PREFIX_DEFAULT = 'api';

export function trimEnd(path, value) {
  return path.endsWith(value) ? path.slice(0, path.length - value.length) : path;
}

export function trimStart(path, value) {
  return path.startsWith(value) ? path.slice(value.length) : path;
}

/**
 *
 * @param {*} event
 * @param {*} targetUrlPrefix
 * @param {{bearerToken?:string,proxyPrefix?:string,forceIndex:boolean?}} options
 * @returns
 */
export async function POSTproxy(event, targetUrlPrefix, options) {

  const prefix = options.proxyPrefix ?? API_PREFIX_DEFAULT;

  let requestUrl = event.request.url;
  let uin = new URL(requestUrl);

  let i = uin.pathname.indexOf(prefix);
  if (i < 0) {
    // if svelte kit is routing propertly this should not happen
    throw new Error(`bad path, missing ${prefix} in ${uin.href}`);
  }

  // Establish the path suffix that remains after removing the prefix, so it can
  // be appended to the targetUrl
  let path = trimStart(uin.pathname.slice(i + prefix.length), '/');
  if (options.forceIndex) path = trimEnd(path, '/') + '/';

  let api = trimEnd(targetUrlPrefix, '/');

  const data = await event.request.json();
  console.log(JSON.stringify(data, null, ' . '));

  const proxyUrl = new URL(path + uin.search, api);
  console.log(
    `${event.request.url} -> ${proxyUrl}, path=${path}, api=${api}, forceIndex=${options.forceIndex}`
  );

  const proxyHeaders = [['content-type', 'application/json']];
  if (options.bearerToken) {
    proxyHeaders.push(
      ['Authorization', `Bearer ${options.bearerToken}`]
    );
  }

  // const options = deriveOptions(event.request)
  // const request = new Request(url, options)
  const request = new Request(proxyUrl, {
    method: event.request.method,
    body: JSON.stringify(data),
    keepalive: event.request.keepalive,
    headers: proxyHeaders
  });

  let upstream;
  try {
    upstream = await fetch(request);
  } catch (err) {
    console.log('proxy headers', request.headers);
    console.log('fetch error:', err);
    return json(err);
  }
  console.log('content-type', upstream.headers.get('content-type'))
  console.log('upstream headers', JSON.stringify(upstream.headers));
  try {
    let contentTypeLine = upstream.headers.get('content-type');
    const headers = [
      ['content-type', contentTypeLine],
      ['date', upstream.headers.get('date')],
      ['vary', upstream.headers.get('vary')]
    ];

    const body = await upstream.text();
    const response = new Response(body, {
      status: upstream.status,
      statusText: upstream.statusText,
      headers
    });
    console.log('proxy status', response.statusText);
    return response;
  } catch (err) {
    console.log(upstream);
    console.log('response error:', err);
    return json(err);
  }
}
