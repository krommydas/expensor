- each of the following section is `expandable`
- try to make use of reusable react components, if possible, without sacrifycing extendiblity by introducing too much tight coupling

# Section - AI Source
- Dropdown: AI model (one option: "Claude")
- Input: "Api Key"
- On dropdown change or on blur of the key input → call server to persist
- "Test Connection" button:
  - Calls the AI provider with the configured credentials (same categorization call as the server)
  - On success: show a checkmark
  - On failure: show an error message

# Section: Categorization

_See **PROMPT - GUI - Settings - Categorization.md**_ 

# Section: Instruments

_See **PROMPT - GUI - Settings - Instruments.md**_ 

# Section: External Data Providers

_See **PROMPT - GUI - Settings - External Data Providers.md**_ 

# Section: Reports

 ## Sub-Section: General
   - A country predefined selection should be displayed with the following countries: (Switzerland, Greece) (`settings.reports.dataCountryProfile`) with title: "Select the country of residence"
   - A relative info message should be displayed with something like "The selected country will be used for currency conversion in case of an expense found in a foreign currency"
  - A "save changes" button should be displayed on the bottom (if any changes were made) and update the relevant settings model with display of the result like the rest of the settings
 ## Sub-Section: AI Assisted Historical Data
  - The whole section should be displayed only if the **AI Source** setting has been successfully configured.. if not it should be grayed out with a relative message indicating what needs to be configured first
  - A list of "Usage Profile Prompts" should be displayed (`settings.reports.assistedHistoricalDataProfiles`) with every item containing a delete icon at the end
  - Also an add icon should be displayd at the bottom on the list, when on click it should display a text box with a placeholder value: "e.g. average household of 2"
  - A warning/info or tooltip message should be displayed with something like "Do not enter any period or country details as those could confict with the reports set up"
  - if you click somewhere else without a value entered the textbox should disappear and nothing added to the list.. otherwise the typed value should be added to the list
  - A "save changes" button should be displayed on the bottom (if any changes were made) and update the relevant settings model with display of the result like the rest of the settings

# Section Bulk Data Operations

 ## Sub-Section: Restore
  - Add one row with title "Restore from" and a button next to it with title "Select File"
  - When clicked, the user should prompted to select a file from the filesystem (only files with the format used in the export api should be selectable)
  - When the file is selected a relevant call to the APi should be made and a relevant message with success of failure should be faded away on the top of the page
 ## Sub-Section: Backup
  - Add one row with title "Create a back-up" and a button next to it with title "Start"
  - When clicked, a relevant call to the API should be made and a relevant message with success or failure should be faded away on the top of the page
  - if it is success, a file should be downloaded from the backend to the user device
 ## Sub-Section: Reset
  - Add one row with title "Delete all data" and a button next to it with title "Start"
  - When clicked, the user should be prompted with a message like: "Are you sure ? This is a terminal operation and all data would be lost" and an "Yes" & "No" button
  - Also, in a "lower" font display a message like: "A most recent backup of the data would be also exported in any case"
  - If "No" is clicked, do nothing
  - If "Yes" is clicked do the following:
      1. Do a call to the Export API -> if the call fails do not do anything else and display a relevant error message
      2. If the call succeeds a file should be downloaded from the backend to the user device
      3. Then, do a call to the `Reset` api and a relevant message with success or failure should be faded away on the top of the page



