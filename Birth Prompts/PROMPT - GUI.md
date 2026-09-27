Use **React** with **React Context** for state management, **Material UI** for styling, and **Vite** for building.

# Layout

- **Left sidebar** with 4 navigation entries, each with an icon:
  - Reports (also serving as "Home")
  - Manage
  - Import
  - Settings
- **Right panel** showing the selected page content

---

# Settings Page

_See **PROMPT - GUI - Settings.md**_ 

# Import Page

Displays **tiles**: "Automatic (EU only)", "Manual"

- Clicking a tile hides all other tiles and opens a **pane** with:
  - `×` button (top-right) — resets to tile view
  - Tile name as header
- The Automatic (EU only) should be displayed only if the `settings.externalDataProvider.enableBanking.appId` has a value

 ## Import Automatic
  _See **PROMPT - GUI - Import - Automatic.md**_

 ## Import Manual
  _See **PROMPT - GUI - Import - File.md**_

# Management Page

_See **PROMPT - GUI - Management.md**_ 

# Reports Page

_See **PROMPT - GUI - Reports.md**_ 

# External Provider Enablebanking Callback Page
  - that page should not be in the menu
  - it should expect a `code` & `state` url parameters
  - it should make a call to the backend **externalDataProvider.loginCallback** with the code and `instrumentProviderId` = state url parameter
  - after the call a redirect to **Import Automatic** page should be made
    - if the call fails a relative error top fading message should appear suggesting to the user to start the authorization process again -> redirect should continue
    - if the call succeeds the redirect page should be opened with url parameter `instrumentProviderId` = state url parameter