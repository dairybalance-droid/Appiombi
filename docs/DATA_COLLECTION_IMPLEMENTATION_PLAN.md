# Appiombi - Data Collection Implementation Plan

## Scopo

Questo documento traduce [DATA_COLLECTION_SPEC.md](</C:/Users/syste/Documents/New project 2/Appiombi/docs/DATA_COLLECTION_SPEC.md>) in un piano tecnico di implementazione ordinato.

Obiettivo:

- trasformare le regole funzionali della raccolta dati in una struttura dati e in un percorso implementativo chiaro
- preparare il lavoro su database, servizi, UI, offline e sync
- evitare modifiche premature o incoerenti allo schema e alla logica applicativa

Questo documento non introduce codice, non crea migrazioni e non modifica lo stato attuale del progetto. Serve come piano di esecuzione tecnica.

## 1. Modello Dati Proposto

### Sessioni Di Lavoro

Entita proposta:

- `trimming_sessions`

Scopo:

- rappresentare la sessione operativa di una stalla
- distinguere il tipo sessione
- mantenere stato aperto/chiuso/riaperto
- fungere da contenitore di tutte le visite vacca registrate in quel ciclo di lavoro

Attributi logici principali:

- `id`
- `farm_id`
- `session_type`
- `status`
- `opened_at`
- `closed_at`
- `reopened_at`
- `created_by`
- `updated_by`
- `notes`
- campi sync/offline gia coerenti con l'architettura del progetto

### Visite Vacca

Entita proposta:

- `cow_visits`

Scopo:

- rappresentare la visita storica unica di un capo dentro una sessione

Principio:

- una visita appartiene a una sola sessione
- una nuova visita futura dello stesso capo crea una nuova riga storica
- non modifica la visita precedente

Attributi logici principali:

- `id`
- `farm_id`
- `session_id`
- `cow_id` oppure riferimento logico al capo aziendale
- `cow_number`
- `visit_date`
- `is_deleted` o `deleted_at` secondo la strategia gia prevista
- campi clinici base
- campi sync/offline

### Osservazioni Mappa Unghioni

Entita proposta:

- `claw_zone_observations`

Scopo:

- memorizzare in modo atomico le singole osservazioni della mappa

Principio:

- una visita puo avere zero o piu osservazioni
- ogni osservazione e riferita a una zona codificata in modo univoco
- ogni osservazione deve distinguere almeno horn / skin / accessory_digit

Attributi logici principali:

- `id`
- `farm_id`
- `session_id`
- `cow_visit_id`
- `zone_code`
- `zone_category`
- `lesion_type`
- `mortellaro_stage`
- `extension_grade`
- `created_at`
- `updated_at`
- campi sync/offline

### Altre Info

Le informazioni complementari della visita possono restare:

- in `cow_visits` se semplici e stabili
- in una tabella separata tipo `cow_visit_additional_info` se si prevede crescita significativa

Per V1 la direzione piu semplice e:

- mantenere in `cow_visits` i campi clinici strutturati principali
- separare solo cio che e realmente multi-riga o altamente estendibile

Esempi di campi gestibili direttamente in `cow_visits`:

- `sole_count`
- `bandage_count`
- `antibiotic_required`
- `anti_inflammatory_required`
- `straw_box_required`
- `laminitis_grade`
- `twisted_claw_grade`
- `notes`

### Storico Capo

Lo storico capo non richiede necessariamente una tabella autonoma.

Puo essere ottenuto da:

- `cow_visits`
- join con `trimming_sessions`
- join con `claw_zone_observations`

In pratica:

- lo storico e una vista logica sul passato delle visite di quel capo nella stessa farm
- l'implementazione dovra privilegiare query ordinate per data e sessione

### Gestione Conflitti Multi-Device

Entita gia coerenti col progetto:

- `sync_mutations`
- `sync_conflicts`

Estensione logica proposta per la raccolta dati:

- supportare conflitti su sessione
- supportare conflitti su visita vacca
- supportare conflitti su zone mappa

Campi logici utili a livello record applicativo:

- `needs_conflict_resolution`
- `original_cow_number`
- `conflict_reason`
- `conflict_group_id`

## 2. Tabelle Necessarie O Da Verificare

## `trimming_sessions`

- scopo: sessione di lavoro della stalla
- campi principali:
  - `id`
  - `farm_id`
  - `session_type`
  - `status`
  - `opened_at`
  - `closed_at`
  - `reopened_at`
  - `created_by`
  - `updated_by`
  - `sync_status`
  - `deleted_at`
- relazioni:
  - molti-a-uno verso `farms`
  - molti-a-uno verso `profiles`
  - uno-a-molti verso `cow_visits`
- vincoli importanti:
  - sessione riferita sempre a una sola farm
  - una sola sessione aperta per farm
  - `session_type` obbligatorio
- indici utili:
  - indice su `(farm_id, status)`
  - indice su `(farm_id, opened_at desc)`
  - indice su `(farm_id, deleted_at)`

## `cow_visits`

- scopo: singola visita storica di un capo dentro una sessione
- campi principali:
  - `id`
  - `farm_id`
  - `session_id`
  - `cow_id`
  - `cow_number`
  - `visit_date`
  - `sole_count`
  - `bandage_count`
  - `antibiotic_required`
  - `anti_inflammatory_required`
  - `straw_box_required`
  - `laminitis_grade`
  - `twisted_claw_grade`
  - `notes`
  - `needs_conflict_resolution`
  - `original_cow_number`
  - `conflict_reason`
  - `sync_status`
  - `deleted_at`
- relazioni:
  - molti-a-uno verso `trimming_sessions`
  - molti-a-uno verso `farms`
  - opzionale verso `cows`
  - uno-a-molti verso `claw_zone_observations`
- vincoli importanti:
  - stesso capo non duplicabile nella stessa sessione
  - `cow_number` obbligatorio
  - `cow_number` integer ammesso anche negativo
- indici utili:
  - indice univoco su `(session_id, cow_number)` filtrato su record non eliminati
  - indice su `(farm_id, cow_number, visit_date desc)`
  - indice su `(session_id, deleted_at)`

## `claw_zone_observations`

- scopo: osservazioni elementari della mappa unghioni
- campi principali:
  - `id`
  - `farm_id`
  - `session_id`
  - `cow_visit_id`
  - `zone_code`
  - `zone_category`
  - `lesion_type`
  - `mortellaro_stage`
  - `extension_grade`
  - `created_at`
  - `updated_at`
  - `sync_status`
  - `deleted_at`
- relazioni:
  - molti-a-uno verso `cow_visits`
  - molti-a-uno verso `trimming_sessions`
  - molti-a-uno verso `farms`
- vincoli importanti:
  - `zone_code` obbligatorio
  - `zone_category` coerente con il tipo di zona
  - per horn non usare campi Mortellaro
  - per skin usare classificazione cute/Mortellaro
- indici utili:
  - indice su `(cow_visit_id, zone_code)`
  - indice su `(farm_id, session_id)`

## `cows`

- scopo: anagrafica minima del capo per azienda
- campi principali da verificare:
  - `id`
  - `farm_id`
  - `cow_identifier` o equivalente
  - eventuali metadati di anagrafica
- relazioni:
  - uno-a-molti verso `cow_visits`
- vincoli importanti:
  - unicita del capo dentro la farm
- indici utili:
  - indice univoco su `(farm_id, cow_identifier)`

## `sync_mutations`

- scopo: coda di operazioni locali da sincronizzare
- campi principali da verificare:
  - `id`
  - `device_id`
  - `entity_type`
  - `entity_id`
  - `operation_type`
  - `payload`
  - `sync_status`
  - `retry_count`
  - `last_attempt_at`
- relazioni:
  - logica verso qualunque entita sincronizzata
- vincoli importanti:
  - ordine locale coerente
  - tracciamento retry e fallimento
- indici utili:
  - indice su `(device_id, sync_status, created_at)`

## `sync_conflicts`

- scopo: registrare conflitti multi-device o multi-operatore
- campi principali da verificare:
  - `id`
  - `entity_type`
  - `entity_id`
  - `farm_id`
  - `local_payload`
  - `remote_payload`
  - `conflict_reason`
  - `resolution_status`
  - `resolved_by`
  - `resolved_at`
- relazioni:
  - logica verso i record in conflitto
- vincoli importanti:
  - nessuna perdita automatica di dati
- indici utili:
  - indice su `(farm_id, resolution_status, created_at desc)`

## 3. Regole Fondamentali

### Una Sola Sessione Aperta Per Stalla

- per ogni `farm_id` puo esistere una sola sessione con stato aperto

### Sessione Multi-Giorno

- la sessione puo restare aperta per piu giorni senza perdere continuita

### Anti-Duplicato Del Capo

- lo stesso `cow_number` non puo comparire due volte nella stessa sessione
- il controllo va eseguito:
  - localmente appena si conferma il popup capo
  - lato backend/sync come vincolo di sicurezza

### Visita Storica Immutabile Nel Significato

- una nuova visita non sovrascrive visite precedenti
- eventuali modifiche sono ammesse solo nella sessione attuale o nell'ultima sessione riaperta

### Finestra Di Modifica

- modifica ammessa solo su:
  - sessione attuale aperta
  - ultima sessione chiusa ma riaperta

### Annulla Popup Capo

- se l'utente annulla il popup numero capo, si torna all'elenco sessione
- non si crea alcuna visita parziale

### Gestione Duplicato Nel Popup

- se il numero capo e gia presente nella sessione:
  - il popup resta aperto
  - il messaggio e solo:
    - `Capo già presente.`

## 4. Strategia Offline-First E Sync

### Salvataggio Locale Immediato

Ogni modifica operativa deve essere salvata localmente subito o al massimo al cambio sezione/azione:

- conferma popup capo
- frecce tra sezioni
- pulsante `Elenco`
- modifica campi
- elimina

### Sync Appena Possibile

Quando la connessione e disponibile:

- sincronizzare la sessione
- sincronizzare le visite vacca
- sincronizzare le osservazioni mappa
- sincronizzare gli aggiornamenti delle altre info

### Gestione Conflitti Multi-Device

In caso di collisione sui dati:

- non usare last-write-wins come soluzione unica
- conservare il dato locale e quello remoto
- marcare il record come da risolvere

### Proposta Di Conservazione Senza Perdita

Campi proposti a livello applicativo:

- `needs_conflict_resolution`
- `original_cow_number`
- `conflict_reason`

Per i duplicati non riconciliabili automaticamente:

- creare una copia di lavoro disambiguata con prefisso `999`
- mantenere il numero originale in `original_cow_number`
- segnare il record per revisione manuale

Esempio:

- capo originale: `234`
- duplicato in conflitto: `999234`
- `original_cow_number = 234`
- `needs_conflict_resolution = true`
- `conflict_reason = duplicate_cow_number_in_session`

Questo consente di:

- non perdere il dato
- evitare collisioni tecniche immediate
- rendere evidente che serve revisione

## 5. Codifica Zone Mappa

## Principio

La codifica deve essere univoca, leggibile e stabile.

Ogni codice deve permettere di capire:

- unghione o area cutanea
- zona anatomica
- categoria di osservazione

## Totale Aree Cliccabili V1

La configurazione V1 della mappa deve prevedere:

- 48 aree cornee
- 8 unghielli
- 16 aree cutanee centrali
- 8 aree cutanee laterali

Totale:

- `80 aree cliccabili`

## Horn

Esempi richiesti:

- `C1_B`
- `C1_S`
- `C1_P`
- `C1_APX`
- `C1_LBab`
- `C1_LBax`

Logica proposta:

- `C1` = claw 1
- `B` = bulbo
- `S` = suola
- `P` = punta
- `APX` = apice
- `LBab` = parete esterna / line border abassiale
- `LBax` = parete interna / line border assiale

Stessa logica da `C1` a `C8`.

## Accessory Digit

Esempi richiesti:

- `C1_UG` ... `C8_UG`

Interpretazione:

- `UG` = unghiello / accessory digit

## Skin

Esempi richiesti:

- `SKIN_12_Nod`
- `SKIN_12_D`
- `SKIN_12_ID`
- `SKIN_12_Dors`
- `SKIN_34_*`
- `SKIN_56_*`
- `SKIN_78_*`

Logica proposta:

- `SKIN_12` = area cutanea riferita alla coppia 1-2
- `Nod` = nodello
- `D` = digitale
- `ID` = interdigitale
- `Dors` = dorsale/dorso quando applicabile

La stessa logica si replica su:

- `SKIN_34`
- `SKIN_56`
- `SKIN_78`

## Skin Laterali

Nuove aree richieste:

- `SKIN_C1_LAT`
- `SKIN_C2_LAT`
- `SKIN_C3_LAT`
- `SKIN_C4_LAT`
- `SKIN_C5_LAT`
- `SKIN_C6_LAT`
- `SKIN_C7_LAT`
- `SKIN_C8_LAT`

Logica proposta:

- `SKIN_C1_LAT` = area cutanea laterale associata all'unghione 1
- `SKIN_C2_LAT` = area cutanea laterale associata all'unghione 2
- stessa logica fino a `SKIN_C8_LAT`

Queste aree:

- appartengono alla categoria `skin`
- usano lo stesso popup delle altre aree cutanee
- vanno trattate come zone autonome, non come alias delle aree centrali

## Distinzioni Obbligatorie

Ogni record mappa deve distinguere:

- `horn`
- `skin`
- `accessory_digit`

Questo deve riflettersi in:

- `zone_code`
- `zone_category`
- regole di validazione del popup

## 6. Piano UI

## Pagina Sessione

Deve mostrare:

- tipo sessione
- data
- nome stalla
- elenco capi in tabella gestionale
- tasto aggiunta capo
- tasto fine sessione

## Popup Numero Capo

Comportamento previsto:

1. apertura automatica su aggiunta nuova vacca
2. input integer obbligatorio
3. se annulla, ritorno all'elenco sessione
4. se duplicato, popup resta aperto con solo:
   - `Capo già presente.`
5. se valido, creazione o apertura della visita in compilazione

## Tre Viste Circolari

La visita deve essere organizzata in:

- `Dati generici`
- `Mappa unghioni`
- `Altre info`

## Comportamento Frecce

- freccia avanti: salva localmente e porta alla vista successiva
- freccia indietro: salva localmente e porta alla vista precedente
- navigazione circolare completa

## Pulsante Elenco

- salva localmente
- torna all'elenco capi della sessione
- non perde il lavoro in corso

## Elimina

- disponibile dalla visita
- apre conferma
- se confermato, marca il record come eliminato secondo la strategia offline/sync

## Storico Capo

- consultabile dalla visita corrente
- non sovrascrive dati storici
- deve mostrare cronologia ordinata delle visite precedenti del capo nella farm

## Popup Corno

Campi UI:

- `Tipologia`
- `Estensione`
- `Rimuovi`
- `Conferma`

Regola:

- i menu a tendina partono con opzione vuota

## Popup Cute

Campi UI:

- `Tipologia`
- `Estensione`
- `Rimuovi`
- `Conferma`

Regola:

- i menu a tendina partono con opzione vuota
- le aree `SKIN_C*_LAT` usano esattamente questo stesso popup

Scelte `Tipologia`:

- vuoto
- `1 - Precoce`
- `2 - Acuta`
- `3 - Guarigione`
- `4 - Cronica`
- `4.1 - Riacutizzata`

Scelte `Estensione`:

- vuoto
- `Focale`
- `Ampio`
- `Multi-zona`

Comportamento:

- `Conferma` salva o aggiorna il dato dell'area e colora la zona
- `Rimuovi` svuota il dato dell'area e decolora la zona
- modifiche successive nella stessa visita sovrascrivono il dato precedente dell'area
- visite precedenti non devono mai essere alterate

## 7. Roadmap Di Implementazione

## Step 1: database/migrazioni

- verificare tabelle gia esistenti
- definire cosa manca
- preparare vincoli su sessione aperta unica e anti-duplicato capo per sessione

Stato attuale:

- questo step e coperto dalla migrazione `20260510_add_data_collection_core.sql`
- la migrazione estende `trimming_sessions` e `cow_visits` gia esistenti
- non crea tabelle duplicate per sessioni o visite
- non introduce aperture RLS: riusa le policy farm-scoped gia presenti su sessioni e visite
- introduce il primo nucleo reale per:
  - tipo sessione
  - stato `reopened`
  - `cow_number` integer
  - soft delete logico
  - anti-duplicato per sessione
  - campi base dati generici
  - marker di conflitto offline/sync

## Step 2: servizi Supabase

- definire query/session services
- definire servizi visita vacca
- definire servizi storico capo
- definire servizi osservazioni mappa

## Step 3: pagina sessione reale

- sostituire i dati demo della sessione con dati reali
- caricare la sessione aperta o ultima riaperta
- mostrare tabella capi reale

## Step 4: popup numero capo e anti-duplicato

- implementare popup reale
- validazione integer
- annulla
- messaggio duplicato minimalista

## Step 5: Dati generici

- implementare campi strutturati
- salvataggio locale immediato
- apertura automatica della visita dal popup capo

## Step 6: navigazione circolare tre viste

- organizzare le tre viste
- salvataggio implicito su frecce ed elenco

## Step 7: mappa zone codificate

- costruire rappresentazione zone con codici stabili
- collegare zone e visite

## Step 8: popup lesioni

- popup corno
- popup cute/Mortellaro
- rimozione/conferma

## Step 9: altre info

- completare i campi complementari
- integrare storico capo consultabile

## Step 10: sync/offline evoluto

- queue di mutazioni
- sync incrementale
- rilevazione conflitti
- disambiguazione con prefisso `999`
- UI di revisione conflitti

## 8. Rischi Tecnici

## Duplicati Multi-Device

Rischio:

- due dispositivi aggiungono lo stesso capo nella stessa sessione offline

Impatto:

- collisione su numero capo
- incoerenza sessione

Mitigazione:

- controllo locale
- controllo backend
- `needs_conflict_resolution`
- `original_cow_number`
- prefisso `999`

## Perdita Dati Offline

Rischio:

- chiusura app, crash, cambio schermata o rete assente

Mitigazione:

- autosave locale
- stato sessione persistente
- sync appena possibile

## Modifiche Sessioni Storiche

Rischio:

- sovrascrittura di visite che dovrebbero restare storiche

Mitigazione:

- blocco modifica fuori da sessione attuale o ultima riaperta
- regole chiare lato UI e lato servizio

## RLS

Rischio:

- query bloccate o troppo lente
- accessi non coerenti tra `farms`, `farm_users`, `sessions`, `visits`

Mitigazione:

- query sempre centrate su `farm_id`
- verificare RLS per ogni tabella nuova o estesa
- evitare helper ricorsivi pesanti

## Performance Query Storico

Rischio:

- storico capo lento con molte visite e osservazioni

Mitigazione:

- indici su `(farm_id, cow_number, visit_date desc)`
- carico progressivo dello storico
- query aggregate limitate dove possibile

## Codifica Zone Non Ambigua

Rischio:

- zone duplicate o non interpretabili nel tempo

Mitigazione:

- dizionario codici stabile
- distinzione obbligatoria `horn / skin / accessory_digit`
- validazione coerente tra popup UI e struttura dati

## Sintesi Finale

La direzione tecnica raccomandata e:

- tenere `trimming_sessions` come contenitore della sessione operativa
- tenere `cow_visits` come record storico principale
- tenere `claw_zone_observations` come livello atomico della mappa
- applicare autosave locale sempre
- sincronizzare appena possibile
- non perdere mai dati in conflitto
- usare disambiguazione esplicita e revisionabile quando il multi-device crea collisioni

Questo piano permette di passare dalla demo attuale del flusso sessione a una raccolta dati reale, robusta e coerente con l'architettura mobile-native offline-first di Appiombi.
