# Clinical Map Validator

Validator non invasivo per le mappe cliniche Appiombi.

## Scopo

Lo script controlla:

- validita JSON dei manifest;
- validita XML/SVG del clickable SVG;
- duplicati negli ID SVG;
- campi obbligatori nelle aree manifest;
- corrispondenza tra `svg_element_id` e ID presenti nello SVG;
- aree mancanti, ID orfani e placeholder non clinici.

## Uso

Dalla root del repository:

```bash
python tools/clinical_map_validator/validate_clinical_map.py
```

Su ambienti senza Python nel PATH, usare il runtime Python disponibile.

## Nota

Il validator non decide tassonomie cliniche. Segnala problemi tecnici e warning; le decisioni anatomiche richiedono approvazione umana.
