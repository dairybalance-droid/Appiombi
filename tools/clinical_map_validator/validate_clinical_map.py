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


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
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


def validate(map_root: Path, draft_taxonomy: Path | None = None) -> int:
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
    args = parser.parse_args()
    return validate(args.map_root, args.draft_taxonomy)


if __name__ == "__main__":
    sys.exit(main())
