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

## Regole

- Non sovrascrivere il master SVG senza una fase dedicata.
- Non incorporare PNG raster dentro lo SVG cliccabile.
- Non collegare questa struttura a Flutter finche manifest e ID anatomici non sono validati.
- Quando una mappa clinica cambia in modo incompatibile, creare una nuova versione invece di rompere `v1`.
