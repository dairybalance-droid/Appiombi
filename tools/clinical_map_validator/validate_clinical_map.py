from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree


DEFAULT_MAP_ROOT = Path("assets/clinical_maps/claw/international_claw_map/v1")
REQUIRED_AREA_FIELDS = {
    "id",
    "svg_element_id",
    "claw_number",
    "limb",
    "digit",
    "zone_type",
    "zone_code",
    "observation_group",
    "popup_kind",
    "label_it",
    "label_en",
    "is_clickable",
}
NON_CLINICAL_SVG_IDS = {"title", "desc", "clickable_canvas_placeholder"}
REQUIRED_DRAFT_FIELDS = {
    "schema_version",
    "map_id",
    "version",
    "status",
    "is_definitive",
    "candidate_area_count",
    "foot_pairs",
    "zone_templates",
    "promotion_blockers",
}
REQUIRED_PROPOSED_FINAL_FIELDS = {
    "id",
    "svg_element_id",
    "legacy_id",
    "expected_legacy_svg_element_id",
    "claw_number",
    "related_claws",
    "limb",
    "digit",
    "zone_type",
    "zone_code",
    "observation_group",
    "popup_kind",
    "label_it",
    "label_en",
    "is_clickable",
    "is_definitive",
    "requires_human_approval",
}
ALLOWED_PROPOSED_ZONE_TYPES = {"horn", "derma"}


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8-sig") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def collect_svg_ids(path: Path) -> list[str]:
    tree = ElementTree.parse(path)
    ids: list[str] = []
    for element in tree.iter():
        element_id = element.attrib.get("id")
        if element_id:
            ids.append(element_id)
    return ids


def resolve_manifest_path(map_root: Path, manifest_dir: Path, value: str) -> Path:
    path = (manifest_dir / value).resolve()
    try:
        path.relative_to(map_root.resolve())
    except ValueError:
        raise ValueError(f"Manifest path escapes map root: {value}") from None
    return path


def validate_draft_taxonomy(path: Path, expected_map_id: str, expected_version: int) -> list[str]:
    errors: list[str] = []
    draft = load_json(path)

    missing = sorted(REQUIRED_DRAFT_FIELDS - set(draft))
    if missing:
        errors.append(f"Draft taxonomy missing fields: {', '.join(missing)}")

    if draft.get("map_id") != expected_map_id:
        errors.append("Draft taxonomy map_id does not match map manifest")
    if draft.get("version") != expected_version:
        errors.append("Draft taxonomy version does not match map manifest")
    if draft.get("is_definitive") is not False:
        errors.append("Draft taxonomy must have is_definitive=false")

    foot_pairs = draft.get("foot_pairs", [])
    zone_templates = draft.get("zone_templates", [])
    if not isinstance(foot_pairs, list) or len(foot_pairs) != 4:
        errors.append("Draft taxonomy should contain 4 foot_pairs")
    if not isinstance(zone_templates, list) or len(zone_templates) != 12:
        errors.append("Draft taxonomy should contain 12 zone_templates")

    candidate_count = draft.get("candidate_area_count")
    if candidate_count != 80:
        errors.append("Draft taxonomy candidate_area_count should be 80")

    for index, template in enumerate(zone_templates if isinstance(zone_templates, list) else []):
        if not isinstance(template, dict):
            errors.append(f"Draft zone template at index {index} must be an object")
            continue
        if template.get("requires_human_approval") is not True:
            errors.append(
                f"Draft zone template {template.get('template_id', index)} must require human approval"
            )

    return errors


def validate_proposed_final_taxonomy(
    path: Path,
    expected_map_id: str,
    expected_version: int,
) -> list[str]:
    errors: list[str] = []
    proposed = load_json(path)

    if proposed.get("map_id") != expected_map_id:
        errors.append("Proposed final taxonomy map_id does not match map manifest")
    if proposed.get("version") != expected_version:
        errors.append("Proposed final taxonomy version does not match map manifest")
    if proposed.get("is_definitive") is not False:
        errors.append("Proposed final taxonomy must have top-level is_definitive=false")

    areas = proposed.get("areas")
    if not isinstance(areas, list):
        return ["Proposed final taxonomy field 'areas' must be a list"]
    if len(areas) != 80:
        errors.append("Proposed final taxonomy should contain 80 areas")
    if proposed.get("candidate_area_count") != 80:
        errors.append("Proposed final taxonomy candidate_area_count should be 80")

    ids: list[str] = []
    svg_ids: list[str] = []
    legacy_ids: list[str] = []
    for index, area in enumerate(areas):
        if not isinstance(area, dict):
            errors.append(f"Proposed final area at index {index} must be an object")
            continue

        missing = sorted(REQUIRED_PROPOSED_FINAL_FIELDS - set(area))
        if missing:
            errors.append(
                f"Proposed final area at index {index} missing fields: {', '.join(missing)}"
            )

        area_id = area.get("id")
        svg_element_id = area.get("svg_element_id")
        legacy_id = area.get("legacy_id")
        expected_legacy_svg_element_id = area.get("expected_legacy_svg_element_id")
        zone_type = area.get("zone_type")
        observation_group = area.get("observation_group")
        popup_kind = area.get("popup_kind")

        if isinstance(area_id, str):
            ids.append(area_id)
        if isinstance(svg_element_id, str):
            svg_ids.append(svg_element_id)
        if isinstance(legacy_id, str):
            legacy_ids.append(legacy_id)
            if expected_legacy_svg_element_id != legacy_id:
                errors.append(
                    f"Proposed final area {area_id or index} has incoherent expected legacy SVG id"
                )
        elif expected_legacy_svg_element_id is not None:
            errors.append(
                f"Proposed final area {area_id or index} has expected legacy SVG id without legacy_id"
            )

        if zone_type not in ALLOWED_PROPOSED_ZONE_TYPES:
            errors.append(f"Proposed final area {area_id or index} has invalid zone_type")
        if zone_type == "horn" and (
            observation_group != "horn_lesion" or popup_kind != "horn"
        ):
            errors.append(f"Proposed final horn area {area_id or index} has invalid group/popup")
        if zone_type == "derma" and (
            observation_group != "derma_lesion" or popup_kind != "skin"
        ):
            errors.append(f"Proposed final derma area {area_id or index} has invalid group/popup")
        if area.get("is_definitive") is not False:
            errors.append(f"Proposed final area {area_id or index} must have is_definitive=false")

    duplicate_ids = sorted(area_id for area_id, count in Counter(ids).items() if count > 1)
    if duplicate_ids:
        errors.append(f"Duplicate proposed final area ids: {', '.join(duplicate_ids)}")

    duplicate_svg_ids = sorted(svg_id for svg_id, count in Counter(svg_ids).items() if count > 1)
    if duplicate_svg_ids:
        errors.append(
            f"Duplicate proposed final svg_element_id values: {', '.join(duplicate_svg_ids)}"
        )

    duplicate_legacy_ids = sorted(
        legacy_id for legacy_id, count in Counter(legacy_ids).items() if count > 1
    )
    if duplicate_legacy_ids:
        errors.append(f"Duplicate proposed final legacy_id values: {', '.join(duplicate_legacy_ids)}")

    return errors


def validate(
    map_root: Path,
    draft_taxonomy: Path | None = None,
    proposed_final_taxonomy: Path | None = None,
) -> int:
    manifest_dir = map_root / "manifests"
    map_manifest_path = manifest_dir / "map_manifest.json"
    areas_manifest_path = manifest_dir / "anatomical_areas.json"

    errors: list[str] = []
    warnings: list[str] = []

    try:
        map_manifest = load_json(map_manifest_path)
        areas_manifest = load_json(areas_manifest_path)
    except Exception as exc:
        print(f"ERROR: {exc}")
        return 1

    try:
        clickable_svg = resolve_manifest_path(
            map_root,
            manifest_dir,
            str(map_manifest["clickable_svg"]),
        )
    except Exception as exc:
        print(f"ERROR: {exc}")
        return 1

    try:
        svg_ids = collect_svg_ids(clickable_svg)
    except Exception as exc:
        print(f"ERROR: invalid SVG {clickable_svg}: {exc}")
        return 1

    svg_id_counts = Counter(svg_ids)
    duplicate_svg_ids = sorted(
        svg_id for svg_id, count in svg_id_counts.items() if count > 1
    )
    if duplicate_svg_ids:
        errors.append(f"Duplicate SVG ids: {', '.join(duplicate_svg_ids)}")

    areas = areas_manifest.get("areas")
    if not isinstance(areas, list):
        errors.append("anatomical_areas.json field 'areas' must be a list")
        areas = []

    area_ids: list[str] = []
    area_svg_ids: list[str] = []
    for index, area in enumerate(areas):
        if not isinstance(area, dict):
            errors.append(f"Area at index {index} must be an object")
            continue

        missing = sorted(REQUIRED_AREA_FIELDS - set(area))
        if missing:
            errors.append(f"Area at index {index} missing fields: {', '.join(missing)}")

        area_id = area.get("id")
        svg_element_id = area.get("svg_element_id")
        if isinstance(area_id, str):
            area_ids.append(area_id)
        if isinstance(svg_element_id, str):
            area_svg_ids.append(svg_element_id)
            if svg_element_id not in svg_id_counts:
                errors.append(
                    f"Area {area_id or index} references missing SVG id {svg_element_id}"
                )

    duplicate_area_ids = sorted(
        area_id for area_id, count in Counter(area_ids).items() if count > 1
    )
    if duplicate_area_ids:
        errors.append(f"Duplicate area ids: {', '.join(duplicate_area_ids)}")

    duplicate_area_svg_ids = sorted(
        svg_id for svg_id, count in Counter(area_svg_ids).items() if count > 1
    )
    if duplicate_area_svg_ids:
        errors.append(
            f"Duplicate area svg_element_id values: {', '.join(duplicate_area_svg_ids)}"
        )

    if not areas:
        warnings.append("No manifest areas are defined yet; this is acceptable for draft setup.")

    if draft_taxonomy:
        try:
            draft_errors = validate_draft_taxonomy(
                draft_taxonomy,
                expected_map_id=str(map_manifest.get("map_id")),
                expected_version=int(map_manifest.get("version")),
            )
            if draft_errors:
                errors.extend(draft_errors)
            else:
                print(f"Draft taxonomy: {draft_taxonomy}")
        except Exception as exc:
            errors.append(f"Draft taxonomy validation failed: {exc}")

    if proposed_final_taxonomy:
        try:
            proposed_errors = validate_proposed_final_taxonomy(
                proposed_final_taxonomy,
                expected_map_id=str(map_manifest.get("map_id")),
                expected_version=int(map_manifest.get("version")),
            )
            if proposed_errors:
                errors.extend(proposed_errors)
            else:
                print(f"Proposed final taxonomy: {proposed_final_taxonomy}")
        except Exception as exc:
            errors.append(f"Proposed final taxonomy validation failed: {exc}")

    orphan_svg_ids = sorted(
        svg_id
        for svg_id in svg_ids
        if svg_id not in area_svg_ids and svg_id not in NON_CLINICAL_SVG_IDS
    )
    if orphan_svg_ids:
        warnings.append(f"SVG ids not referenced by manifest areas: {', '.join(orphan_svg_ids)}")

    print(f"Map root: {map_root}")
    print(f"Clickable SVG: {clickable_svg}")
    print(f"SVG ids: {len(svg_ids)}")
    print(f"Manifest areas: {len(areas)}")

    for warning in warnings:
        print(f"WARNING: {warning}")
    for error in errors:
        print(f"ERROR: {error}")

    return 1 if errors else 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Appiombi clinical map manifests.")
    parser.add_argument(
        "--map-root",
        type=Path,
        default=DEFAULT_MAP_ROOT,
        help="Clinical map version root directory.",
    )
    parser.add_argument(
        "--draft-taxonomy",
        type=Path,
        help="Optional draft taxonomy JSON to validate without making it required.",
    )
    parser.add_argument(
        "--proposed-final-taxonomy",
        type=Path,
        help="Optional proposed final taxonomy JSON to validate without promoting it.",
    )
    args = parser.parse_args()
    return validate(args.map_root, args.draft_taxonomy, args.proposed_final_taxonomy)


if __name__ == "__main__":
    sys.exit(main())
