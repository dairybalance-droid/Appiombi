# Appiombi - Data Collection Functional Spec V1

## Scopo

Questo documento definisce la specifica funzionale V1 della raccolta dati Appiombi per:

- sessioni di lavoro
- visite vacca
- navigazione operativa durante la compilazione
- gestione locale/offline e sincronizzazione
- regole stabili per evitare ambiguita nei dati storici

La presente versione descrive il comportamento atteso dell'app mobile nativa Android/iOS. Non introduce nuove tabelle o nuove API: serve come riferimento funzionale per l'implementazione progressiva di UI, logica locale e sync.

## Principi Operativi

- Ogni dato raccolto deve essere tracciabile nel tempo.
- Una visita storica non deve essere sovrascritta da visite successive.
- La raccolta dati deve essere rapida, adatta all'uso in stalla e tollerante a connessione assente o instabile.
- La perdita dati deve essere evitata tramite salvataggio locale immediato e sincronizzazione appena possibile.
- In caso di conflitto multi-device, il sistema non deve scegliere automaticamente una versione distruggendo l'altra.

## Sessioni Di Lavoro

### Definizione

Una sessione di lavoro rappresenta un contenitore operativo entro cui vengono registrate una o piu visite vacca per una specifica stalla/farm.

Le tipologie di sessione V1 sono:

- Pareggio di mandria
- Pareggio su selezione
- Sessione urgenze
- Sessione ricontrolli

In V1 tutte le tipologie condividono lo stesso flusso operativo, ma il tipo sessione deve essere sempre salvato e mostrato come indicatore logico e visivo, perche in futuro statistiche, elaborati e report varieranno in base a questa classificazione.

### Una Sola Sessione Aperta Per Stalla

Regola V1:

- per ogni stalla/farm puo esistere una sola sessione aperta alla volta

Conseguenze operative:

- se esiste gia una sessione aperta per quella stalla, l'utente deve rientrare in quella sessione invece di crearne una nuova
- la creazione di una nuova sessione deve essere bloccata finche la sessione aperta non viene chiusa
- il sistema deve mantenere chiaro quale sessione e quella attualmente modificabile

### Sessione Multi-Giorno

Una sessione puo durare piu giorni.

Questo significa che:

- la sessione non e limitata al solo giorno di apertura
- l'utente puo riaprire la sessione aperta nei giorni successivi e continuare ad aggiungere o modificare capi all'interno di quella sessione
- la data di sessione va interpretata come riferimento operativo di apertura/stato, non come vincolo di utilizzo in giornata unica

### Chiusura E Riapertura

La sessione attuale puo essere chiusa dall'utente.

Per V1:

- la modifica e consentita sulla sessione attuale aperta
- in aggiunta, e consentita la riapertura della sola ultima sessione chiusa, per gestire chiusure accidentali
- sessioni storiche piu vecchie non devono essere modificabili nel flusso standard

## Visita Vacca

### Definizione

La visita vacca e l'entita storica unica dentro una sessione.

Ogni vacca salvata nella sessione genera una visita distinta, legata a:

- farm/stalla
- sessione
- capo

### Regola Storica Fondamentale

Le visite successive non modificano le visite precedenti.

Questo significa che:

- se il capo 123 viene visitato oggi in una sessione, quella visita resta uno snapshot storico
- se lo stesso capo viene rivisto in una sessione futura, si crea una nuova visita storica
- i dati storici precedenti restano consultabili ma non vengono sovrascritti

### Modificabilita

Per V1 e consentita la modifica solo di:

- visita appartenente alla sessione attuale aperta
- visita appartenente all'ultima sessione riaperta

Non e previsto modificare visite appartenenti a sessioni storiche piu vecchie nel normale flusso operativo.

## Regole Sul Campo Capo

### Obbligatorieta

Il campo `Capo` e obbligatorio.

Vincoli V1:

- tipo: integer
- puo essere positivo, zero o negativo
- non puo essere vuoto
- senza valore valido non e possibile confermare l'apertura della visita

### Apertura Automatica Popup Capo

Quando l'utente aggiunge una nuova vacca alla sessione:

- deve aprirsi automaticamente il popup del numero capo
- il popup e il primo passaggio obbligatorio prima di entrare nella scheda completa della vacca

### Duplicato Nella Stessa Sessione

Regola V1:

- lo stesso capo non puo comparire due volte nella stessa sessione

Se l'utente inserisce un numero capo gia presente nella sessione:

- il popup resta aperto
- non si procede alla visita
- viene mostrato solo questo messaggio:

`Capo già presente.`

Non devono comparire altri testi o spiegazioni in questo stato di errore.

## Flusso Operativo Di Sessione

### Elenco Capi Sessione

La pagina sessione mostra un elenco/tabella dei capi gia registrati nella sessione, con riepilogo operativo.

Per V1 l'elenco deve includere almeno:

- modifica capo
- numero capo
- lesione piu grave
- farmaci
- suole
- bende

### Aggiunta Nuovo Capo

Dal tasto aggiunta:

1. apertura popup Capo
2. validazione del numero
3. controllo duplicato nella sessione
4. accesso alla scheda di raccolta dati del capo

### Modifica Capo Gia Salvato

Dall'elenco sessione l'utente puo riaprire un capo gia registrato e modificarlo, ma solo entro le regole di modificabilita della sessione corrente o ultima sessione riaperta.

## Navigazione Della Scheda Vacca

La visita vacca e organizzata in tre sezioni principali:

- Dati generici
- Mappa unghioni
- Altre info

### Navigazione Circolare

La navigazione tra queste tre sezioni deve essere circolare.

Esempio:

- da `Dati generici` avanti va a `Mappa unghioni`
- da `Mappa unghioni` avanti va a `Altre info`
- da `Altre info` avanti torna a `Dati generici`

Allo stesso modo la navigazione indietro deve chiudere il ciclo in senso opposto.

### Salvataggio Implicito

Ogni volta che l'utente:

- usa le frecce di navigazione tra sezioni
- preme `Elenco`

il sistema deve eseguire salvataggio implicito locale dei dati correnti.

Obiettivo:

- l'utente non deve perdere quanto ha gia compilato passando da una sezione all'altra
- il ritorno all'elenco sessione non deve richiedere un salvataggio manuale esplicito separato

## Salvataggio, Autosave E Sync

### Salvataggio Immediato Locale

La raccolta dati V1 deve adottare una logica di salvataggio immediato/autosave locale.

Questo vale per:

- creazione nuova visita
- modifica progressiva dei campi
- passaggi tra sezioni
- ritorno all'elenco

### Sync Appena Possibile

Quando la connettivita e disponibile, il sistema deve sincronizzare appena possibile i dati locali con il backend.

### Regola Offline-First

L'assenza di rete non deve bloccare:

- apertura sessione
- aggiunta capo
- modifica visita
- consultazione dati locali gia presenti

## Gestione Conflitti Multi-Device

Appiombi deve supportare uso multi-device e multi-operatore.

Se due dispositivi producono modifiche incompatibili:

- il sistema non deve usare last write wins come strategia unica
- nessuna modifica deve essere persa automaticamente
- i conflitti devono essere tracciati e portati a revisione manuale

Per V1 la regola funzionale e:

- preservare entrambe le versioni quando necessario
- rendere evidente il conflitto
- richiedere decisione esplicita di revisione/sistemazione

## Elimina

La visita vacca deve prevedere azione `Elimina`.

Comportamento V1:

- l'azione apre conferma esplicita
- la cancellazione non deve avvenire al primo tocco senza conferma
- una volta confermata, la visita viene rimossa dal flusso operativo attuale secondo la strategia di soft delete/sync prevista dall'architettura offline-first

## Storico Capo

Lo storico capo deve essere consultabile senza sovrascrivere dati precedenti.

Questo implica che:

- aprire lo storico e una funzione di sola consultazione, salvo casi espliciti di modifica sulla sessione corrente/ultima riaperta
- la visualizzazione dello storico non deve alterare i dati della visita in corso
- una visita storica resta distinta da una visita nuova o corrente

## Menu A Tendina

Per V1 tutti i menu a tendina rilevanti devono avere:

- opzione vuota come default

Significato:

- nessuna scelta preselezionata
- l'utente deve scegliere intenzionalmente un valore quando necessario

## Mappa Unghioni

### Totale Aree Cliccabili V1

La mappa V1 deve supportare 80 aree cliccabili totali:

- 48 aree cornee
- 8 unghielli
- 16 aree cutanee centrali
- 8 aree cutanee laterali

Totale:

- `80 aree cliccabili`

### Principio Di Codifica Unica

Ogni area della mappa unghioni deve avere una codifica univoca e stabile.

La codifica deve permettere di distinguere almeno:

- arto/unghione
- macro-area
- tipologia di lesione o classificazione
- estensione

L'obiettivo e garantire:

- coerenza storica
- interrogabilita futura
- sincronizzazione multi-device affidabile

### Struttura Codifica V1

La mappa V1 comprende:

- 8 unghioni: `C1` ... `C8`
- 6 aree cornee per ogni unghione:
  - `B`
  - `S`
  - `P`
  - `APX`
  - `LBab`
  - `LBax`
- 8 unghielli:
  - `C1_UG` ... `C8_UG`
- 16 aree cutanee centrali:
  - `SKIN_12_Nod`, `SKIN_12_D`, `SKIN_12_ID`, `SKIN_12_Dors`
  - `SKIN_34_Nod`, `SKIN_34_D`, `SKIN_34_ID`, `SKIN_34_Dors`
  - `SKIN_56_Nod`, `SKIN_56_D`, `SKIN_56_ID`, `SKIN_56_Dors`
  - `SKIN_78_Nod`, `SKIN_78_D`, `SKIN_78_ID`, `SKIN_78_Dors`
- 8 aree cutanee laterali:
  - `SKIN_C1_LAT`
  - `SKIN_C2_LAT`
  - `SKIN_C3_LAT`
  - `SKIN_C4_LAT`
  - `SKIN_C5_LAT`
  - `SKIN_C6_LAT`
  - `SKIN_C7_LAT`
  - `SKIN_C8_LAT`

Significato delle nuove aree laterali:

- `SKIN_C1_LAT` = area cutanea laterale associata all'unghione 1
- `SKIN_C2_LAT` = area cutanea laterale associata all'unghione 2
- stessa logica fino a `SKIN_C8_LAT`

Le aree `SKIN_C*_LAT`:

- appartengono alla categoria `skin`
- usano lo stesso popup delle altre aree cutanee/Mortellaro
- vengono salvate solo nella visita corrente
- possono essere modificate nella visita corrente senza alterare visite precedenti

### Popup Aree Corno

Per le aree corno il popup deve contenere:

- `Tipologia`
- `Estensione`
- pulsante `Rimuovi`
- pulsante `Conferma`

### Popup Aree Cutanee

Per le aree cutanee il popup deve contenere:

- `Tipologia`
- `Estensione`
- pulsante `Rimuovi`
- pulsante `Conferma`

#### Tipologia

Una sola scelta:

- vuoto
- `1 - Precoce`
- `2 - Acuta`
- `3 - Guarigione`
- `4 - Cronica`
- `4.1 - Riacutizzata`

#### Estensione

Una sola scelta:

- vuoto
- `Focale`
- `Ampio`
- `Multi-zona`

#### Comportamento

- `Conferma` salva o aggiorna il dato e colora l'area
- `Rimuovi` svuota il dato e decolora l'area
- se un'area gia salvata viene ritoccata e modificata, il nuovo dato sovrascrive quello precedente nella stessa visita
- nessuna visita precedente deve essere modificata

## Effetti Attesi Sul Flusso UX

Il flusso V1 della raccolta dati deve risultare:

- veloce nell'aggiunta di nuovi capi
- stabile nel mantenere i dati gia inseriti
- chiaro nella separazione tra storico e modifica corrente
- robusto su piu giorni e piu dispositivi
- adatto a future evoluzioni senza cambiare la semantica dei dati raccolti

## Ambito Di Questa Versione

Questa specifica definisce il comportamento funzionale V1.

Non definisce ancora in dettaglio:

- layout finale completo di ogni singolo controllo UI
- formule statistiche definitive
- logica completa di sync conflict resolution lato backend
- regole cliniche di classificazione avanzata delle lesioni oltre i campi qui esplicitati

Questi punti saranno approfonditi in documenti o iterazioni successive, mantenendo pero ferme le regole base qui definite.
