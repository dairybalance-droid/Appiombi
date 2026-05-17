# Asset Safety Checklist

Regole per lavorare con asset clinici e visuali.

## SVG e PNG clinici

- Non sovrascrivere SVG master.
- Non cancellare reference PNG.
- Non rasterizzare la PNG dentro lo SVG.
- Non modificare asset clinici senza istruzioni esplicite.
- Non trattare una mappa clinica come logo o immagine decorativa.

## Separazione asset

- Asset UI/logo: loghi, placeholder, icone, immagini decorative.
- Asset clinici: reference, SVG master, SVG clickable, manifest anatomici.
- Tool legacy: strumenti manuali non runtime.
- Output generati: report, diff, overlay, render temporanei.

## Versionamento mappe cliniche

Le mappe cliniche devono essere versionate:

```text
assets/clinical_maps/<domain>/<map_id>/v1/
```

Quando una mappa cambia in modo incompatibile, creare una nuova versione invece di rompere quella esistente.

## ID stabili

Gli ID SVG e manifest devono restare stabili perche possono essere salvati nel database.
