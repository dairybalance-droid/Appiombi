# Pre-Commit Checklist

Usare questa checklist prima di ogni commit.

## Stato Git

- Eseguire `git status --short`.
- Eseguire `git diff --cached --name-only`.
- Verificare che la branch attiva sia quella attesa.

## Staging

- Staged files solo nei path previsti.
- Nessun file legacy aggiunto per errore.
- Nessun asset clinico aggiunto o modificato senza istruzioni.
- Nessun output generato aggiunto per errore.

## Verifiche

- Eseguire i test o comandi richiesti dal workflow.
- Se un comando non puo essere eseguito, documentare il motivo.
- Aggiornare report o documentazione se previsto.

## Prima del commit

- Rileggere la lista staged.
- Confermare che i file non tracciati da preservare sono ancora presenti.
- Usare un messaggio commit breve, chiaro e coerente con il task.
