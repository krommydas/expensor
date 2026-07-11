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
  - Manage
  - Import
  - Settings
- **Right panel** showing the selected page content

---

### Settings Page

_See **PROMPT - GUI - Settings.md**_ 

### Import Page

_See **PROMPT - GUI - Import.md**_

### Management Page

The page should display a grid with some search options on top of it. The title should be: "Manage Expenses"

#### Search bar

The look and feel should be copied from the Splunk search bar with a search box on the left followed by a time selection and the search button. On top of all that, a button should displayed on the right with title: "Pin Instrument Provider".

**search box**
 - it should have as a placeholder: "enter either search terms or instructions" or something equivelant

**time selection**
 - it should contain splunk "preset, "relative" & "date range" options and for all of them the lowest unit offered should be days

**pin instrument provider**
 - upon clicking a call to the backend should be made to retrieve the settings and specficially `instrumentProviders`
 - if the call fails a relative error message should be displayed as dissapearing from the top and nothing else should happen
 - if the call succeeds a prompt should be open with title: "select an instrument provider"
 - the prompt should contain a select component where you can select the instrument provider (select by name)
 - next to it another select component with placeholder: "specific import" where the `pastImports` should be displayed by date (order by descending)
   - another option should be injected to that list, always displayed on top and be preselected: "All"
 - on the bottom right two buttons should be displayed: "Pin Provider", "Cancel"
 - upon clicking on "Cancel" the prompt closes with no further action
 - upon clicking on the other button, the selected provider + the pastImport (if an option other than the injected one was selected) are stored in the background
 - the prompt closes and the select provider name is displayed on the left of the `pin instrument provider button` as a small tile with:
     - provider name visible + on the botton right with smaller font the pastImport date (if selected)
     - a clickable "x" icon on the top right which on click should remove that provider tile and clear it as a stored value on the background
     - the instrument provider `key` & pastImport `mnemonic` should be used then on all searches on the grid below as extra parameters