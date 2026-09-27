# Main Tile
 - Once the tile loads a call to the backend api **externalDataProvider.instrumentProviders** should be made (to be cahed, e.g using tanstack query)
 - If the call fails a relative error fading top message should be displayed and the tile closed
 ## Select Instrument Provider 
  A selector type of input with the data returned from the backend call explained above:
   - the `logo` should be displayed (on the left, if available) 
   - along with the `name` of each provider
   - the `country` & `id` should be hidden within each item
   - if the url contains a selected isntrumentProviderId use it to preselect that value 
     - if the id does not exist on the backend returned data display a top fading error message and remove it from the url

 **Once an entry is selected the following should happen:**
  1. retrieve from the `settings.instrumentProviders` entries 1 with `key == selectedItem.id`
  2. if not found save the instrumentProvider in the settings api
  3. if any of the settings call fail clear, display the error (fading top message) and clear the selection
  4. append the selected instumentProviderId in the url
  5. make a call to the backend **externalDataProvider.instruments** api using the selectedItem _name + country_ 
    - if the call fail display the error (fading top message) and clear the *instrumentProvider* selection
    - if the call returns a redirect response, follow it to start the **enableBanking authorization flow** as explained here: https://enablebanking.com/docs/api/reference/#account-information-flow (steps 6 + 7) -> the flow should start on another tab
    - if the call returns an accepted but processing respondse (e.g. 202) start an efficient polling based on the authorization flow set up and until the response is different from accepted  
    - if instrument data are returned from that call display them below on the **instrument selector**

 ## Select Instument
  - That should be a selector field, next to the instrument provider one and should be visible only if the data are avaible as explained in the section above
  - It should display a list of options with `name` visible & `currency`, `id`, `settingsKey` data hidden within each item

  **Once an entry is selected the following should happen:**
   1. A call to settings api to find any entry with `settings.instruments.key` == selected item `settingsKey`
   2. If none available display the **Save Instrument Prompt**
   3. If the user closes the prompt or an error happens and settings do not get updated clear the selection of the instrument
   4. On instrument save success or if instrument is already available select the **Import Period Prompt**
   5. If that prompt closes manually or the follow up import data call fails clear the instrument selection

 ### Save Instrument Prompt
  - It should have a text box editor with name "Select a memorable name for the instrument"
  - An `Save` button (grayed out if text box is empty) should be visible on the bottom, which on click should update the `settings.instrumnets` with a new entry with:
    - name = textbox valie
    - key = Select Instrument selected item -> `settingsKey`
    - currency = Select Instrument selected item -> `currency`
    - provider = selected instrumentProviderid from the url parameter
  - the prompt should close after the settups update or if the user opts to close it manually

 ### Import Period Prompt
  - It should display a "Since" & "Until" period date pickers with text: "Select a period to import data from or leave empty for all data to be imported"
  - An "Import" button should be displayed and on click a call should be done on the backend **externalDataProvider.import** with:
    - `dateFrom`, `dateTo` values from the date pickers 
    - the selected instrument item `id` + `settingsKey`
  - if the call succeeds display the **Results Grid** with the call data 
  - if the call fails display a top fading error message and leave the prompt open
  - the prompt should be closeable manually 

# Results Grid
  - that grid should be displayed below the instrument provider and instrument selectors
  - the logic should be similar to the _PROMPT - GUI - Import - File.md_ file with a small exception when user updates settings column mappings

  ## Inline Column Mapping Settings Update
   - if a `settings.instrumentProviders.sourceColumns` entry exists for the selected instrumentProviderId then the update should behave exactly like the one in the reference _File Import_ page
   - if not, then a "Segmented Button" or a 2 option selector should be added before saving with the following options:
      - "Save as default column mappings for all external instrument providers" (or a shorted name) -> update `settings.externalDataProvider.enableBanking.defaultExpenseColumnMappings` once the user clicks to save
      - "Save only for the selected Instrument provider" -> update `settings.instrumentProviders.sourceColumns` once the user clicks to save
