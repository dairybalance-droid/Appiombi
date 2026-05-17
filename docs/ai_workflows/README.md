# Appiombi AI Workflows

Questa cartella contiene regole, checklist e procedure persistenti per far lavorare Codex sul repository Appiombi con prompt brevi e ripetibili.

Questi playbook sono strumenti di sviluppo: non fanno parte del runtime dell'app Flutter e non devono essere caricati dall'app in produzione.

## Come usarla

Prima di chiedere un task operativo a Codex, indica quali file leggere. Esempio:

```text
Leggi docs/ai_workflows/operating_rules.md,
docs/ai_workflows/workflows/svg_genesis.md e
tools/ai_tasks/tasks/svg_genesis_pipeline.json.
Poi esegui il task seguendo le checklist.
```

In questo modo non serve copiare ogni volta tutte le regole nella chat.

## File da leggere sempre

1. `docs/ai_workflows/operating_rules.md`
2. `docs/ai_workflows/repo_context.md`
3. La checklist adatta al momento: pre-commit, pre-push o branch handoff.
4. Il workflow specifico del task.
5. Il manifest task corrispondente in `tools/ai_tasks/tasks/`.

## Separazione delle responsabilita

- `docs/ai_workflows/` spiega regole, contesto e procedure per persone e AI.
- `tools/ai_tasks/` contiene manifest e template strutturati, pronti per futuri script o GitHub Actions.
- Le decisioni prodotto e cliniche restano separate dai task automatici.

## Regola pratica

Se un task richiede decisioni cliniche, naming anatomico, struttura database o UX importante, Codex deve fermarsi e chiedere approvazione umana.
