# Main Tile
Shows a file input selector (CSV or Excel only). On file selection → calls backend parse API with the file name and its content
When a response is received and it's a failing one, then display a fading error prompt on the top: "something went wrong, please try again" & clear the file selection.
Otherwise, if a success response do a check on the missing settings data returned from the response as displayed below.

## 1. Duplicate Check
If the response `SettingsDelta`.instrumentProvider contains an entry in `pastImports` with "mnemonic"=fileName then:
  - a warning prompt with title: "File already processed" should be dsiplayed
  - find the most recent date from pastImports with "mnemonic"=fileName
  - having text something like "File was already processed at {date}. You want to process it again ?"
  - add also "Yes" & "No" buttons on the bottom
  - if user clicks yes continue to the next check
  - if user clicks no, clear the file selection
## 2. Instrument Provider Check
If the retuned `SettingsDelta`.instrumentProvider has a name with value = "<Provider Name Missing>" then:
  - display a prompt (with an option to close it) with title "New provider found" and within an input box with label: "select name:". Also a "Save" button on the bottom
  - upon clicking on save the new instrumentProvider model should be saved on the browser and the next check be done
  - if he tries to close, a same prompt like in the duplicate check should be displayed
## 3. Instruments Check
Find all **instrument** in `SettingsDelta`.instruments with empty `name` column and if they are more than 1 then:
   - display a prompt with title: "Update existing instruments"
   - display inisde a list of those instrument keys and next to each one a text editor with label "enter name" & a select component with label "select currency"
   - retrieve the currency items to show using a free open api with no authentication/authorization (e.g. frankurter) and display/store their ISO code
   - the `instrumentProvider` key from the returned model should be used a foreign key for the column `provider`
   - on the bottom a "Save" button should be displayed, which on click should temporarily save the data on the browser
   - the prompt should also be "closeable" and on click follow the same logic as in duplicate check


# Results Grid

- Display as title of the grid the `instrumentProvider` name
- The grid header row should be "sticky" and all row groups/rows beneath it should be scrollable.
- The column `importMnemonic` should be hidden both at the header and the row cells but also in any selection done by the user.
   - it should, however, be included in the backend call to save the expense data as explained in **Header row** below

## Header row 

  - expense model column names
  - below each column name: a label showing the mapping source (file column name or index), styled differently from the column name + the format is available (e.g. date)
  - at the very end one button with name: "Save Successfull Rows", which on click should save the following rows on the backend by calling the relevant API of the expenses:
    - all successfull row group rows + the duplicate group rows with attribute `notDuplicate`
    - if save was succesfull a relevant fading top screen success message (green background) is displayed and the whole **File tile** is collapsed/closed
    - if save was NOT succesfull a relevant fading top screen error message (red background) is displayed and nothing else should happen
    - if save was succesfull, the **HistroicalRates Sync** api should be called/triggered & the `SyncingExternalAggregatedData` one in parallel -> ignore any errors

## Rows Grouping

The rows should be grouped in 3 categories:

  | Category | Description | Sort order | Background color
  |----------|-------------|------------|
  | **Problematic** | Rows with one or more unparsed expense columns | Most missing fields first | light red |
  | **Ignored** | Rows whose merchant is in `SettingsDelta.ignoredMerchants`; visually marked as excluded | By merchant name | light green |
  | **Duplicates** | Rows where all fields are parsed but they are found more than 1 time in the results | By date | light yellow |
  | **Successful** | All remaining rows | By date | light green |

 ### Problematic rows

Those should have the following actions as a last column:

 #### Ignore button
  - open a prompt with the 2 following options
  - "Ignore this row only" → removes the row from the grid (remembers the user selection in case the data of the grid are refetched) & moves it to the **Ignored** rows group
  - "Ignore all rows for merchant: {merchant}" → add the merchant to the `SettingsDelta`.ignoredMerchants in the browser & moves all rows that match that merchant to the **Ignored** rows group
  - this button should be enabled only if the merchant cell in the row is available/parsed

 #### Empty cells
   - empty cells should be clickable with a prompt being displayed to choose the mapping type
   - the prompt should have on top a "mini grid" with the contents from the backend with a title: "Sample Parsed File Rows"
   - a select type component with title: "Map form" should be visible below where the user can select:
      - "Column Order" -> if that is selected a number selection editor should be displayed on the right which should accept values only from `1` until the length of the sample row columns returned from the backend
      - "Column Name" -> if that is selected another select component should be displayed on the right with values from the header row column values returned from the sample data from the back end
         - that option should be available only if the header row was returned from the back end
      - "Predefined Value" -> a select with search functioniality should be displayed on the right with values drawn from:
          - if user clicked on instrument column use the `SettingsDelta`.instruments and display their name on the select and as value the key
          - if user clicked on any other column originally this option (predefined value) should not be available
    - on the bottom of all this 2 button should be available: "Apply" & "Cancel"
    - if the first is clicked the updated columnMapping should be stored on the instrumentProvider in the `SettingsDelta` on the browser and re-parses the file via backend
    - if the second button is clicked it should just close the prompt with no further actions

 ### Ignored rows

Those should have the following actions as a last column:

**"Un-Ignore" button** — prompts the user:
  - "Un-Ignore this row only" → removes the row from the grid (remembers the user selection in case the data of the grid are refetched) and moves it either to the successfull or problematic rows, depending if it has any empty cells
  - "Un-Ignore all rows for merchant: {merchant}" → removes the entry from `SettingsDelta`.ignoredMerchants in the browser & moves all rows that match that merchant to the respective rows group dependening if they have empty cells or not, just like in the above case.

 ### Duplicate rows
Those should have the following actions as a last column:

**"Not a duplicate"** - only if the row is NOT marked as `notDuplicate` on the background
Marks this row as `notDuplicate` (background row data) and remembers the user selection in case the data of the grid are refetched.
It is important to keep the source row (the one we checked against) as not duplicate all of the times and retain it as source of truth for that data.

**"Duplicate"** - only if the row is marked as `notDuplicate` on the background
Remove the `notDuplicate` attribute of the row and remembers the user selection in case the data of the grid are refetched

Rows with `notDuplicate` attribute should be marked with the same background color as the *successfull rows*

 ### Successful rows

Those should have the following actions as a last column:

**"Ignore" button** — prompts the user:
  - "Ignore this row only" → removes the row from the grid (remembers the user selection in case the data of the grid are refetched) & moves it to the **Ignored** rows group
  - "Ignore all rows for merchant: {merchant}" → add the merchant to the `SettingsDelta`.ignoredMerchants in the browser & moves all rows that match that merchant to the **Ignored** rows group
     - this button should be enabled only if the merchant cell in the row is available/parsed

**"Change Category" button** — opens a prompt titled "Select new category for merchant: {merchant}":
  - Uses `SettingsDelta`.categories as a select component
  - On selection → update `SettingsDelta`.categories selected entry `merchants` list
  - Then re-parses the file via backend and refreshes the grid

# Footer Buttons
After the grid the following 2 buttons should be displayed on a footer row (which should be sticky if scrolling is enabled on the grid).
 
 ## Save Successfull Rows

 ### 1. Save Settings
 If that is clicked, then the `SettingsDelta` data should be tried to be persisted:
   - **ignoredMerchants**, **categories** -> `upsert` style operation the relevant sections on **settings** model
   - **instrumentProvider** -> `upsert` operation to the item with the same _key_ from the relevant **settings** model list
   - **instruments** -> `upsert` operation to the items with the same _key_ from the relevant **settings** model list

If any above operation fails, a relevant fading error message (top of the screen) should be displayed and a relevant text to inform the user that the results on the grid can not be persisted anymore and that he should try again (the settings update part should be idempotent).

If the operation succeeds than the next persistent action should execute.

### 2. Save Expneses
After a successfull settings update the successfull rows should be inserted (`add` style api call) with individuals calls to each row.
For the duplicate ones that the user marked as `notDuplicate` add the extra flag on the api call.
Only persist the rows from the successfull rows group of the results grid above.

Wait for all calls to finish and if there are any error results open a new prompt with title "Failed to be saved Expenses":
  - add all failed ones in a "light grid" with all expense columns with a checkbox next to each
  - add the bottom add a split button with text "Try Again the selected" and on click the selected expenses should be retried
  - if they fail again they should remain on the grid, otherwise they should be deleted from the grid
  - if no remaining (failing) expenses are to be displayed on the grid, close the prompt and go to the last section  (_3. Clear File Selection_)
  - if the user clicks to close the prompt then display the following warning message: "Are you sure ? You will lose any unsaved work"
  - if the user cancels then nothing happens but if he chooses to cancel then the next section should happen (_3. Clear File Selection_)

### 3. Clear File Selection
That should clear any temporarily saved results for the import session (e.g. `SettingsDelta`, `ignoredRows`, etc) delete the results grid and clear the file selection from the top of the page

 ## Cancel Import
  - That should prompt the user with following warning message: "Are you sure ? You will lose any unsaved work"
  - if the user cancels then nothing happens but if he chooses to cancel then the above section should happen (_3. Clear File Selection_)
