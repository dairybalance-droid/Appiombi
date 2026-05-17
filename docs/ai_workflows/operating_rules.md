# Operating Rules

Queste regole valgono per tutti i task AI nel repository Appiombi.

## Controlli iniziali

- Controllare sempre branch attiva con `git branch --show-current`.
- Controllare sempre stato git con `git status --short`.
- Identificare file non tracciati prima di modificare qualsiasi cosa.
- Non perdere file non tracciati. Se serve cambiare branch, proporre backup manuale o stash esplicito.

## Regole Git

- Non fare commit se l'utente non lo chiede esplicitamente.
- Non fare push se l'utente non lo chiede esplicitamente.
- Non aggiungere file legacy o output generati senza istruzioni esplicite.
- Prima di un commit, mostrare chiaramente staged files e file esclusi.

## Asset e file sensibili

- Non modificare asset clinici senza istruzioni.
- Non modificare SVG master senza istruzioni.
- Non cancellare reference PNG.
- Non rasterizzare una PNG dentro uno SVG.
- Distinguere sempre tra file di runtime, file clinici, file legacy, output generati e file temporanei.

## Output generati

- Gli output di pipeline devono essere ignorati o esclusi dal commit, salvo richiesta esplicita.
- I file temporanei devono restare dentro la cartella output prevista e, quando possibile, essere rimossi automaticamente.

## Report finale

Ogni task deve terminare con un report finale standard:

- branch attiva;
- file creati o modificati;
- comandi eseguiti;
- output generati;
- test o verifiche;
- file esclusi dal commit;
- rischi residui;
- commit e push status.
