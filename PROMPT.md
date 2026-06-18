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
      "fileSource": { "namePattern": "string" },
      "sourceColumns": [
        {
          "target": "<Enum — one of expense model columns>",
          "sourceName": "string",
          "sourceIndex": "number",
          "format": "string"
        }
      ]
    }
  ]
}
```
> `fileSource` is optional on `instrumentProviders`.

---

### REST API

Expose full **CRUD** endpoints for:
- `/expenses`
- `/categories`
- `/instruments`
- `/settings`

---

### File Parse API

**Input:**
- A CSV or Excel file
- Optionally, a list of column mappings, each containing:
  - `target` — the expense model field this column maps to *(required)*
  - `sourceIndex` — the column index in the parsed row *(required)*
  - `format` — parsing format hint (e.g. date format) *(optional)*

**Output:**
- A list of parsed rows, each containing expense model fields (some may be empty)
- The list of columns found in the file, each tagged with its expense model mapping

**Column detection order (applied per unmapped column):**

1. **Explicit mapping** — use column data passed in the request input
2. **Header-based mapping** — read header row from the file; map headers to expense model fields using synonyms and common financial naming conventions
3. **Content-based mapping** — infer type from content (e.g. a parseable date is likely a date field)
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

Organized as expandable sections.

#### Section: Categorization

**Subsection — AI Source:**
- Dropdown: AI model (one option: "Claude")
- Input: "Api Key"
- On dropdown change or on blur of the key input → call server to persist
- "Test Connection" button:
  - Calls the AI provider with the configured credentials (same categorization call as the server)
  - On success: show a checkmark
  - On failure: show an error message

**Subsection — Existing Mappings:**
- Search input: "Search for merchant"
- Accordion list of categories (loaded from server):
  - Expanding a category shows its linked merchants as tag/label items
  - Each merchant tag has an `×` icon to remove it (calls API to update that category)
  - An `+` icon to manually add a merchant (persists on click-outside)
  - Long merchant names are truncated; full name shown on hover/click
- Below the accordion: an "Add Category" button (calls server to persist, then reloads the list)

#### Section: Instruments

Displays a list of **Providers**, with each one displayed with the...
*(section incomplete in original)*

---

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
