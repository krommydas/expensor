# Subsection — Merchant Mappings
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

# Subsection — Groups
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