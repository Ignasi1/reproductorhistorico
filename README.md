# Reproductor Cloud (AE4)

Projecte Flutter de reproductor d'audio en streaming des de Supabase Storage, preparat per cobrir base obligatòria + ampliacions A1-A8.

## Configuració ràpida

1. Copia `.env.example` a `.env`.
2. Omple les claus:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_BUCKET` (opcional, per defecte `songs`)
   - `SUPABASE_SONGS_PATH` (opcional, subcarpeta dins del bucket)
3. Executa:

```bash
flutter pub get
flutter run
```

Per defecte, el bucket esperat es `songs` i l'arrel del bucket.
Si tens MP3 dins d'una carpeta, posa `SUPABASE_SONGS_PATH` (ex: `music` o `audios/2026`).

## Funcionalitats implementades

- Base obligatòria:
  - Llista de cançons des de Supabase Storage.
  - Reproducció en streaming.
  - Panell de metadades.
  - Controls play/pause.
- A1: metadades ID3 completes amb fallbacks i durada `MM:SS`.
- A2: anterior/següent amb límits segurs.
- A3: barra de progrés interactiva amb seek.
- A4: mode shuffle amb indicador visual.
- A5: repeat one amb indicador visual.
- A6: control de volum en temps real.
- A7: portada ID3 amb imatge fallback.
- A8: cerca i filtre en temps real (case-insensitive).

## Checklist de prova manual

1. La llista carrega correctament des de Supabase.
2. Play/pause funciona en una cançó seleccionada.
3. Anterior/següent no donen error a extrems.
4. El slider de progrés avança i permet seek.
5. Shuffle i repeat one canvien d'estat visual i comportament.
6. El volum canvia en temps real.
7. La portada es mostra si existeix; si no, apareix placeholder.
8. La cerca filtra en viu i mostra missatge sense resultats.
