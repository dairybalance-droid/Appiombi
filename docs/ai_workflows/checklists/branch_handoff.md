# Branch Handoff Checklist

Usare questa procedura per chiudere una branch e aprirne una nuova.

## Prima di cambiare branch

1. Eseguire `git status --short --branch`.
2. Identificare file modificati e non tracciati.
3. Se ci sono file non tracciati importanti, proporre backup manuale fuori dal repo.
4. Non cancellare file non tracciati.

## Chiusura branch

1. Verificare che commit e push siano gia completati, se richiesti.
2. Verificare che la PR sia stata aperta o mergiata, se richiesto.
3. Non creare nuova branch da una feature non mergiata se il lavoro deve partire da `main`.

## Creazione nuova branch da main

Dopo merge PR su GitHub:

```bash
git fetch origin
git checkout main
git pull origin main
git checkout -b feature/name
git status --short
```

## File non tracciati

Se Git blocca il cambio branch per file non tracciati:

1. Fermarsi.
2. Fare backup manuale.
3. Valutare `git stash push --include-untracked -m "message"` solo con conferma utente.
4. Non usare comandi distruttivi.
