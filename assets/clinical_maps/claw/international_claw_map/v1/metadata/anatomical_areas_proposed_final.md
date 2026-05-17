# Anatomical Areas Proposed Final

Proposta finale non definitiva per la tassonomia delle aree cliccabili della mappa unghioni.

## Stato

- Status: `proposed_final_pending_review`
- `is_definitive`: `false`
- Aree: 80
- Manifest definitivo non modificato: `../manifests/anatomical_areas.json`
- Uso previsto: revisione finale prima della promozione manuale nel manifest definitivo.

## Decisioni Applicate

- La tassonomia usa solo due macro-tipologie: `horn` e `derma`.
- `accessory_digit` / unghiello / UG e trattato come `horn`.
- Le zone skin/periungueali sono trattate come `derma`.
- Le aree `horn` usano `observation_group=horn_lesion` e `popup_kind=horn`.
- Le aree `derma` usano `observation_group=derma_lesion` e `popup_kind=skin`.
- Gli ID white line usano `WL_AB` e `WL_AX`; gli ID legacy restano documentati.

## WL_AB / WL_AX e legacy_id

- `LBab` e stato normalizzato in `WL_AB` / `white_line_abaxial`.
- `LBax` e stato normalizzato in `WL_AX` / `white_line_axial`.
- Il vecchio ID resta in `legacy_id` e `expected_legacy_svg_element_id` per futura migrazione.
- Lo SVG cliccabile futuro dovra usare gli ID nuovi oppure dichiarare una migrazione esplicita.

## Tabella Sintetica

| id | legacy_id | claw_number | related_claws | limb | digit | zone_type | zone_code | observation_group | popup_kind | label_it | label_en | approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `C1_B` | `` | 1 | [1] | left_front | external | horn | bulb | horn_lesion | horn | Bulbo | Bulb | requires_human_approval |
| `C1_S` | `` | 1 | [1] | left_front | external | horn | sole | horn_lesion | horn | Suola | Sole | requires_human_approval |
| `C1_P` | `` | 1 | [1] | left_front | external | horn | toe | horn_lesion | horn | Punta | Toe | requires_human_approval |
| `C1_APX` | `` | 1 | [1] | left_front | external | horn | apex | horn_lesion | horn | Apice | Apex | requires_human_approval |
| `C1_WL_AB` | `C1_LBab` | 1 | [1] | left_front | external | horn | white_line_abaxial | horn_lesion | horn | Linea bianca abassiale | Abaxial white line | requires_human_approval |
| `C1_WL_AX` | `C1_LBax` | 1 | [1] | left_front | external | horn | white_line_axial | horn_lesion | horn | Linea bianca assiale | Axial white line | requires_human_approval |
| `C1_UG` | `` | 1 | [1] | left_front | external | horn | accessory_digit | horn_lesion | horn | Unghiello | Accessory digit | requires_human_approval |
| `SKIN_C1_LAT` | `` | 1 | [1] | left_front | external | derma | skin_lateral | derma_lesion | skin | Cute laterale | Lateral skin | requires_human_approval |
| `C2_B` | `` | 2 | [2] | left_front | internal | horn | bulb | horn_lesion | horn | Bulbo | Bulb | requires_human_approval |
| `C2_S` | `` | 2 | [2] | left_front | internal | horn | sole | horn_lesion | horn | Suola | Sole | requires_human_approval |
| `C2_P` | `` | 2 | [2] | left_front | internal | horn | toe | horn_lesion | horn | Punta | Toe | requires_human_approval |
| `C2_APX` | `` | 2 | [2] | left_front | internal | horn | apex | horn_lesion | horn | Apice | Apex | requires_human_approval |
| `C2_WL_AB` | `C2_LBab` | 2 | [2] | left_front | internal | horn | white_line_abaxial | horn_lesion | horn | Linea bianca abassiale | Abaxial white line | requires_human_approval |
| `C2_WL_AX` | `C2_LBax` | 2 | [2] | left_front | internal | horn | white_line_axial | horn_lesion | horn | Linea bianca assiale | Axial white line | requires_human_approval |
| `C2_UG` | `` | 2 | [2] | left_front | internal | horn | accessory_digit | horn_lesion | horn | Unghiello | Accessory digit | requires_human_approval |
| `SKIN_C2_LAT` | `` | 2 | [2] | left_front | internal | derma | skin_lateral | derma_lesion | skin | Cute laterale | Lateral skin | requires_human_approval |
| `SKIN_12_Nod` | `` |  | [1,2] |  | central | derma | skin_nodello | derma_lesion | skin | Nodello | Pastern | requires_human_approval |
| `SKIN_12_D` | `` |  | [1,2] |  | central | derma | skin_digital | derma_lesion | skin | Digitale | Digital skin | requires_human_approval |
| `SKIN_12_ID` | `` |  | [1,2] |  | central | derma | skin_interdigital | derma_lesion | skin | Interdigitale | Interdigital skin | requires_human_approval |
| `SKIN_12_Dors` | `` |  | [1,2] |  | central | derma | skin_dorsal | derma_lesion | skin | Dorsale | Dorsal skin | requires_human_approval |
| `C3_B` | `` | 3 | [3] | right_front | internal | horn | bulb | horn_lesion | horn | Bulbo | Bulb | requires_human_approval |
| `C3_S` | `` | 3 | [3] | right_front | internal | horn | sole | horn_lesion | horn | Suola | Sole | requires_human_approval |
| `C3_P` | `` | 3 | [3] | right_front | internal | horn | toe | horn_lesion | horn | Punta | Toe | requires_human_approval |
| `C3_APX` | `` | 3 | [3] | right_front | internal | horn | apex | horn_lesion | horn | Apice | Apex | requires_human_approval |
| `C3_WL_AB` | `C3_LBab` | 3 | [3] | right_front | internal | horn | white_line_abaxial | horn_lesion | horn | Linea bianca abassiale | Abaxial white line | requires_human_approval |
| `C3_WL_AX` | `C3_LBax` | 3 | [3] | right_front | internal | horn | white_line_axial | horn_lesion | horn | Linea bianca assiale | Axial white line | requires_human_approval |
| `C3_UG` | `` | 3 | [3] | right_front | internal | horn | accessory_digit | horn_lesion | horn | Unghiello | Accessory digit | requires_human_approval |
| `SKIN_C3_LAT` | `` | 3 | [3] | right_front | internal | derma | skin_lateral | derma_lesion | skin | Cute laterale | Lateral skin | requires_human_approval |
| `C4_B` | `` | 4 | [4] | right_front | external | horn | bulb | horn_lesion | horn | Bulbo | Bulb | requires_human_approval |
| `C4_S` | `` | 4 | [4] | right_front | external | horn | sole | horn_lesion | horn | Suola | Sole | requires_human_approval |
| `C4_P` | `` | 4 | [4] | right_front | external | horn | toe | horn_lesion | horn | Punta | Toe | requires_human_approval |
| `C4_APX` | `` | 4 | [4] | right_front | external | horn | apex | horn_lesion | horn | Apice | Apex | requires_human_approval |
| `C4_WL_AB` | `C4_LBab` | 4 | [4] | right_front | external | horn | white_line_abaxial | horn_lesion | horn | Linea bianca abassiale | Abaxial white line | requires_human_approval |
| `C4_WL_AX` | `C4_LBax` | 4 | [4] | right_front | external | horn | white_line_axial | horn_lesion | horn | Linea bianca assiale | Axial white line | requires_human_approval |
| `C4_UG` | `` | 4 | [4] | right_front | external | horn | accessory_digit | horn_lesion | horn | Unghiello | Accessory digit | requires_human_approval |
| `SKIN_C4_LAT` | `` | 4 | [4] | right_front | external | derma | skin_lateral | derma_lesion | skin | Cute laterale | Lateral skin | requires_human_approval |
| `SKIN_34_Nod` | `` |  | [3,4] |  | central | derma | skin_nodello | derma_lesion | skin | Nodello | Pastern | requires_human_approval |
| `SKIN_34_D` | `` |  | [3,4] |  | central | derma | skin_digital | derma_lesion | skin | Digitale | Digital skin | requires_human_approval |
| `SKIN_34_ID` | `` |  | [3,4] |  | central | derma | skin_interdigital | derma_lesion | skin | Interdigitale | Interdigital skin | requires_human_approval |
| `SKIN_34_Dors` | `` |  | [3,4] |  | central | derma | skin_dorsal | derma_lesion | skin | Dorsale | Dorsal skin | requires_human_approval |
| `C5_B` | `` | 5 | [5] | left_hind | external | horn | bulb | horn_lesion | horn | Bulbo | Bulb | requires_human_approval |
| `C5_S` | `` | 5 | [5] | left_hind | external | horn | sole | horn_lesion | horn | Suola | Sole | requires_human_approval |
| `C5_P` | `` | 5 | [5] | left_hind | external | horn | toe | horn_lesion | horn | Punta | Toe | requires_human_approval |
| `C5_APX` | `` | 5 | [5] | left_hind | external | horn | apex | horn_lesion | horn | Apice | Apex | requires_human_approval |
| `C5_WL_AB` | `C5_LBab` | 5 | [5] | left_hind | external | horn | white_line_abaxial | horn_lesion | horn | Linea bianca abassiale | Abaxial white line | requires_human_approval |
| `C5_WL_AX` | `C5_LBax` | 5 | [5] | left_hind | external | horn | white_line_axial | horn_lesion | horn | Linea bianca assiale | Axial white line | requires_human_approval |
| `C5_UG` | `` | 5 | [5] | left_hind | external | horn | accessory_digit | horn_lesion | horn | Unghiello | Accessory digit | requires_human_approval |
| `SKIN_C5_LAT` | `` | 5 | [5] | left_hind | external | derma | skin_lateral | derma_lesion | skin | Cute laterale | Lateral skin | requires_human_approval |
| `C6_B` | `` | 6 | [6] | left_hind | internal | horn | bulb | horn_lesion | horn | Bulbo | Bulb | requires_human_approval |
| `C6_S` | `` | 6 | [6] | left_hind | internal | horn | sole | horn_lesion | horn | Suola | Sole | requires_human_approval |
| `C6_P` | `` | 6 | [6] | left_hind | internal | horn | toe | horn_lesion | horn | Punta | Toe | requires_human_approval |
| `C6_APX` | `` | 6 | [6] | left_hind | internal | horn | apex | horn_lesion | horn | Apice | Apex | requires_human_approval |
| `C6_WL_AB` | `C6_LBab` | 6 | [6] | left_hind | internal | horn | white_line_abaxial | horn_lesion | horn | Linea bianca abassiale | Abaxial white line | requires_human_approval |
| `C6_WL_AX` | `C6_LBax` | 6 | [6] | left_hind | internal | horn | white_line_axial | horn_lesion | horn | Linea bianca assiale | Axial white line | requires_human_approval |
| `C6_UG` | `` | 6 | [6] | left_hind | internal | horn | accessory_digit | horn_lesion | horn | Unghiello | Accessory digit | requires_human_approval |
| `SKIN_C6_LAT` | `` | 6 | [6] | left_hind | internal | derma | skin_lateral | derma_lesion | skin | Cute laterale | Lateral skin | requires_human_approval |
| `SKIN_56_Nod` | `` |  | [5,6] |  | central | derma | skin_nodello | derma_lesion | skin | Nodello | Pastern | requires_human_approval |
| `SKIN_56_D` | `` |  | [5,6] |  | central | derma | skin_digital | derma_lesion | skin | Digitale | Digital skin | requires_human_approval |
| `SKIN_56_ID` | `` |  | [5,6] |  | central | derma | skin_interdigital | derma_lesion | skin | Interdigitale | Interdigital skin | requires_human_approval |
| `SKIN_56_Dors` | `` |  | [5,6] |  | central | derma | skin_dorsal | derma_lesion | skin | Dorsale | Dorsal skin | requires_human_approval |
| `C7_B` | `` | 7 | [7] | right_hind | internal | horn | bulb | horn_lesion | horn | Bulbo | Bulb | requires_human_approval |
| `C7_S` | `` | 7 | [7] | right_hind | internal | horn | sole | horn_lesion | horn | Suola | Sole | requires_human_approval |
| `C7_P` | `` | 7 | [7] | right_hind | internal | horn | toe | horn_lesion | horn | Punta | Toe | requires_human_approval |
| `C7_APX` | `` | 7 | [7] | right_hind | internal | horn | apex | horn_lesion | horn | Apice | Apex | requires_human_approval |
| `C7_WL_AB` | `C7_LBab` | 7 | [7] | right_hind | internal | horn | white_line_abaxial | horn_lesion | horn | Linea bianca abassiale | Abaxial white line | requires_human_approval |
| `C7_WL_AX` | `C7_LBax` | 7 | [7] | right_hind | internal | horn | white_line_axial | horn_lesion | horn | Linea bianca assiale | Axial white line | requires_human_approval |
| `C7_UG` | `` | 7 | [7] | right_hind | internal | horn | accessory_digit | horn_lesion | horn | Unghiello | Accessory digit | requires_human_approval |
| `SKIN_C7_LAT` | `` | 7 | [7] | right_hind | internal | derma | skin_lateral | derma_lesion | skin | Cute laterale | Lateral skin | requires_human_approval |
| `C8_B` | `` | 8 | [8] | right_hind | external | horn | bulb | horn_lesion | horn | Bulbo | Bulb | requires_human_approval |
| `C8_S` | `` | 8 | [8] | right_hind | external | horn | sole | horn_lesion | horn | Suola | Sole | requires_human_approval |
| `C8_P` | `` | 8 | [8] | right_hind | external | horn | toe | horn_lesion | horn | Punta | Toe | requires_human_approval |
| `C8_APX` | `` | 8 | [8] | right_hind | external | horn | apex | horn_lesion | horn | Apice | Apex | requires_human_approval |
| `C8_WL_AB` | `C8_LBab` | 8 | [8] | right_hind | external | horn | white_line_abaxial | horn_lesion | horn | Linea bianca abassiale | Abaxial white line | requires_human_approval |
| `C8_WL_AX` | `C8_LBax` | 8 | [8] | right_hind | external | horn | white_line_axial | horn_lesion | horn | Linea bianca assiale | Axial white line | requires_human_approval |
| `C8_UG` | `` | 8 | [8] | right_hind | external | horn | accessory_digit | horn_lesion | horn | Unghiello | Accessory digit | requires_human_approval |
| `SKIN_C8_LAT` | `` | 8 | [8] | right_hind | external | derma | skin_lateral | derma_lesion | skin | Cute laterale | Lateral skin | requires_human_approval |
| `SKIN_78_Nod` | `` |  | [7,8] |  | central | derma | skin_nodello | derma_lesion | skin | Nodello | Pastern | requires_human_approval |
| `SKIN_78_D` | `` |  | [7,8] |  | central | derma | skin_digital | derma_lesion | skin | Digitale | Digital skin | requires_human_approval |
| `SKIN_78_ID` | `` |  | [7,8] |  | central | derma | skin_interdigital | derma_lesion | skin | Interdigitale | Interdigital skin | requires_human_approval |
| `SKIN_78_Dors` | `` |  | [7,8] |  | central | derma | skin_dorsal | derma_lesion | skin | Dorsale | Dorsal skin | requires_human_approval |

## Resta Da Revisionare

- Questo file non e il manifest definitivo.
- Le decisioni macro approvate sono gia applicate; resta da verificare l'allineamento terminologico con International Claw Map ufficiale.
- Resta da confermare la corrispondenza esatta con i path/ID dello SVG cliccabile finale.
- La promozione in `manifests/anatomical_areas.json` deve avvenire in una fase dedicata.
