# Clickable Map Engine Workflow

Workflow futuro per trasformare una mappa clinica versionata in un motore Flutter cliccabile.

## Pipeline concettuale

```text
manifest JSON
-> parser Dart typed
-> renderer responsive
-> hit-test
-> popup clinico
-> salvataggio DB
```

## Manifest JSON

Il manifest deve descrivere:

- `map_id`;
- `version`;
- canvas;
- asset SVG/reference;
- aree;
- ID SVG;
- codice clinico;
- tipo popup;
- gruppo osservazione.

## Parser Dart

Il parser deve convertire JSON in modelli typed, senza hardcodare nuove geometrie nel widget.

## Renderer responsive

Il renderer deve mantenere:

- aspect ratio stabile;
- hit-test coerente con scala;
- supporto touch;
- stato attivo delle aree;
- accessibilita di base.

## Popup

Il popup deve dipendere dal tipo area:

- horn;
- derma/skin;
- altri tipi futuri.

## Database

Il salvataggio deve usare ID clinici stabili:

- `claw_number`;
- `zone_type`;
- `zone_code`;
- `observation_group`;
- payload lesione/stadio;
- `is_active`.

Non salvare coordinate UI come fonte clinica primaria.

## Verifica

- Testare tap su area nota.
- Testare responsive su viewport piccoli.
- Verificare encode/decode osservazioni.
- Verificare che reset area non cancelli storia se il backend richiede audit.
