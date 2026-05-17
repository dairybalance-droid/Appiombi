# Clinical Map Asset Structure Workflow

Workflow per creare una struttura stabile per asset clinici della mappa unghioni.

## Scopo

Separare asset clinici versionati da asset UI/logo.

## Struttura target

```text
assets/clinical_maps/claw/international_claw_map/v1/
  reference/
  svg/
    master/
    clickable/
  manifests/
  metadata/
```

## File previsti

- Reference PNG in `reference/`.
- SVG master in `svg/master/`.
- SVG clickable in `svg/clickable/`.
- Manifest aree anatomiche in `manifests/anatomical_areas.json`.
- Manifest mappa in `manifests/map_manifest.json`.
- Note operative in `metadata/README.md`.

## Regole

- Non cancellare asset esistenti finche Flutter non e aggiornato.
- Preferire copia iniziale a spostamento, se serve preservare compatibilita.
- Non modificare master SVG durante la riorganizzazione.
- Non creare tassonomie cliniche nuove senza approvazione.

## Collegamento con Flutter

Aggiornare Flutter solo in una fase dedicata:

1. Registrare asset in `pubspec.yaml`.
2. Leggere manifest JSON.
3. Collegare ID area a hit-test e salvataggio DB.
4. Verificare rendering responsive.

## Output attesi

- Struttura cartelle cliniche.
- Manifest iniziali.
- Documentazione breve.
- Nessun cambiamento UX non richiesto.
