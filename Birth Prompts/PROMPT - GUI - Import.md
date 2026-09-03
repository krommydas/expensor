Displays **tiles**: "Revolut", "File"

- Clicking a tile hides all other tiles and opens a **pane** with:
  - `×` button (top-right) — resets to tile view
  - Tile name as header
- The **Revolut** tile is not clickable

# File Tile

## File Input

Shows a file input selector (CSV or Excel only). On file selection → calls backend parse API with the file name and its content
When a response is received:
  - if response indicates some form of unpredictable error display a fading error prompt on the top: "something went wrong, please try again"
  - if a response indicates duplicate issue display a fading warbing prompt on the top: "File data already imported"
  - if a success response and the instrument provider retruned has a `name` equal to "<Provider Name Missing>":
      - display a prompt (with an option to close it) with title "New provider found" and within an input box with label: "select name:". Also a "Save" button on the bottom
      - upon clicking on save a relevant call on the settings should be made to save the update instrumentProvider model
      - if the save call fails display a relevant disappearing error message in the top and keep the prompt open
      - if the save succeeds show the grid below with the updated provider name or the prompt with the missing instruments (see below)
      - if the user clicks to close the prompt show the grid below with the default provider name or the prompt with the missing instruments (see below)
  - if a success response and the instrument provider retruned has a `name` NOT equal to "<Provider Name Missing>" display the grid below with that name
  - if a success response and a list of not found instruments is not empty then, *after* the instrumentProvider prompt:
     - display a prompt with title: "Update existing instruments"
     - display inisde a list of not found instrument keys and next to each one a text editor with label "enter name" & a select component with label "select currency"
     - retrieve the currency items to show using a free open api with no authentication/authorization (e.g. frankurter) and display/store their ISO code
     - on the bottom a "Save" button should be displayed, which on click should update the settings model with the updated instruments
     - the prompt should also be "closeable" and in that case nothing should happen -> the below grid should be displayed
  - in case of a success response save on the background the provider `key`

### Results Grid

- Display as title of the grid the provider name. Before dispaying the grid a call to retrieve the settings model should be done.
- The grid header row should be "sticky" and all row groups/rows beneath it should be scrollable.
- The column `importMnemonic` should be hidden both at the header and the row cells but also in any selection done by the user.
   - it should, however, be included in the backend call to save the expense data as explained in **Header row** below

#### Header row 

  - expense model column names
  - below each column name: a label showing the mapping source (file column name or index), styled differently from the column name + the format is available (e.g. date)
  - at the very end one button with name: "Save Successfull Rows", which on click should save the following rows on the backend by calling the relevant API of the expenses:
    - all successfull row group rows + the duplicate group rows with attribute `notDuplicate`
    - if save was succesfull a relevant fading top screen success message (green background) is displayed and the whole **File tile** is collapsed/closed
    - if save was NOT succesfull a relevant fading top screen error message (red background) is displayed and nothing else should happen
    - if save was succesfull, the **HistroicalRates Sync** api should be called/triggered & the `SyncingExternalAggregatedData` one in parallel -> ignore any errors

#### Rows Grouping

The rows should be grouped in 3 categories:

  | Category | Description | Sort order | Background color
  |----------|-------------|------------|
  | **Problematic** | Rows with one or more unparsed expense columns | Most missing fields first | light red |
  | **Ignored** | Rows whose merchant is in `settings.ignoredMerchants`; visually marked as excluded | By merchant name | light green |
  | **Duplicates** | Rows where all fields are parsed but they are found more than 1 time in the results | By date | light yellow |
  | **Successful** | All remaining rows | By date | light green |

 #### Problematic rows

Those should have the following actions as a last column:

**"Ignore" button** — prompts the user:
  - "Ignore this row only" → removes the row from the grid (remembers the user selection in case the data of the grid are refetched) & moves it to the **Ignored** rows group
  - "Ignore all rows for merchant: {merchant}" → calls settings API to add merchant to `ignoredMerchants` & moves all rows that match that merchant to the **Ignored** rows group
     - this button should be enabled only if the merchant cell in the row is available/parsed

In addition, empty cells should be clickable with the following logic on click:
   - a prompt should be displayed to choose the mapping type
   - the prompt should have on top a "mini grid" with the contents from the backend with a title: "Sample Parsed File Rows"
   - a select type component with title: "Map form" should be visible below where the user can select:
      - "Column Order" -> if that is selected a number selection editor should be displayed on the right which should accept values only from `1` until the length of the sample row columns returned from the backend
      - "Column Name" -> if that is selected another select component should be displayed on the right with values from the header row column values returned from the sample data from the back end
         - that option should be available only if the header row was returned from the back end
      - "Predefined Value" -> a select with search functioniality should be displayed on the right with values drawn from:
          - if user clicked on instrument column retrieve the instruments from the settings api and display their name on the select and as value the key
          - if user clicked on any other column originally this option (predefined value) should not be available
    - on the bottom of all this 2 button should be available:
        - "Apply" -> this should do a call to the settings to update the instrument provider with the key stored in the background and the selected column mapping to be updated/overriden
        - "Cancel" -> this should just close the prompt

#### Ignored rows

Those should have the following actions as a last column:

**"Un-Ignore" button** — prompts the user:
  - "Un-Ignore this row only" → removes the row from the grid (remembers the user selection in case the data of the grid are refetched) and moves it either to the successfull or problematic rows, depending if it has any empty cells
  - "Un-Ignore all rows for merchant: {merchant}" → calls settings API to remove merchant from `ignoredMerchants` & moves all rows that match that merchant to the respective rows group dependening if they have empty cells or not, just like in the above case.

#### Duplicate rows
Those should have the following actions as a last column:

**"Not a duplicate"** - only if the row is NOT marked as `notDuplicate` on the background
Marks this row as `notDuplicate` (background row data) and remembers the user selection in case the data of the grid are refetched

**"Duplicate"** - only if the row is marked as `notDuplicate` on the background
Remove the `notDuplicate` attribute of the row and remembers the user selection in case the data of the grid are refetched

Rows with `notDuplicate` attribute should be marked with the same background color as the *successfull rows*

#### Successful rows

Those should have the following actions as a last column:

**"Ignore" button** — prompts the user:
  - "Ignore this row only" → removes the row from the grid (remembers the user selection in case the data of the grid are refetched) & moves it to the **Ignored** rows group
  - "Ignore all rows for merchant: {merchant}" → calls settings API to add merchant to `ignoredMerchants` & moves all rows that match that merchant to the **Ignored** rows group
     - this button should be enabled only if the merchant cell in the row is available/parsed

**"Change Category" button** — opens a prompt titled "Select new category for merchant: {merchant}":
  - Calls settings API to load categories with their merchants; displays as a select component
  - Option to add a new category inline
  - On selection → calls API to update the merchant's category mapping
  - Then re-parses the file via backend and refreshes the grid