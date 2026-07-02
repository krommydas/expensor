# Expensor — System Prompt

Create an expense management system called **"expensor"** as a monorepo with the following components.

---

## 1. Backend Server

_See **PROMPT - BACKEND.md**_ 

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
3. When results are received a grid is shown below

**Results Grid:**

- **Header row:** 
  - expense model column names
  - below each column name: a label showing the mapping source (file column name or index), styled differently from the column name + the format is available (e.g. date)
  - at the very end one extra column with name "Actions"
- **Rows split into 3 categories (in this order):**

  | Category | Description | Sort order |
  |----------|-------------|------------|
  | **Problematic** | Rows with one or more unparsed expense columns | Most missing fields first |
  | **Ignored** | Rows whose merchant is in `ignoredMerchants`; visually marked as excluded | By merchant name |
  | **Successful** | All remaining rows | By date |

**Problematic rows actions:**

- **"Ignore" button** — prompts the user:
  - "Ignore this row only" → removes the row from the grid (remembers the user selection in case the data of the grid are refetched)
  - "Ignore all rows for merchant: {merchant}" → calls settings API to add merchant to `ignoredMerchants` & calls the api again to refetch the data for the grid
     - this button should be enabled only if the merchant cell in the row is available/parsed

- **Empty cells: (clickable but with no visible button)**
   - a prompt should be displayed to choose the mapping type
   - the prompt should have on top a "mini grid" with the contents from the backend with a title: "Sample Parsed File Rows"
   - a select type component with title: "Map form" should be visible below where the user can select:
      - "Column Order" -> if that is selected a number selection editor should be displayed on the right which should accept values only from `1` until the length of the sample row columns returned from the backend
      - "Column Name" -> if that is selected another select component should be displayed on the right with values from the header row column values returned from the sample data from the back end
         - that option should be available only if the header row was returned from the back end
      - "Predefined Value" -> a select with search functioniality should be displayed on the right with values drawn from:
          - if user clicked on currency column use a free open api with no authentication/authorization (e.g. frankurter) to retrieve currencies
          - if user clicked on instrument column retrieve the instruments from the settings api and display their name on the select and as value the key
          - if user clicked on any other column originally this option (predefined value) should not be available
    - on the bottom of all this 2 button should be available:
        - "Apply" -> this should do a call to the settings to update

**Successful rows actions:**

- **"Ignore" button** — prompts the user:
  - "Ignore this row only" → removes the row from the grid (remembers the user selection in case the data of the grid are refetched)
  - "Ignore all rows for merchant: {merchant}" → calls settings API to add merchant to `ignoredMerchants` & calls the api again to refetch the data for the grid

- **"Change Category" button** — opens a prompt titled "Select new category for merchant: {merchant}":
  - Calls settings API to load categories with their merchants; displays as a select component
  - Option to add a new category inline
  - On selection → calls API to update the merchant's category mapping
  - Then re-parses the file via backend and refreshes the grid
