# International Claw Map v1

Questa cartella contiene asset clinici versionati per la mappa unghioni Appiombi.

## Scopo

Gli asset qui dentro sono separati dagli asset generici dell'app. La cartella `assets/images/` resta dedicata ad asset UI, logo, immagini generiche e compatibilita runtime esistente.

## Stato

Questa struttura non e ancora collegata al runtime Flutter. Per ora la PNG reference resta anche in `assets/images/hoof_single_card_reference.png` per non rompere l'app attuale.

## File

- `reference/hoof_single_card_reference.png`: copia clinica versionata della reference PNG.
- `svg/master/hoof_single_card_master.svg`: copia clinica versionata del master SVG locale preesistente.
- `svg/clickable/hoof_single_card_clickable.svg`: placeholder del futuro SVG cliccabile.
- `manifests/map_manifest.json`: metadati generali della mappa.
- `manifests/anatomical_areas.json`: schema iniziale per le aree anatomiche.
- `metadata/svg_master_id_analysis.md`: analisi tecnica degli ID presenti nel master SVG.
- `metadata/clickable_area_mapping_draft.json`: proposta draft, non definitiva, di mapping tra ID SVG e future aree manifest.
- `metadata/area_taxonomy_analysis.md`: analisi tecnica della tassonomia dedotta dal codice Flutter esistente.
- `metadata/anatomical_areas_taxonomy_draft.json`: proposta draft, non definitiva, della tassonomia iniziale delle aree.
- `metadata/taxonomy_human_review.md`: documento per revisione umana della tassonomia candidate.
- `metadata/taxonomy_human_review.csv`: versione tabellare della revisione umana.
- `metadata/anatomical_areas_proposed_final.json`: proposed final non definitiva della tassonomia, pronta per revisione prima della promozione.
- `metadata/anatomical_areas_proposed_final.md`: riepilogo leggibile della proposed final.

## Regole

- Non sovrascrivere il master SVG senza una fase dedicata.
- Non incorporare PNG raster dentro lo SVG cliccabile.
- Non collegare questa struttura a Flutter finche manifest e ID anatomici non sono validati.
- Quando una mappa clinica cambia in modo incompatibile, creare una nuova versione invece di rompere `v1`.

## Validator

Il validator tecnico vive in `tools/clinical_map_validator/`. Serve a controllare JSON, SVG e coerenza degli ID, ma non approva tassonomie cliniche.

Il validator puo leggere anche il draft tassonomico con l'opzione `--draft-taxonomy` e la proposed final con `--proposed-final-taxonomy`, ma questi file restano proposte non runtime.
