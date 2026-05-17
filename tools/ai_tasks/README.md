# AI Tasks

Questa cartella contiene task manifest e template machine-readable per rendere ripetibili i workflow Codex.

Questi file sono strumenti di sviluppo e automazione. Non sono asset runtime dell'app e non devono essere usati dalla UI Flutter.

## Uso previsto

Un prompt breve puo indicare a Codex:

```text
Leggi tools/ai_tasks/tasks/svg_genesis_pipeline.json e segui il workflow collegato.
```

Il manifest dichiara:

- branch consigliata;
- path consentiti;
- path vietati;
- input richiesti;
- output attesi;
- comandi;
- checklist;
- template report.

## Futuro

Questi file potranno essere letti da script locali o GitHub Actions per validare task, staging e output.
