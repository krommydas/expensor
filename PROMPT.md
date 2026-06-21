# Expensor — System Prompt

Create an expense management system called **"expensor"** as a monorepo with the following components.

---

## 1. Backend Server

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

### REST API

Expose full **CRUD** endpoints for:
- `/expenses`
- `/settings`

---

### File Parse API

**Input:**
- A CSV or Excel file
- Optionally, a list of column mappings (same model as settings.instrumentProviders.sourceColumns)

**Output:**
- A list of parsed rows, each containing expense model fields (some may be empty)
- The list of columns config (same model as settings.instrumentProviders.sourceColumns)

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
     - Persist the result (merchant → category) in the categories model for future use

**Post-parse filtering:**
- Apply a filter on rows based on their `merchant` field against `ignoredMerchants` from settings

---

## 2. Frontend (React GUI)

Use **React** with **React Context** for state management, **Material UI** for styling, and **Vite** for building.

### Layout

- **Left sidebar** with 4 navigation entries, each with an icon:
  - Home
  - Import
  - Settings
- **Right panel** showing the selected page content

---

### Settings Page

_See **PROMPT - GUI - Settings.md**_ 

### Import Page

Displays **tiles**: "Revolut", "File"

- Clicking a tile hides all other tiles and opens a **pane** with:
  - `×` button (top-right) — resets to tile view
  - Tile name as header
- The **Revolut** tile is not clickable

#### File Tile

1. Shows a file input selector (CSV or Excel only)
2. On file selection → calls backend parse API → receives rows and columns

**Grid display:**

- **Header row:** expense model column names
  - Below each column name: a label showing the mapping source (file column name or index), styled differently from the column name
- **Rows split into 3 categories (in this order):**

  | Category | Description | Sort order |
  |----------|-------------|------------|
  | **Problematic** | Rows with one or more unparsed expense columns | Most missing fields first |
  | **Ignored** | Rows whose merchant is in `ignoredMerchants`; visually marked as excluded | By merchant name |
  | **Successful** | All remaining rows | By date |

**Row actions (Successful rows only):**

- **"Ignore" button** — prompts the user:
  - "Ignore this row only" → removes the row from the grid
  - "Ignore all rows for merchant: {merchant}" → calls settings API to add merchant to `ignoredMerchants`

- **"Change Category" button** — opens a prompt titled "Select new category for merchant: {merchant}":
  - Calls settings API to load categories with their merchants; displays as a select component
  - Option to add a new category inline
  - On selection → calls API to update the merchant's category mapping
  - Then re-parses the file via backend and refreshes the grid
