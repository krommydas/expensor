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


