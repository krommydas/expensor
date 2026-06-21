- each of the following section is `expandable`
- try to make use of reusable react components, if possible, without sacrifycing extendiblity by introducing too much tight coupling

# Section: Categorization

## Subsection — AI Source
- Dropdown: AI model (one option: "Claude")
- Input: "Api Key"
- On dropdown change or on blur of the key input → call server to persist
- "Test Connection" button:
  - Calls the AI provider with the configured credentials (same categorization call as the server)
  - On success: show a checkmark
  - On failure: show an error message

## Subsection — Merchant Mappings
- Search input: "Search for merchant/category"
   - upon search input entered a call to the backend should be made to find the category based on it's name or in the existence of a merchant with similar name.
   - the result should be displayed on the accordion component explained next
- Accordion list of categories (all loaded from server initially or based on the search criteria):
  - Expanding a category shows it's name as a text box -> any change to it should trigger a relative update to the backend and a green disappearing message on complete with the text "updated" ("red" in case of error)
  - Expanding a category shows also its linked merchants as tag/label items
  - Each merchant tag has a pencil/edit type of button. Upon pressing the following should happen:
     - a prompt should appear with name "Change Merchant Category"
     - all the categories should be displayed in a "select" type of component
     - the option to add a new category should be also displayed
     - a button with name "Save" and as a disclaimer should be on the bottom with the following text: "Changing this will affect both existing and new data"
     - upon clicking on the button a call should be made to the settings api with the 2 categories (the one the merchant was removed from & the one the merchant was added to)
  - Long merchant names are truncated; full name shown on hover/click
- Below the accordion: an "Add Category" button (calls server to persist, then reloads the list)

## Subsection — Groups
- Search input: "Search for category/group"
  - upon search input entered a call to the backend should be made to find a category based on it's name or being linked to a group that matches the input
  - the result should be displayed on the accordion component explained next
- Accordion list of groups (all loaded from server initially or based on the search criteria):
  - Expanding a group shows it's name as a text box -> any change to it should trigger a relative update to the backend and a green disappearing message on complete with the text "updated" ("red" in case of error)
  - Expanding a group shows also its linked categories as labels/tags underneath it's name
  - Each category tag has a pencil/edit type of button. Upon pressing the following should happen:
     - a prompt should appear with name "Change Category Mapping"
     - all the groups should be displayed in a "select" type of component
     - the option to add a new group should be also displayed
     - a button with name "Save" and as a disclaimer should be on the bottom with the following text: "Changing this will affect both existing and new data"
     - upon clicking on the button a call should be made to the settings api with the 2 categories (the one the group was removed from & the one the group was added to)
- Below the accordion: an "Add Group" button (calls server to persist, then reloads the list)

# Section: Instruments

## Subsection — Items

- Search input: "Search for instrument/provider"
   - upon search input entered a call to the backend should be made to find an instrument based on that name or to it being linked to provider matching the input
   - the result should be displayed on the accordion component explained next
- Accordion list of istruments (all loaded from server initially or based on the search criteria):
  - they should be grouped by provider name
  - each expanded instrument section should display:
     - it's name as a text box -> any change to it should trigger a relative update to the backend and a green disappearing message on complete with the text "updated" ("red" in case of error)
     - it's key as a text box ("with label Import Mapping Key") -> any change to it should trigger a prompt with header: "Changing this will affect only new data" and buttons "Save" & "Cancel" with both triggering a relative update on the backend
    - it's cyrrency as a select component ->a ny change to it should trigger a prompt with header: "Changing this will affect existing & new data" and buttons "Save" & "Cancel" with both triggering a relative update on the backend. The list of available currencies to choose from are "CHF, EUR".
  - Below the accordion (and within the provider grouping): an "Add Instrument" button:
    - all of the fields of the instrumnet section should be displayed plus a "Save" & "Cancel" button on the bottom
    - chaning any input field data should not trigger an update on the backend like on existing isntruments edit
    - all fields are mandatory
    - when persisting the instrument on the backend, the relative accordion group provider should be added on the input data automatically

## Subsection — Providers

- Search input: "Search for provider"
  - upon search input entered a call to the backend should be made to find an instrument linked to that provider
  - the result should be displayed on the accordion component explained next
- Accordion list of providers:
   - load all (or the ones based on the search input) instruments and group them by provider
   - each expanded provider section should display:
     - it's name as a text box -> any change to it should trigger a relative update to the backend and a green disappearing message on complete with the text "updated" ("red" in case of error)
     - its linked instruments as labels/tags underneath it's name with each having a pencil/edit type of button. Upon pressing the following should happen:
        - a prompt should appear with name "Change Provider Mapping"
        - all the providers should be displayed in a "select" type of component
        - the option to add a new provider should also be displayed
        - a button with name "Save" and as a disclaimer should be on the bottom with the following text: "Changing this will affect both existing & new data"
        - upon clicking on the button a call should be made to the settings api with the the instrument and it's updated provider
    - a sub section called: "File Source" with:
       - it's fileSource.namePattern field as "Import File Pattern" with an input text box -> any change to it should trigger a relative update to the backend and a green disappearing message on complete with the text "updated" ("red" in case of error)
       - below it, 3 examples should be displayed with file names matching that pattern '
    - a sub section called: "Import File Columns Mapping:"
       - all expense model columns should be displayed as a list with the following order from left to right
       - the name of expense model column
       - the mapping type:
          - value "From header name" -> if `sourceName` field is non empty
          - value "From column number" -> if `sourceIndex` field is non empty 
          - value "Predefined" -> if `predefinedValue` field is non empty 
      - On hover of the mapping type a "Change" button should be displayed inline and on click:
          - a prompt should appear with name "Change Mapping Type"
          - a predefined selection component should be displayed with the above 3 options
          - based on the selection a relative input component should be displayed -> either text for predefinedValue & sourceName, or number input for sourceIndex
          - upon change 3 examples should be displayed for the applied mapping based on random input data
          - 2 buttons with name "Save" & "Cancel" -> on save a relative call on the backend is made to update the parent provider instrument with the updated column fields. On cancel button pressed the prompt should close
          - a disclaimer should be added "Changing this will affect only new data"
       - the value of each of the fields mentioned above (depending on which field is non empty)
       - if date column model, an extra field called "Format" should be displayed the format field value -> On hover a "Change" button should be displayed inline and on click:
          - a prompt should appear with name "Change Format"
          - a text box should be available 
          - upon change 3 examples should be displayed for the date format matching
          - 2 buttons with name "Save" & "Cancel" -> on save a relative call on the backend is made to update the parent provider instrument with the updated column format. On cancel button pressed the prompt should close
          - a disclaimer should be added "Changing this will affect only new data"