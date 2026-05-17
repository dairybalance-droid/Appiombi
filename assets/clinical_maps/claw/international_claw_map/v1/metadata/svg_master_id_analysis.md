# SVG Master ID Analysis

Analisi tecnica del master SVG per la mappa unghioni `international_claw_map` v1.

## Stato

Questo documento e una base di lavoro, non una decisione clinica definitiva. Gli ID anatomici e le tassonomie cliniche dovranno essere approvati in una fase successiva.

## File analizzati

- Master SVG: `../svg/master/hoof_single_card_master.svg`
- Clickable SVG placeholder: `../svg/clickable/hoof_single_card_clickable.svg`
- Manifest aree: `../manifests/anatomical_areas.json`
- Manifest mappa: `../manifests/map_manifest.json`

## ID trovati nel master SVG

| ID | Elemento SVG | Valutazione tecnica | Note |
| --- | --- | --- | --- |
| `card_background` | `rect` | non cliccabile | Sfondo della card, utile per visualizzazione ma non per hit-test clinico. |
| `card_border` | `path` | non cliccabile | Bordo decorativo/strutturale della card. |
| `C1_UG` | `path` | candidato cliccabile draft | Probabile area unghiello per C1. Richiede validazione clinica e geometrica. |
| `C2_UG` | `path` | candidato cliccabile draft | Probabile area unghiello per C2. Richiede validazione clinica e geometrica. |
| `SKIN_12_Nod` | `path` | candidato cliccabile draft | Probabile area cutanea/nodello tra C1 e C2. Richiede validazione clinica. |

## Struttura SVG osservata

Il master SVG e una bozza parziale. Contiene elementi strutturali della card e tre possibili elementi anatomici. Non contiene ancora l'intera International Claw Map, ne tutte le aree attese per gli otto unghioni.

Il clickable SVG attuale e un placeholder valido, con solo `clickable_canvas_placeholder`. Non contiene geometrie cliniche reali.

## Possibili candidati cliccabili

Questi ID possono diventare aree cliccabili solo dopo approvazione:

- `C1_UG`
- `C2_UG`
- `SKIN_12_Nod`

## Elementi non cliccabili

Questi ID non dovrebbero diventare aree cliniche:

- `card_background`
- `card_border`
- `clickable_canvas_placeholder`
- `title`
- `desc`

## Rischi e ambiguita

- Il master e incompleto: non rappresenta tutte le zone cliniche future.
- I suffissi `UG` e `Nod` sono interpretabili ma non devono essere considerati tassonomia definitiva.
- Il mapping tra ID SVG e campi `zone_type`, `zone_code`, `observation_group` richiede approvazione clinica.
- Il clickable SVG dovra ricevere geometrie reali prima di qualunque integrazione runtime.
- Non salvare coordinate UI nel database come fonte clinica primaria.
