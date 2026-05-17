# Pre-Push Checklist

Usare questa checklist prima di ogni push.

## Controlli

- Eseguire `git branch --show-current`.
- Eseguire `git status --short`.
- Eseguire `git log --oneline -1`.
- Verificare che il commit giusto sia in HEAD.

## Sicurezza

- Non pushare da `main` salvo richiesta esplicita.
- Non fare push se ci sono commit non verificati.
- Non includere output generati.
- Non includere file legacy non richiesti.

## Push

- Usare `git push -u origin <branch>` per una branch nuova.
- Dopo il push, riportare branch remota e link PR se GitHub lo mostra.

## Report

- Indicare hash del commit.
- Indicare stato git finale.
- Confermare che non sono stati aggiunti file esclusi.
