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

 ## Sub-Section: AI Assisted Historical Data
  - The section should be visible only if the **AI Source** setting has been successfully configured
  - A toggle like button "enable" should be displayed
  - if enabled a country predefined selection should be displayed with the following countries: (Switzerland, Greece, )
