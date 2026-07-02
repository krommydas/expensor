Use **Node.js** with an embedded database, HTTP-based protocol (no auth — assume local use), and modern, mature, lightweight technologies.

### Data Models

#### Expense
| Field | Type |
|-------|------|
| date | date |
| merchant | text |
| amount | number |
| currency | text |
| category | text |
| instrument | text |

#### Category
- `name` — string
- `group` — string
- `merchants` — list of strings (mapped merchant names)

#### Instrument
- `name` — string
- `key` — string
- `provider` — string

#### Settings
```json
{
  "ai": {
    "model": "CLAUDE",
    "key": "<text>"
  },
  "ignoredMerchants": ["string"],
  "categories": [
    { "name": "string", "group": "string", "merchants": ["string"] }
  ],
  "instruments": [
    { "name": "string", "key": "string", "provider": "string", "currency": "string" }
  ],
  "instrumentProviders": [
    {
      "name": "string",
      "fileSource": { "namePattern": "string" (optional) },
      "sourceColumns": [
        {
          "target": "<Enum — one of expense model columns>",
          "sourceName": "string" (optional),
          "sourceIndex": "number" (optional),
          "predefinedValue": "string" (optional),
          "format": "string" (optional)
        }
      ]
    }
  ]
}
```

---

### API

Expose full **CRUD** endpoints for:
- `/expenses`
- `/settings`

Choose based on the requirements on the GUI section about the API type (rest or graphql or grpc).

---

### File Parse API

**Input:**
- A CSV or Excel file
- Optionally, a list of column mappings (same model as settings.instrumentProviders.sourceColumns)

**Output:**
- A list of parsed rows, each containing expense model fields (some may be empty)
- The list of columns config (same model as settings.instrumentProviders.sourceColumns)
- A sample list of rows parsed (not mapped to expense columns):
  - include the header row if one is found
  - include a list of rows with each row having either a list of column values (text) or column attributes & values

**Column detection order (applied per unmapped column):**

1. **Explicit mapping** — use column data passed in the request input
    - if the `column.predefinedValue` is filled, use the value to map the column
2. **Header-based mapping** — read header row from the file.. map headers to expense model fields using synonyms and common financial naming conventions
3. **Content-based mapping** — infer type from content.. for example:
    - a parseable date is likely a date field
    - masked content (e.g. **9012) is most likely a card number or expense model instrument instrument
4. **Conflict rule** — if two columns qualify for the same expense field, leave both unmapped

**Parsing rules:**
- For each column, apply format-appropriate parsing (e.g. try multiple date formats until one succeeds), unless a format is explicitly provided in the input
- If `category` cannot be parsed but `merchant` can:
  1. Search saved categories for a match on the merchant name
  2. If no match, call the AI provider (model + key from settings) to categorize the merchant
     - Strip any sensitive data from the merchant name before the external call
     - Persist the result (merchant → category) in the categories model for future use -> try to align the found category with one of the existing categories
     - If the final category is new and not linked to a group, try to use AI to find a relavant group (try to align with existing groups)

**Post-parse filtering:**
- Apply a filter on rows based on their `merchant` field against `ignoredMerchants` from settings
