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
| importMnemonic | text |

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
      "key": "string",
      "fileSource": { "namePattern": "string" } (optional),
      "sourceColumns": [
        {
          "target": "<Enum — one of expense model columns>",
          "sourceName": "string" (optional),
          "sourceIndex": "number" (optional),
          "predefinedValue": "string" (optional),
          "format": "string" (optional)
        }
      ],
      "pastImports": [
        {
          "date": "date",
          "mnemonic": "string",
          "checksum": "string",
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

#### Input
- A CSV or Excel file

#### Output
- A list of parsed rows, each containing expense model fields (some may be empty)
- The instrumentProvider model found to be matching for this file
- A sample list of rows parsed (not mapped to expense columns):
  - include the header row if one is found
  - include a list of rows with each row having either a list of column values (text) or column attributes & values

#### Logic

##### Resolve Instrument provider

1. try to find an instrument provider from the list that it's filePattern matches the file name
2. if no one is found create a new item and saved it in the settings:
  - `key` would be auto-generated
  - `name` will have the value: "<Provider Name Missing>"
  - `sourceColumns` will be null
  - `fileSource.namePattern` should be regex pattern to match this file name plus future ones:
     - try to cater for dynamic part of the file name, eg dates (e.g. 2025_06_02)
     - try to cater for dynamic part of the file name, eg indexing values (e.g. _1 or _2)

##### Duplicate protection

After an instrument provider is found, try to calculate a checksum of the file data.

1. If one of the `pastImports` is found to contain that checksum -> abort the operation & return a relevant message/http status code/response
2. If not, store a new entry in the `pastImports` with that checksum + the current date + a mnemonic for the GUI containing the filename

##### Resolve Columns Mapping

For every field in the expense model try to resolve the column mapping based on the following logic:

1. **Existing mapping** - column mapping existings already -> nothing extra to be done
2. **Header-based mapping** — read header row from the file -> find the relevant header that maps to expense model fields using synonyms and common financial naming conventions
   - use `sourceName` field in that case in the created column mapping
3. **Content-based mapping** — infer type from content.. for example:
    - a parseable date is likely a date field
    - masked content (e.g. **9012) is most likely a card number or expense model instrument instrument
    - use `sourceIndex` field in that case in the created column mapping

For steps **2** & **3**, in addition: 
  - if more than 1 columns from the input resolve to the same expense model field, skip that expense column mapping
  - try to find the format for the column (if applicable - eg date) try multiple date formats until one succeeds
  - if the expense column in question is the `importMnemonic` then always use a column mapping with the **predefinedValue** equal to the filename passed in the input
  - save the column mapping into the provider

##### Apply Columns Mapping

After resolving the columns try to create expense models from the parsed file rows using the following logic:

1. **Explicit mapping** — if the `column.predefinedValue` is filled, use the value to map the column
2. **Header-based mapping** - if the `column.sourceName` is filled, try to map the row cell that corresponds to the header column that has the same name
3. **Index-based mapping** - if the `column.sourceIndex` is filled, try to map the row cell that corresponds to the indexed column

If the mapping can not performed leave the relevant field empty

##### Post Processing

1. For each column, apply format-appropriate rules (if applicable in the column mapping)
2. If there is no column mapping found for the expense `category` column but for the `merchant` is and a cell value was parsed:
  1. Try to find a category from the settings that contains the merchant in it's list of merchants
  2. If no match, call the AI provider (model + key from settings) to categorize the merchant
     - Strip any sensitive data from the merchant name before the external call
     - Persist the result (merchant → category) in the categories model for future use -> try to align the found category with one of the existing categories
     - If the final category is new and not linked to a group, try to use AI to find a relavant group (try to align with existing groups)