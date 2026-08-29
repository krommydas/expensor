The page should display a grid with some search options on top of it. The title should be: "Manage Expenses". It should consist of 2 sections: the *search bar* which should be "sticky" and the *expenses grid* which should be scrollable up to 3 times the current view unit height.

# Search bar

The look and feel should be copied from the Splunk search bar with a search box on the left followed by a time selection and the search button. On top of the search box, a checkbox should be displayed with title: "Enable AI". Upon loading of the page the following search default filters should be applied and the relative call to the backend be done: 
   - *search string*: empty
   - *time selection*: "last month"
   - *ai checkbox*: "disabled"

Upon success or failure of that first call on the backend the same things as described on the *search button* section should be performed.

## AI checkbox
It should have as label: "Use AI" and be placed above the *search box*. If checked, *time selection* editor below should be hidden 

## Search box
 - it should have as a placeholder: "enter search terms" if **AI Checkbox** is not checked or "enter search instructions" if it is checked

## Time selection
 - it should contain splunk "preset, "relative" & "date range" options and for all of them the lowest unit offered should be days
 - the selected value should always be translated to a "from" - "to" (optional) date filter
 - every value displayed as "Last unit X" should be translated to a "from" date filter with X being either days, months or years to look in the past (current date minus) according to the unit entered (e.g. 3 days back)
 - every value displayed as "Last X" should be translated to a "from" date filter where according to the X value (days, months or years) we look on the start of the period (e.g. last month)
 - a date range filter corresponds to a "from" - "to" date filter for the backend

## Search button
 - upon clicking a call to the `search` backend endpoint should be made with the serach box content (string) + the time filter (from - to dates) + the value of the AI checkbox (boolean)
 - if *AI checkbox* is checked the time filter should not be sent
 - if the call fails an error should be displyed as fading away from the top
 - if the call succeeds the grid below should be displayed with the data retrieved (`expense model` rows)

# Expenses Grid

 - the grid should displayed the expense rows retrieved from the backend. It should have 3 sections: *Header Row* (sticky), *Data Rows* (scrollable) & *Footer Row* (sticky).
 - the data displayed should be paginated only if the amount of rows exceeds the current view unit height multiply by 3. In that case the results should be divided to pages so as every page rows fulfills that rule.
 - the data should by default (unless overriden by the user) shorted by `date` descending and then by `importMnemonic`

## Header Row
 The expense model colums should be displayed (except the `id`) with the option to short data based on them (but not filter) + 1 extra column in the left with a checkbox

## Footer Row 
 - It should display the number or rows selected, only if any or the rows checkbox is selected.
 - A split button with the following options: "Delete Selected" (default) & "Adjust Selected (TODO)". The button should only be visible if any or the rows checkbox is selected.
 - An "add" button should be displayed
 - A pagination component should be displayed on the right only if multipe pages are available for the results

 ### Split button
   - if the "Delete Selected" option was pressed a prompt should be displayed with the following mesage: "All of the selected expenses will be deleted for ever. Are you sure ?"
   - if yes a call to the backend should be made with the selected row ids and show either a fading success (green) or error (red) message on the top
   - upon successfull response the data of the grid should be refetched from the backend using the same filters
   - The "Adjust Selected" button should dispay a prompt where the user could change the category of all of the transactions
      1. a call to the settings api should be made to find the current categories - merchant mappings
      2. the system should calculate and display on the bottom of the prompt the updated merchant re-categorizations
          - every merchant could be added/removed from a category (existing or new) -> show relative graphiscs to indicate this
      3. a confirmation button should be displayed together with a cancellation one
      4. if cancelled the prompt should be closed with no further up action
      5. if confirmed a call to both the settings & transactions APIs should be made to persist the changes
      6. on success a green postive message should be faded from the top and prompt close and on error a respective erroneous one should be displayed and prompt should stay open
 
 ### Add button
   - a prompt should be displayed where you can enter the transaction: `date`, `amount`, `merchant`, `category` and `instrument`
   - for merchant an auto-complete feature should be done where merchant names from the settings api should be searched and prompted
   - if a merchant is selected, a settings search should be made to find if it belongs to a category and this should be preslected on the category input
   - if the user changes the category of an existing merchant or add a new merchant a relative wanring message should be displayed on the bottom for settings update with the related changes
   - the instrument field should be a select one with the available values from the settings model
   - the `importMnemonic` should be a custom predefined system wide value to indicate it's a GUI user custom single addition of the transaction and not visible to the user
   - on the bottom 2 buttons with similar logic like the Split Button -> "Adjust Selected" above

## Data Rows
The expense data rows should be displayed here with the following rules:
 - `id` field should be available in the row data on the background but not visible
 - `instrument` cells should display the instrument name retrieved by calling the `settings` -> `instruments` where **key** field is equal to the row instrument cell value
 - `amount` field should also display the *currency* by looking up the `currency` field from the row instrument key (see above)
 - merchant, date, category and importMnemonic should be also displayed
 - the user should be able to move the columns around by drap and drop and change their appearance order (from left to right)
 - the default columns order should be: date, amount, category, merchant, instrument, importMnemonic
 - a checkbox should always be dispayed per row as a last column on the right