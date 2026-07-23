# Add / edit places in Firebase (live directory)

After the first successful seed, **Firestore is the source of truth**.  
You can grow the list without rebuilding the app.

## How the app loads places

```
First launch (empty Firestore)
  → uploads pilot_seed.json once
  → app reads Firestore

Later
  → you add/edit docs in Console
  → pull down on Home / Search / Browse to refresh
```

Bundled JSON is only a backup if cloud fails.

## Add a restaurant or hotel (Console)

1. Open Firebase Console → project **heyecho-56838**
2. **Firestore** → collection **`businesses`**
3. **Add document**
4. Document ID: e.g. `r200` (restaurant) or `h050` (hotel) — any unique string
5. Add these fields:

| Field | Type | Example |
|-------|------|---------|
| `name` | string | `CTR Soft Serve - HSR` |
| `neighborhood` | string | `HSR Layout` |
| `city` | string | `Bengaluru` |
| `categories` | array\<string\> | `["Desserts", "Cafe & Coffee"]` |
| `shortDescription` | string | `Soft serve favourite near HSR.` |
| `priceLevel` | number | `2` (1–4) |
| `perfectFor` | array\<string\> | `["Friends", "Dessert"]` |
| `recommendedByContactIds` | array\<string\> | `["u1", "u5"]` (optional; for trust) |
| `imageSymbol` | string | `birthday.cake.fill` |
| `address` | string | `27th Main, HSR Layout` |
| `hours` | string | `11:00 AM – 11:00 PM` |
| `latitude` | number | `12.9121` |
| `longitude` | number | `77.6446` |

### Hotels
Use category **`Hotels`** (and optionally `Fine Dining`):

- `categories`: `["Hotels", "Fine Dining"]`
- `imageSymbol`: `building.2.fill`

### Trust ranking tip
Put contact ids from collection **`contacts`** into `recommendedByContactIds` (e.g. `u1`, `u2`, `cgoto1`).  
Then users who picked those GoTo’s see the place higher on Home.

## See it in the app

1. Save the document in Console  
2. Open the app → **Home** → **pull down to refresh**  
3. Set food city to that neighborhood (e.g. `HSR Layout, Bengaluru`) or Search by name  

Place count under the city on Home updates after refresh.

## Edit / delete
- Edit any field on the document → pull to refresh  
- Delete document → place disappears after refresh  

## Reset to bundled seed
Delete the entire **`businesses`** collection (and optionally re-seed by relaunching while signed in). First empty load uploads `pilot_seed.json` again.

## Do not
- Don’t put Places API keys in the iOS app  
- Don’t expect Console changes without pull-to-refresh or relaunch  
