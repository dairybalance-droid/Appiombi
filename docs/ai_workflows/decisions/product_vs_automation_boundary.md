# Product vs Automation Boundary

Codex puo automatizzare lavoro ripetibile, ma non deve prendere decisioni prodotto o cliniche importanti senza approvazione.

## Codex puo decidere autonomamente

- Struttura documentale per workflow AI.
- Checklist operative.
- Naming tecnico non clinico.
- Script di supporto senza impatto runtime.
- Esclusione di output generati dal commit.
- Report finale standard.

## Richiede approvazione umana

- Decisioni cliniche.
- Naming anatomico canonico.
- Tassonomie di lesioni o stadi.
- Modifiche allo schema database.
- Cambiamenti UX importanti.
- Introduzione o rimozione di asset clinici versionati.
- Migrazioni che cambiano compatibilita dei dati.

## Regola pratica

Se una modifica puo cambiare il significato clinico di un dato salvato, Codex deve fermarsi e chiedere conferma.
