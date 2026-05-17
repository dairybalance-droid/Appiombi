# Appiombi Repo Context

Appiombi e una app Flutter nativa per raccolta dati in ambito bovino, con backend Supabase e attenzione a flussi offline-first.

## Componenti principali

- `lib/`: codice Flutter.
- `supabase/`: schema, migrazioni e policy.
- `docs/`: specifiche prodotto, tecniche e workflow.
- `assets/`: asset usati dall'app.
- `tools/`: strumenti di supporto non runtime.

## Flutter

L'app usa Flutter, Riverpod, GoRouter e Supabase Flutter. La feature visite contiene gia modelli e widget per la mappa unghioni.

File rilevanti:

- `lib/features/visits/hoof_map_models.dart`
- `lib/features/visits/hoof_map_widget.dart`
- `lib/features/visits/cow_visit_page.dart`

## Supabase

Il database contiene gia una tabella per osservazioni cliniche:

- `claw_zone_observations`

La tabella salva osservazioni per visita, numero unghione, tipo zona, codice zona, gruppo osservazione e payload clinico.

## Offline-first

Il modello dati include campi di sync e tabelle per mutazioni offline. I task AI devono evitare modifiche database non richieste.

## Mappa unghioni

La mappa unghioni e un dominio clinico, non un semplice asset UI. Deve supportare:

- International Claw Map;
- aree cliccabili con ID stabili;
- manifest JSON;
- rendering responsive in Flutter;
- salvataggio DB per ogni click.

## SVG Genesis Pipeline

`tools/svg_genesis/` contiene una pipeline per confrontare PNG reference e SVG target:

- render SVG;
- overlay;
- diff;
- score JSON;
- report markdown.

## Asset UI/logo vs asset clinici

- Asset UI/logo: immagini decorative, loghi, icone, placeholder.
- Asset clinici versionati: reference, SVG master, SVG cliccabili e manifest anatomici.

Le mappe cliniche dovrebbero vivere in una struttura dedicata, per esempio:

```text
assets/clinical_maps/claw/international_claw_map/v1/
```
