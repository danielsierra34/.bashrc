"""Generic text extractor -- fallback for formats graphify has no dedicated
parser for.

Registered by extract._get_extractor only for an extension that is not one of
detect.py's known categories (CODE/DOC/PAPER/IMAGE/OFFICE/VIDEO/Google
Workspace) *and* that a binary/text sniff (detect._looks_like_text) confirms
is textual. A recognized extension always keeps its existing behavior --
this module never runs for .py/.md/.json/etc., even when they have no AST
extractor of their own.

Deliberately does not attempt per-format grammar: a `.cml`/`.puml`/`.mmd`/
`.customdsl` file gets a file node plus its capitalized identifier-like
tokens (the load-bearing symbols in most textual DSLs: type/entity/component/
service names) so it is discoverable and queryable, not silently invisible.
It will never match the precision of a real extractor, and is not meant to.
"""
from __future__ import annotations

import re
from pathlib import Path

from graphify.extractors.base import _file_stem, _make_id

# Skip oversized blobs rather than read them whole -- mirrors json_config.py's
# 1 MiB config-file cap, sized up a bit since this fallback also covers plain
# prose/DSL files that can legitimately run larger than a config file.
_GENERIC_MAX_BYTES = 2 * 1024 * 1024

# Cap how many distinct identifiers a single file can contribute, mirroring
# json_config.py's per-file pair cap (500) -- protects against a pathological
# file (a minified blob, a giant generated table) turning into thousands of
# orphan nodes.
_GENERIC_MAX_IDENTIFIERS = 300

# PascalCase / ALLCAPS tokens are the load-bearing symbols in most textual
# DSLs (BoundedContext, PaymentGateway, ENTITY, OrderService, ...), while
# lowercase keywords (component, entity, graph, feature) are the DSL's own
# grammar noise. Coarse on purpose: this is a fallback for formats graphify
# has no grammar for, not a replacement for one.
_IDENT_RE = re.compile(r'\b[A-Z][A-Za-z0-9_]{2,}\b')

# "A --> B" / "A -> B" / "A => B" / "A -- B" style relations: Mermaid, DOT-ish
# and most diagram/DSL formats use one of these for an explicit edge between
# two named things, so a match here is a real semantic relation, not mere
# co-occurrence on the same line.
_ARROW_RE = re.compile(
    r'\b([A-Z][A-Za-z0-9_]{2,})\b\s*(?:-->|->|=>|--)\s*\b([A-Z][A-Za-z0-9_]{2,})\b'
)


def extract_generic_text(path: Path) -> dict:
    """Best-effort structure for a textual file with no dedicated extractor.

    Returns the same nodes/edges shape every other extractor returns, so the
    rest of the pipeline (build/cluster/report/query) treats it exactly like
    any other source file.
    """
    try:
        if path.stat().st_size > _GENERIC_MAX_BYTES:
            return {"nodes": [], "edges": [], "error": "file too large for generic text extraction"}
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError as e:
        return {"nodes": [], "edges": [], "error": str(e)}

    str_path = str(path)
    stem = _file_stem(path)
    file_nid = _make_id(str_path)

    nodes: list[dict] = [{"id": file_nid, "label": path.name, "file_type": "code",
                           "source_file": str_path, "source_location": "L1"}]
    edges: list[dict] = []
    seen_ids: set[str] = {file_nid}
    nid_by_name: dict[str, str] = {}
    seen_edge_pairs: set[tuple[str, str]] = set()
    identifier_budget = [_GENERIC_MAX_IDENTIFIERS]

    def ident_node(name: str, line: int) -> str | None:
        nid = nid_by_name.get(name)
        if nid is not None:
            return nid
        if identifier_budget[0] <= 0:
            return None
        nid = _make_id(stem, name)
        if not nid:
            return None
        nid_by_name[name] = nid
        identifier_budget[0] -= 1
        if nid not in seen_ids:
            seen_ids.add(nid)
            nodes.append({"id": nid, "label": name, "file_type": "code",
                           "source_file": str_path, "source_location": f"L{line}"})
            edges.append({"source": file_nid, "target": nid, "relation": "contains",
                           "confidence": "EXTRACTED", "source_file": str_path,
                           "source_location": f"L{line}", "weight": 1.0})
        return nid

    for lineno, line in enumerate(text.splitlines(), start=1):
        for m in _ARROW_RE.finditer(line):
            left_nid = ident_node(m.group(1), lineno)
            right_nid = ident_node(m.group(2), lineno)
            if not left_nid or not right_nid or left_nid == right_nid:
                continue
            pair = (left_nid, right_nid)
            if pair in seen_edge_pairs:
                continue
            seen_edge_pairs.add(pair)
            edges.append({"source": left_nid, "target": right_nid, "relation": "references",
                           "confidence": "EXTRACTED", "source_file": str_path,
                           "source_location": f"L{lineno}", "weight": 1.0})
        for m in _IDENT_RE.finditer(line):
            ident_node(m.group(0), lineno)

    return {"nodes": nodes, "edges": edges}
