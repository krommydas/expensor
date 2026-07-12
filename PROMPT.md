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

The page should display a grid with some search options on top of it. The title should be: "Manage Expenses". It should consist of 2 sections: the *search bar* which should be "sticky" and the *expenses grid* which should be scrollable up to 3 times the current view unit height.

#### Search bar

The look and feel should be copied from the Splunk search bar with a search box on the left followed by a time selection and the search button. On top of the search box, a checkbox should be displayed with title: "Enable AI". Upon loading of the page the following search default filters should be applied and the relative call to the backend be done: 
   - *search string*: empty
   - *time selection*: "last month"
   - *ai checkbox*: "diabled"

Upon success or failure of that first call on the backend the same things as described on the *search button* section should be performed.

**search box**
 - it should have as a placeholder: "enter search terms" if **AI Checkbox** is not checked or "enter search instructions" if it is checked

**time selection**
 - it should contain splunk "preset, "relative" & "date range" options and for all of them the lowest unit offered should be days
 - the selected value should always be translated to a "from" - "to" (optional) date filter
 - every value displayed as "Last unit X" should be translated to a "from" date filter with X being either days, months or years to look in the past (current date minus) according to the unit entered (e.g. 3 days back)
 - every value displayed as "Last X" should be translated to a "from" date filter where according to the X value (days, months or years) we look on the start of the period (e.g. last month)
 - a date range filter corresponds to a "from" - "to" date filter for the backend

**search button**
 - upon clicking a call to the `/search` backend endpoint should be made with the serach box content (string) + the time filter (from - to dates) + the value of the AI checkbox (boolean)
 - if the call fails an error should be displyed as fading away from the top
 - if the call succeeds the grid below should be displayed with the data retrieved (`expense model` rows)

#### Expenses Grid

The grid should displayed the expense rows retrieved from the backend. It should have 3 sections: *Header Row* (sticky), *Data Rows* (scrollable) & *Footer Row* (sticky).
The data displayed should be paginated only if the amount of rows exceeds the current view unit height multiply by 3. In that case the results should be divided to pages so as every page rows fulfills that rule.

##### Header Row
 The expense model colums should be displayed (except the `id`) with the option to short data based on them (but not filter) + 1 extra column in the left with a checkbox

##### Footer Row 
 - It should display the number or rows selected, only if any or the rows checkbox is selected.
 - A split button with the following options: "Delete Selected" (default) & "Adjust Selected". The button should only be visible if any or the rows checkbox is selected.
 - A pagination component should be displayed on the right only if multipe pages are available for the results

 **Split button**:
   - if the "Delete Selected" option was pressed a prompt should be displayed with the following mesage: "All of the selected expenses will be deleted for ever. Are you sure ?"
   - if yes a call to the backend should be made with the selected row ids and show either a fading success (green) or error (red) message on the top
   - upon successfull response the data of the grid should be refetched from the backend using the same filters
   - if the "Adjust Selected" button is clicked a prompt should be displayed with the title: "Adjust expenses"
   - a select component with the expense fields (except `id` & `importMnemonic`) should be displayed  with label "Select field to update"
   - depending on the selected field type a relevant component should be displayed
     - date -> date editor
     - amount -> number editor
     - merchant, category -> another select component on the right with the values retrieved from the `settings.categories` field (merchant should be flatten)
     - instrument -> another select component on the right with the values retrieved from the `settings.instruments` field
     - 