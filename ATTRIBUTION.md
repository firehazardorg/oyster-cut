# Attribution

## Project Lineage
Oyster is a derivative and integrative platform built on top of multiple
upstream AGPL codebases.

Primary upstreams:
- Logseq: https://github.com/logseq/logseq
- Huncho: remote URL tracked in `UPSTREAMS.yaml`

## Repository Model
This repository follows a split upstream/integration/product model:
- `upstream/logseq`: mirror branch for Logseq upstream
- `upstream/huncho`: mirror branch for Huncho upstream
- `integration/main`: merge-only integration branch
- `main`: Oyster product branch

No history rewrites are required in normal operation after public bootstrap.
Upstream traceability is maintained through merge commits and/or subtree history.

## License
This repository is licensed under AGPL-3.0.

When running a public network deployment of Oyster or a modified version, the
corresponding source code for that running version must be made available under
AGPL terms. See `docs/source-offer.md`.

## Source Mapping
Upstream metadata and sync state are tracked in `UPSTREAMS.yaml`.

If private-to-public commit remapping is needed during initial publication,
record the mapping in `docs/history-map.md`.
