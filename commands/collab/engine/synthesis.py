"""Synthesis source-unit and artifact helpers for collab projection."""
from __future__ import annotations

import hashlib
import json
from copy import deepcopy

from commands.collab.engine.errors import die
from commands.collab.engine.normalizers import phase_slug
from commands.collab.engine.registry_constants import PHASES
from commands.collab.engine.transcript_render import (
    contribution_store_digest,
    projection_source_digest,
    projection_store_records,
)

SYNTHESIS_AUTHOR_ROLE = 'sy'
SYNTHESIS_STORE_SCHEMA = 'collab-synthesis-artifacts-v1'
SYNTHESIS_ABSENT_TEXT = '_Not yet produced. Run (collab synthesize) to generate._'


def empty_synthesis_store() -> dict:
    return {
        'schema': SYNTHESIS_STORE_SCHEMA,
        'artifacts': [],
    }


def synthesis_artifacts(synthesis_store: object) -> list[dict]:
    if synthesis_store is None:
        return []
    if not isinstance(synthesis_store, dict):
        die('synthesis store must be an object')
    artifacts = synthesis_store.get('artifacts', [])
    if not isinstance(artifacts, list):
        die('synthesis store artifacts must be a list')
    normalized: list[dict] = []
    for index, artifact in enumerate(artifacts, start=1):
        if not isinstance(artifact, dict):
            die(f'synthesis artifact {index} must be an object')
        normalized.append(artifact)
    return normalized


def normalized_synthesis_store(synthesis_store: object | None) -> dict:
    if synthesis_store is None:
        return empty_synthesis_store()
    if not isinstance(synthesis_store, dict):
        die('synthesis store must be an object')
    store = deepcopy(synthesis_store)
    schema = store.get('schema')
    if schema is None:
        store['schema'] = SYNTHESIS_STORE_SCHEMA
    elif schema != SYNTHESIS_STORE_SCHEMA:
        die(f'unsupported synthesis store schema: {schema}')
    artifacts = store.setdefault('artifacts', [])
    if not isinstance(artifacts, list):
        die('synthesis store artifacts must be a list')
    for index, artifact in enumerate(artifacts, start=1):
        if not isinstance(artifact, dict):
            die(f'synthesis artifact {index} must be an object')
    return store


def latest_phase_artifact(synthesis_store: object | None, phase: str) -> dict | None:
    for artifact in reversed(synthesis_artifacts(synthesis_store)):
        if artifact.get('phase') == phase:
            return artifact
    return None


def phase_artifact_count(synthesis_store: object | None, phase: str) -> int:
    return sum(1 for artifact in synthesis_artifacts(synthesis_store) if artifact.get('phase') == phase)


def _source_unit_digest(payload: dict) -> str:
    encoded = json.dumps(payload, sort_keys=True, separators=(',', ':'), ensure_ascii=True)
    return hashlib.sha256(encoded.encode()).hexdigest()


def current_synthesis_source_unit(
    registry_state: dict,
    entry: dict,
    contribution_store: object,
    synthesis_store: object | None,
    observed_revision: int,
) -> dict:
    phase = entry.get('activePhase')
    if phase not in PHASES:
        die('ABORT: active phase missing in metadata.')
    records = projection_store_records(contribution_store)
    phase_records = [record for record in records if record['phase'] == phase]
    moderator_role = entry.get('moderatorRole', 'mod')
    round_start_anchor = None
    start_index = -1
    for index, record in enumerate(phase_records):
        if record['role'] == moderator_role:
            round_start_anchor = record['anchor']
            start_index = index
    contribution_records = [
        record for record in phase_records[start_index + 1:]
        if record['role'] != moderator_role
    ]
    contribution_anchors = [record['anchor'] for record in contribution_records]
    unit_payload = {
        'phase': phase,
        'roundStartAnchor': round_start_anchor,
        'contributionAnchors': contribution_anchors,
        'observedRevision': observed_revision,
        'authorRole': SYNTHESIS_AUTHOR_ROLE,
    }
    return {
        'phase': phase,
        'roundStartAnchor': round_start_anchor,
        'contributionAnchors': contribution_anchors,
        'observedRevision': observed_revision,
        'roundNumber': phase_artifact_count(synthesis_store, phase) + 1,
        'noContributions': not contribution_anchors,
        'sourceDigest': projection_source_digest(registry_state, entry, contribution_store, observed_revision),
        'sourceUnitDigest': _source_unit_digest(unit_payload),
        'contributionStoreDigest': contribution_store_digest(contribution_store),
    }


def artifact_id_for_source_unit(unit: dict) -> str:
    phase = unit.get('phase')
    if phase not in PHASES:
        die('synthesis source unit has invalid phase')
    round_number = unit.get('roundNumber')
    if not isinstance(round_number, int) or round_number < 1:
        die('synthesis source unit has invalid roundNumber')
    digest = unit.get('sourceUnitDigest')
    if not isinstance(digest, str) or len(digest) < 12:
        die('synthesis source unit has invalid sourceUnitDigest')
    return f'{phase_slug(phase)}-round-{round_number}-{digest[:12]}'


def build_synthesis_artifact(
    unit: dict,
    artifact_id: str,
    content_path: str,
    content: str,
    agent_id: str,
    created_at: str,
    registry_revision_after_write: int,
) -> dict:
    if not content.strip():
        die('synthesis content is empty')
    return {
        'id': artifact_id,
        'phase': unit['phase'],
        'roundNumber': unit['roundNumber'],
        'roundStartAnchor': unit['roundStartAnchor'],
        'contributionAnchors': list(unit['contributionAnchors']),
        'observedRevision': unit['observedRevision'],
        'registryRevision': registry_revision_after_write,
        'authorRole': SYNTHESIS_AUTHOR_ROLE,
        'agentId': agent_id,
        'createdAt': created_at,
        'sourceDigest': unit['sourceDigest'],
        'sourceUnitDigest': unit['sourceUnitDigest'],
        'contributionStoreDigest': unit['contributionStoreDigest'],
        'contentPath': content_path,
        'contentDigest': hashlib.sha256(content.encode()).hexdigest(),
    }


def public_artifact_metadata(artifact: dict) -> dict:
    return {key: deepcopy(value) for key, value in artifact.items() if not key.startswith('_')}


def append_synthesis_artifact(synthesis_store: object | None, artifact: dict) -> dict:
    store = normalized_synthesis_store(synthesis_store)
    store['artifacts'].append(public_artifact_metadata(artifact))
    return store


def synthesis_registry_metadata(store_path: str, synthesis_store: object) -> dict:
    artifacts = [public_artifact_metadata(artifact) for artifact in synthesis_artifacts(synthesis_store)]
    latest_by_phase: dict[str, dict] = {}
    for artifact in artifacts:
        phase = artifact.get('phase')
        if isinstance(phase, str):
            latest_by_phase[phase] = artifact
    return {
        'storePath': store_path,
        'artifacts': artifacts,
        'latestArtifactByPhase': latest_by_phase,
    }


def artifact_is_current(
    registry_state: dict,
    entry: dict,
    contribution_store: object,
    artifact: dict,
) -> bool:
    phase = artifact.get('phase')
    if phase not in PHASES:
        return False
    if entry.get('activePhase') != phase:
        return False
    observed_revision = artifact.get('observedRevision')
    if not isinstance(observed_revision, int):
        return False
    unit = current_synthesis_source_unit(
        registry_state,
        entry,
        contribution_store,
        None,
        observed_revision,
    )
    return (
        artifact.get('roundStartAnchor') == unit['roundStartAnchor']
        and artifact.get('contributionAnchors') == unit['contributionAnchors']
        and artifact.get('sourceDigest') == unit['sourceDigest']
        and artifact.get('sourceUnitDigest') == unit['sourceUnitDigest']
        and artifact.get('contributionStoreDigest') == unit['contributionStoreDigest']
    )


def synthesis_block_lines(
    registry_state: dict,
    entry: dict,
    contribution_store: object,
    synthesis_store: object | None,
    phase: str,
) -> list[str]:
    if phase not in PHASES:
        die(f'invalid synthesis phase: {phase}')
    latest = latest_phase_artifact(synthesis_store, phase)
    if latest is None:
        unit = current_synthesis_source_unit(
            registry_state,
            dict(entry, activePhase=phase),
            contribution_store,
            synthesis_store,
            int(registry_state.get('revision', 0)),
        )
        return [
            f'## {phase} \u2014 Round {unit["roundNumber"]} synthesis',
            '',
            SYNTHESIS_ABSENT_TEXT,
            '',
        ]
    if not artifact_is_current(registry_state, entry, contribution_store, latest):
        produced = latest.get('observedRevision', 'unknown')
        current = registry_state.get('revision', 'unknown')
        round_number = latest.get('roundNumber', phase_artifact_count(synthesis_store, phase))
        return [
            f'## {phase} \u2014 Round {round_number} synthesis',
            '',
            f'_Stale \u2014 produced at revision {produced}; current revision {current}. '
            'Re-run (collab synthesize) to update._',
            '',
        ]
    content = latest.get('_content')
    if not isinstance(content, str) or not content.strip():
        die(f'synthesis artifact body missing: {latest.get("id", "<unknown>")}')
    return content.rstrip('\n').splitlines() + ['']


def synthesis_blocks_for_projection(
    registry_state: dict,
    entry: dict,
    contribution_store: object,
    synthesis_store: object | None,
) -> dict[str, list[str]]:
    records = projection_store_records(contribution_store)
    blocks: dict[str, list[str]] = {}
    for phase in PHASES:
        if any(record['phase'] == phase for record in records):
            blocks[phase] = synthesis_block_lines(
                registry_state,
                entry,
                contribution_store,
                synthesis_store,
                phase,
            )
    return blocks
