"""Integration test for the /searchapi search gateway (search.js).

Seeds OpenSearch with public fixture documents and a confidential intranet
document, then checks through docs-proxy that searches work and that no
request shape reaches the intranet index or another OpenSearch API.

Uses only the standard library. Run through tests/search/run.sh.
"""

import concurrent.futures
import itertools
import json
import os
import sys
import time
import unittest
import urllib.error
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OPENSEARCH = os.environ.get("OPENSEARCH_URL", "http://sitesearch-app:9200")
PROXY = os.environ.get("PROXY_URL", "http://docs-proxy:8000")
UNTRUSTED_PROXY = os.environ.get("UNTRUSTED_PROXY_URL", "http://docs-proxy-untrusted:8000")

# Every request to the proxy comes from its own client address, as Envoy
# would forward it, so only the rate limit test hits the per-client limit.
_client = itertools.count(1)


def client_address():
    n = next(_client)
    return f"198.51.{n // 250}.{n % 250 + 1}"
SECRET = "zebracorn"

# The gateway wraps highlighted matches in these private-use characters.
HIGHLIGHT_PRE = chr(0xE000)
HIGHLIGHT_POST = chr(0xE001)

# Mirrors the analysis the indexer configures, so a search here behaves as it
# does in production. The 'edge_ngram_index' analyzer and the 'prefix' field in
# mapping-hugo.json and mapping-blog.json carry partial-word matching; see
# common.py and mappings/ in docs-indexer.
SETTINGS = {
    "analysis": {
        "analyzer": {
            "trigram": {"type": "custom", "tokenizer": "standard", "filter": ["lowercase", "shingle"]},
            "reverse": {"type": "custom", "tokenizer": "standard", "filter": ["lowercase", "reverse"]},
            "edge_ngram_index": {"type": "custom", "tokenizer": "standard",
                                 "filter": ["lowercase", "edge_ngram_3_15"]},
        },
        "filter": {
            "shingle": {"type": "shingle", "min_shingle_size": 2, "max_shingle_size": 3},
            "edge_ngram_3_15": {"type": "edge_ngram", "min_gram": 3, "max_gram": 15, "preserve_original": True},
        },
    }
}


def request(method, url, body=None, headers=None):
    data = None
    if body is not None:
        data = body if isinstance(body, bytes) else json.dumps(body).encode()
    headers = dict(headers or {})
    if url.startswith(PROXY) and "X-Forwarded-For" not in headers:
        headers["X-Forwarded-For"] = client_address()
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    if data is not None and "Content-Type" not in headers:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def doc(title, body, type_, url, breadcrumb):
    d = {"title": title, "body": body, "text": body, "type": type_, "url": url, "uri": url,
         "breadcrumb": breadcrumb, "description": title + " description"}
    for i, b in enumerate(breadcrumb):
        d[f"breadcrumb_{i + 1}"] = b
    return d


def seed():
    for _ in range(90):
        try:
            status, _ = request("GET", OPENSEARCH + "/_cluster/health?wait_for_status=yellow&timeout=1s")
            if status == 200:
                break
        except OSError:
            pass
        time.sleep(2)
    else:
        sys.exit("OpenSearch did not come up")

    with open(os.path.join(HERE, "mapping-hugo.json")) as f:
        hugo = json.load(f)
    with open(os.path.join(HERE, "mapping-blog.json")) as f:
        blog = json.load(f)
    indices = {"docs": hugo, "handbook": hugo, "blog": blog, "intranet": hugo}
    for name, mapping in indices.items():
        request("DELETE", f"{OPENSEARCH}/{name}")
        status, text = request("PUT", f"{OPENSEARCH}/{name}", {"settings": SETTINGS, "mappings": mapping})
        assert status == 200, text

    docs = [
        ("docs", "1", doc("Scale node pools", "How to scale node pools of a workload cluster.", "Documentation",
                          "https://docs.giantswarm.io/tutorials/node-pools/", ["tutorials", "node-pools"])),
        ("docs", "2", doc("Cluster autoscaler", "The cluster autoscaler scales node pools up and down.", "Documentation",
                          "https://docs.giantswarm.io/reference/autoscaler/", ["reference"])),
        ("docs", "3", doc("Markdown bold", "Write **bold** text with two asterisks.", "Documentation",
                          "https://docs.giantswarm.io/reference/markdown/", ["reference", "markdown"])),
        ("handbook", "1", doc("Node pool etiquette", "Handbook page about node pools.", "Handbook",
                              "https://handbook.giantswarm.io/docs/node-pools/", ["docs"])),
        ("blog", "1", doc("Node pools are here", "Blog post announcing node pools.", "Blog",
                          "https://www.giantswarm.io/blog/node-pools", ["blog"])),
        ("intranet", "/docs/secret/", doc("Secret plan", f"The {SECRET} node pools plan is confidential.", "Intranet",
                                          "https://intranet.giantswarm.io/docs/secret/", ["docs", "secret"])),
    ]
    for index, id_, body in docs:
        status, text = request("PUT", f"{OPENSEARCH}/{index}/_doc/{urllib.parse.quote(id_, safe='')}?refresh=true", body)
        assert status in (200, 201), text


def search(params="", method="GET", body=None, headers=None, path="/searchapi/"):
    url = PROXY + path + (("?" + params) if params else "")
    return request(method, url, body=body, headers=headers)


def ok(params):
    status, text = search(params)
    if status != 200:
        raise AssertionError(f"{params}: {status} {text}")
    return json.loads(text)


class Gateway(unittest.TestCase):
    def test_search_returns_public_results_only_with_allowed_fields(self):
        result = ok("q=node+pools&size=50")
        hits = result["hits"]["hits"]
        self.assertGreaterEqual(len(hits), 3)
        self.assertEqual(result["hits"]["total"]["value"], len(hits))
        for hit in hits:
            self.assertEqual(set(hit), {"_source", "highlight"})
            self.assertEqual(set(hit["_source"]), {"title", "description", "url", "type", "breadcrumb"})
            self.assertNotEqual(hit["_source"]["type"], "Intranet")
            self.assertNotIn("intranet.giantswarm.io", hit["_source"]["url"])
        self.assertNotIn(SECRET, json.dumps(result))

    def test_secret_term_finds_nothing(self):
        self.assertEqual(ok("q=" + SECRET)["hits"]["total"]["value"], 0)
        self.assertEqual(ok("q=" + SECRET + "&match=all")["hits"]["total"]["value"], 0)

    def test_client_headers_do_not_reach_opensearch(self):
        # A client asking for gzip must still get a parsed, filtered answer.
        status, text = search("q=node+pools", headers={"Accept-Encoding": "gzip", "Cookie": "a=b",
                                                        "Authorization": "Bearer x"})
        self.assertEqual(status, 200, text)
        self.assertGreater(json.loads(text)["hits"]["total"]["value"], 0)

    def test_type_filter(self):
        hits = ok("q=node+pools&type=Handbook")["hits"]["hits"]
        self.assertEqual([h["_source"]["type"] for h in hits], ["Handbook"])

    def test_breadcrumb_filter(self):
        hits = ok("q=node+pools&breadcrumb=tutorials&breadcrumb=node-pools")["hits"]["hits"]
        self.assertEqual([h["_source"]["url"] for h in hits], ["https://docs.giantswarm.io/tutorials/node-pools/"])

    def test_match_all_and_paging(self):
        hits = ok("q=cluster+autoscaler+scales&match=all")["hits"]["hits"]
        self.assertEqual([h["_source"]["title"] for h in hits], ["Cluster autoscaler"])
        self.assertEqual(len(ok("q=node+pools&size=1")["hits"]["hits"]), 1)
        self.assertEqual(len(ok("q=node+pools&from=1000")["hits"]["hits"]), 0)

    def test_highlight_is_returned(self):
        hit = ok("q=autoscaler")["hits"]["hits"][0]
        self.assertTrue(any(HIGHLIGHT_PRE in s for s in hit["highlight"].get("body", []) + hit["highlight"].get("title", [])))

    def test_highlight_markers_do_not_collide_with_markdown_bold(self):
        # The markers were ** until the private-use characters replaced them,
        # which the indexed text also uses for bold. Only the match itself is
        # wrapped now, and the asterisks around it stay as text.
        hit = ok("q=bold")["hits"]["hits"][0]
        self.assertEqual(hit["_source"]["title"], "Markdown bold")
        body = hit["highlight"]["body"][0]
        self.assertIn(HIGHLIGHT_PRE + "bold" + HIGHLIGHT_POST, body)
        self.assertIn("**" + HIGHLIGHT_PRE, body)
        self.assertIn(HIGHLIGHT_POST + "**", body)

    def test_partial_word_matches_a_stored_prefix(self):
        # Searching while the last word is still being typed. "autosca" is not
        # what the english analyzer stems "autoscaler" to, so only the 'prefix'
        # sub-fields can match it. A fragment below the analyzer's min_gram of
        # 3 matches nothing.
        titles = [h["_source"]["title"] for h in ok("q=autosca")["hits"]["hits"]]
        self.assertIn("Cluster autoscaler", titles)
        self.assertEqual(ok("q=au")["hits"]["total"]["value"], 0)

    def test_query_syntax_stays_inside_the_query_string(self):
        # Operators the gateway allows are fine; JSON in q is just text.
        ok("q=" + urllib.parse.quote('"node pools" -blog'))
        result = ok("q=" + urllib.parse.quote('{"terms":{"body":{"index":"intranet","id":"/docs/secret/","path":"body"}}}'))
        self.assertNotIn(SECRET, json.dumps(result))

    def test_rejected_requests(self):
        lookup = {"query": {"terms": {"body": {"index": "intranet", "id": "/docs/secret/", "path": "body"}}}}
        mlt = {"query": {"more_like_this": {"fields": ["body"], "like": [{"_index": "intranet", "_id": "/docs/secret/"}],
                                             "min_term_freq": 1, "min_doc_freq": 1}}}
        cases = [
            ("POST with a terms lookup body", dict(method="POST", body=lookup), 403),
            ("POST with a more_like_this body", dict(method="POST", body=mlt), 403),
            ("PUT", dict(method="PUT", body=lookup), 403),
            ("GET with a body", dict(params="q=x", body=lookup, method="GET"), 400),
            ("missing q", dict(params=""), 400),
            ("blank q", dict(params="q=+++"), 400),
            ("long q", dict(params="q=" + "a" * 201), 400),
            ("unknown parameter", dict(params="q=x&index=intranet"), 400),
            ("source parameter", dict(params="q=x&source=" + urllib.parse.quote(json.dumps(lookup))), 400),
            ("intranet type", dict(params="q=x&type=Intranet"), 400),
            ("type twice", dict(params="q=x&type=Blog&type=Handbook"), 400),
            ("q twice", dict(params="q=x&q=y"), 400),
            ("size too big", dict(params="q=x&size=51"), 400),
            ("size zero", dict(params="q=x&size=0"), 400),
            ("negative from", dict(params="q=x&from=-1"), 400),
            ("from too big", dict(params="q=x&from=1001"), 400),
            ("too many breadcrumbs", dict(params="q=x" + "&breadcrumb=a" * 6), 400),
            ("empty breadcrumb", dict(params="q=x&breadcrumb="), 400),
            ("bad match", dict(params="q=x&match=regexp"), 400),
        ]
        for name, kwargs, want in cases:
            with self.subTest(name):
                status, text = search(**kwargs)
                self.assertEqual(status, want, text)
                self.assertNotIn(SECRET, text)

    def burst(self, url, forwarded_for, count=60):
        # Sent concurrently, so a slow runner still exceeds the burst.
        def one(i):
            return request("GET", url + "/searchapi/?q=node+pools",
                           headers={"X-Forwarded-For": forwarded_for(i)})[0]
        with concurrent.futures.ThreadPoolExecutor(max_workers=20) as pool:
            return list(pool.map(one, range(count)))

    def test_rate_limit_per_client(self):
        # 5 requests per second with a burst of 10, per client address and
        # replica. The address is the last X-Forwarded-For entry; earlier
        # ones are the client's own and don't open a new bucket.
        statuses = self.burst(PROXY, lambda i: f"203.0.113.{i}, 192.0.2.7")
        self.assertIn(429, statuses)
        self.assertEqual(set(statuses), {200, 429}, statuses)
        self.assertEqual(search("q=node+pools", headers={"X-Forwarded-For": "192.0.2.8"})[0], 200,
                         "another client is not limited")

    def test_untrusted_peer_cannot_choose_its_address(self):
        # From outside the Envoy pod range, X-Forwarded-For is ignored: a
        # new address per request still counts against the peer's own.
        statuses = self.burst(UNTRUSTED_PROXY, lambda i: f"198.18.0.{i}")
        self.assertIn(429, statuses)

    def test_upstream_cannot_redirect_into_opensearch(self):
        # docs-app answers /accel with X-Accel-Redirect into /_sitesearch.
        for method, body in [("GET", None), ("POST", b"x=1")]:
            with self.subTest(method):
                status, text = request(method, PROXY + "/accel", body=body,
                                       headers={"Content-Type": "application/x-www-form-urlencoded"})
                self.assertEqual(text.strip(), "docs-app", f"{status} {text}")
                self.assertNotIn(SECRET, text)

    def test_other_opensearch_apis_are_not_reachable(self):
        for path in ["/searchapi/health", "/searchapi_shards", "/searchapi/template", "/searchapi/_count",
                     "/_sitesearch", "/_sitesearch?q=" + SECRET]:
            with self.subTest(path):
                status, text = request("GET", PROXY + path)
                # Anything but the gateway falls through to docs-app.
                self.assertTrue(status != 200 or text.strip() == "docs-app", f"{status} {text}")
                self.assertNotIn(SECRET, text)
                self.assertNotIn("cluster_name", text)


if __name__ == "__main__":
    seed()
    unittest.main(argv=[sys.argv[0], "-v"])
