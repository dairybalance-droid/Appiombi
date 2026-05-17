# Hoof Map Area Taxonomy Analysis

Analisi tecnica per una tassonomia iniziale delle aree cliccabili della mappa unghioni.

## Stato

Questo documento e una proposta draft. Non modifica il runtime Flutter, non modifica `anatomical_areas.json` e non approva alcuna tassonomia clinica definitiva.

## File analizzati

- `lib/features/visits/hoof_map_models.dart`
- `lib/features/visits/hoof_map_widget.dart`
- `assets/clinical_maps/claw/international_claw_map/v1/manifests/anatomical_areas.json`
- `assets/clinical_maps/claw/international_claw_map/v1/metadata/clickable_area_mapping_draft.json`
- `tools/clinical_map_validator/validate_clinical_map.py`

## Sintesi dal codice Flutter

Il codice Flutter contiene gia una mappa generativa con:

- 4 coppie di unghioni: `AS`, `AD`, `PS`, `PD`;
- 8 unghioni canonici, numerati da 1 a 8;
- 80 zone totali attese (`hoofMapZoneCount = 80`);
- 7 zone per ogni unghione;
- 6 zone non cornee/cutanee per ogni coppia.

Il widget attuale usa ancora la PNG in `assets/images/hoof_single_card_reference.png` e geometrie hardcoded in Dart. Questa analisi non cambia quel comportamento.

## Coppie dedotte

| footLabel | pairCode | unghione sinistro visivo | unghione destro visivo | nota |
| --- | --- | --- | --- | --- |
| `AS` | `12` | C1 | C2 | anteriore sinistro |
| `AD` | `34` | C3 | C4 | anteriore destro |
| `PS` | `56` | C5 | C6 | posteriore sinistro |
| `PD` | `78` | C7 | C8 | posteriore destro |

## Zone per ogni unghione

Queste zone sono dedotte dai codici e dalle label Flutter. Restano draft finche non approvate clinicamente.

| Suffisso | Esempio ID | Label Flutter | Famiglia Flutter | Popup Flutter | Stato |
| --- | --- | --- | --- | --- | --- |
| `B` | `C1_B` | Bulbo | horn | horn | requires_human_approval |
| `S` | `C1_S` | Suola | horn | horn | requires_human_approval |
| `P` | `C1_P` | Punta | horn | horn | requires_human_approval |
| `APX` | `C1_APX` | Apice | horn | horn | requires_human_approval |
| `LBab` | `C1_LBab` | Linea bianca abassiale | horn | horn | requires_human_approval |
| `LBax` | `C1_LBax` | Linea bianca assiale | horn | horn | requires_human_approval |
| `UG` | `C1_UG` | Unghiello | accessoryDigit | horn | requires_human_approval |

## Zone centrali per coppia

| Pattern ID | Label Flutter | Famiglia Flutter | Popup Flutter | Stato |
| --- | --- | --- | --- | --- |
| `SKIN_<pair>_Nod` | Nodello | skin | skin | requires_human_approval |
| `SKIN_<pair>_D` | Digitale | skin | skin | requires_human_approval |
| `SKIN_<pair>_ID` | Interdigitale | skin | skin | requires_human_approval |
| `SKIN_<pair>_Dors` | Dorsale | skin | skin | requires_human_approval |

## Zone laterali per unghione

| Pattern ID | Label Flutter | Famiglia Flutter | Popup Flutter | Stato |
| --- | --- | --- | --- | --- |
| `SKIN_C<n>_LAT` | Cute laterale | skin | skin | requires_human_approval |

## Conteggio candidate

- 8 unghioni x 7 zone = 56 zone.
- 4 coppie x 4 zone centrali = 16 zone.
- 8 unghioni x 1 zona laterale = 8 zone.
- Totale candidate dedotte dal codice Flutter: 80.

## Relazione con SVG corrente

Il master SVG attuale contiene solo questi ID anatomici candidati:

- `C1_UG`
- `C2_UG`
- `SKIN_12_Nod`

Il clickable SVG e ancora placeholder. Quindi la tassonomia draft puo descrivere 80 candidate, ma la geometria SVG reale non esiste ancora per la maggior parte delle aree.

## Ambiguita cliniche

Richiedono approvazione umana:

- se `accessoryDigit` debba diventare `zone_type = horn`, `derma`, o un tipo separato;
- se `skin` debba mappare sempre a `zone_type = derma`;
- nomi canonici inglesi e italiani;
- `zone_code` definitivo da salvare nel database;
- `observation_group` definitivo;
- eventuale allineamento con International Claw Map ufficiale;
- promozione da draft a `anatomical_areas.json`.

## Raccomandazione

Mantenere `anatomical_areas_taxonomy_draft.json` come fonte di proposta tecnica. Promuovere in `manifests/anatomical_areas.json` solo dopo revisione clinica e dopo la creazione dello SVG cliccabile con ID corrispondenti.
