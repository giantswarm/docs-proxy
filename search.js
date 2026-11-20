// Search gateway for /searchapi.
//
// sitesearch (OpenSearch) runs without authentication and also holds the
// confidential intranet index. Any caller-supplied query body can read other
// indices (terms lookup, more_like_this), so callers never send one: they pass
// a few validated parameters, this handler builds the query, and only the
// fields search results need are returned.
//
// GET /searchapi/?q=<text>[&type=<type>][&breadcrumb=<segment>...]
//                [&from=<n>][&size=<n>][&match=any|all]

const MAX_QUERY_LENGTH = 200;
const MAX_BREADCRUMBS = 5;
const MAX_BREADCRUMB_LENGTH = 100;
const MAX_FROM = 1000;
const MAX_SIZE = 50;
const DEFAULT_SIZE = 10;

// Highlight markers. These are private-use characters (U+E000 and U+E001)
// that cannot occur in indexed content, so they never collide with Markdown
// bold. String.fromCharCode keeps the source plain ASCII.
const HIGHLIGHT_PRE = String.fromCharCode(0xe000);
const HIGHLIGHT_POST = String.fromCharCode(0xe001);

// The public indices hold only these types. Intranet documents live in their
// own index, which the upstream location never targets.
const TYPES = ['Documentation', 'Handbook', 'Blog'];

const PARAMS = ['q', 'type', 'breadcrumb', 'from', 'size', 'match'];

// simple_query_string operators allowed in q. PREFIX (term*), FUZZY and
// NEAR/SLOP expand into many terms and can make one query expensive.
const QUERY_FLAGS = 'AND|OR|NOT|PHRASE|PRECEDENCE|WHITESPACE|ESCAPE';

function fail(r, status, message) {
    r.headersOut['Content-Type'] = 'application/json';
    r.return(status, JSON.stringify({ error: message }));
}

// Returns the single value of a parameter, or an error string.
function single(value, name) {
    if (Array.isArray(value)) {
        return { error: name + ' may be given only once' };
    }
    return { value: value };
}

function integer(raw, name, min, max, fallback) {
    if (raw === undefined) {
        return { value: fallback };
    }
    const s = single(raw, name);
    if (s.error) {
        return s;
    }
    if (!/^[0-9]{1,4}$/.test(s.value)) {
        return { error: name + ' must be a whole number' };
    }
    const n = Number(s.value);
    if (n < min || n > max) {
        return { error: name + ' must be between ' + min + ' and ' + max };
    }
    return { value: n };
}

// Validates the request and returns the search parameters, or an error.
function parse(r) {
    if (r.method !== 'GET' && r.method !== 'HEAD') {
        return { status: 405, error: 'only GET is supported' };
    }
    const length = r.headersIn['Content-Length'];
    if ((length && length !== '0') || r.headersIn['Transfer-Encoding']) {
        return { status: 400, error: 'a request body is not accepted' };
    }

    const args = r.args;
    for (const key in args) {
        if (PARAMS.indexOf(key) === -1) {
            return { status: 400, error: 'unknown parameter: ' + key };
        }
    }

    const q = single(args.q, 'q');
    if (q.error) {
        return { status: 400, error: q.error };
    }
    const text = (q.value || '').trim();
    if (text.length === 0) {
        return { status: 400, error: 'q is required' };
    }
    if (text.length > MAX_QUERY_LENGTH) {
        return { status: 400, error: 'q is longer than ' + MAX_QUERY_LENGTH + ' characters' };
    }

    let type = '';
    if (args.type !== undefined) {
        const t = single(args.type, 'type');
        if (t.error) {
            return { status: 400, error: t.error };
        }
        if (TYPES.indexOf(t.value) === -1) {
            return { status: 400, error: 'type must be one of ' + TYPES.join(', ') };
        }
        type = t.value;
    }

    let breadcrumbs = [];
    if (args.breadcrumb !== undefined) {
        breadcrumbs = Array.isArray(args.breadcrumb) ? args.breadcrumb : [args.breadcrumb];
        if (breadcrumbs.length > MAX_BREADCRUMBS) {
            return { status: 400, error: 'at most ' + MAX_BREADCRUMBS + ' breadcrumb segments' };
        }
        for (let i = 0; i < breadcrumbs.length; i++) {
            const b = breadcrumbs[i];
            if (b.length === 0 || b.length > MAX_BREADCRUMB_LENGTH) {
                return { status: 400, error: 'each breadcrumb must be 1 to ' + MAX_BREADCRUMB_LENGTH + ' characters' };
            }
        }
    }

    const from = integer(args.from, 'from', 0, MAX_FROM, 0);
    if (from.error) {
        return { status: 400, error: from.error };
    }
    const size = integer(args.size, 'size', 1, MAX_SIZE, DEFAULT_SIZE);
    if (size.error) {
        return { status: 400, error: size.error };
    }

    let matchAll = false;
    if (args.match !== undefined) {
        const m = single(args.match, 'match');
        if (m.error) {
            return { status: 400, error: m.error };
        }
        if (m.value !== 'any' && m.value !== 'all') {
            return { status: 400, error: 'match must be any or all' };
        }
        matchAll = m.value === 'all';
    }

    return {
        params: {
            text: text,
            type: type,
            breadcrumbs: breadcrumbs,
            from: from.value,
            size: size.value,
            matchAll: matchAll,
        },
    };
}

// Builds the OpenSearch query. Caller input only ever lands in string values,
// never in keys or structure.
function buildQuery(p) {
    const fields = ['title^5', 'title.prefix^2', 'body', 'body.prefix', 'text'];
    const inner = p.matchAll
        ? {
            simple_query_string: {
                query: p.text,
                fields: fields,
                default_operator: 'AND',
                flags: QUERY_FLAGS,
            },
        }
        : {
            multi_match: {
                query: p.text,
                fields: fields,
                type: 'best_fields',
                operator: 'or',
                minimum_should_match: '30%',
                tie_breaker: 0.3,
            },
        };

    const scored = {
        function_score: {
            query: inner,
            functions: [
                { filter: { term: { type: 'Blog' } }, weight: 0.01 },
                { filter: { term: { breadcrumb: 'changes' } }, weight: 0.0001 },
                { filter: { term: { breadcrumb: 'api' } }, weight: 0.0001 },
            ],
        },
    };

    const filters = [];
    if (p.type) {
        filters.push({ term: { type: p.type } });
    }
    for (let i = 0; i < p.breadcrumbs.length; i++) {
        const field = 'breadcrumb_' + (i + 1);
        const clause = { term: {} };
        clause.term[field] = p.breadcrumbs[i];
        filters.push(clause);
    }

    return {
        from: p.from,
        size: p.size,
        timeout: '5s',
        track_total_hits: 10000,
        sort: ['_score'],
        _source: { includes: ['title', 'description', 'url', 'type', 'breadcrumb'] },
        query: filters.length > 0 ? { bool: { must: [scored], filter: filters } } : scored,
        highlight: {
            pre_tags: [HIGHLIGHT_PRE],
            post_tags: [HIGHLIGHT_POST],
            fields: {
                body: { type: 'unified', number_of_fragments: 1, no_match_size: 200, fragment_size: 150 },
                title: { type: 'unified', number_of_fragments: 1 },
            },
        },
    };
}

function stringOrEmpty(v) {
    return typeof v === 'string' ? v : '';
}

// Copies only the fields search results need out of the OpenSearch response.
function shape(raw) {
    const hits = (raw && raw.hits) || {};
    const total = hits.total && typeof hits.total === 'object' ? hits.total.value : hits.total;
    const out = [];
    const list = Array.isArray(hits.hits) ? hits.hits : [];
    for (let i = 0; i < list.length; i++) {
        const src = list[i]._source || {};
        const hl = list[i].highlight || {};
        const hit = {
            _source: {
                title: stringOrEmpty(src.title),
                description: stringOrEmpty(src.description),
                url: stringOrEmpty(src.url),
                type: stringOrEmpty(src.type),
                breadcrumb: Array.isArray(src.breadcrumb) ? src.breadcrumb.filter((b) => typeof b === 'string') : [],
            },
            highlight: {},
        };
        ['body', 'title'].forEach((f) => {
            if (Array.isArray(hl[f])) {
                hit.highlight[f] = hl[f].filter((s) => typeof s === 'string');
            }
        });
        out.push(hit);
    }
    return { hits: { total: { value: typeof total === 'number' ? total : 0 }, hits: out } };
}

async function handle(r) {
    const parsed = parse(r);
    if (parsed.error) {
        return fail(r, parsed.status, parsed.error);
    }

    let reply;
    try {
        reply = await r.subrequest('/_sitesearch', {
            method: 'POST',
            body: JSON.stringify(buildQuery(parsed.params)),
        });
    } catch (e) {
        r.error('search subrequest failed: ' + e);
        return fail(r, 502, 'search is unavailable');
    }

    if (reply.status !== 200) {
        r.warn('search upstream returned ' + reply.status + ': ' + String(reply.responseText).slice(0, 500));
        return fail(r, 502, 'search is unavailable');
    }

    let raw;
    try {
        raw = JSON.parse(reply.responseText);
    } catch (e) {
        return fail(r, 502, 'search is unavailable');
    }

    let body;
    try {
        body = JSON.stringify(shape(raw));
    } catch (e) {
        r.warn('unexpected search upstream response: ' + e);
        return fail(r, 502, 'search is unavailable');
    }

    r.headersOut['Content-Type'] = 'application/json';
    r.headersOut['Cache-Control'] = 'no-store';
    r.return(200, body);
}

export default { handle, parse, buildQuery, shape };
