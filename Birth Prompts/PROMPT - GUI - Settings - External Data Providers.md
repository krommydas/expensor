 # Sub-Section: Enable Banking
  - A short message explaining what is open banking / PSD2 in europe, the role enablebanking plays (maybe a link would be nice).
  - Below or on the side a label with text: "Application Id" and next to it a textbox (initialized from `settings.externalDataProvider.enableBanking.appId`)
  - Below that, a file input selector with title: "Select private key". Once a file is selected, the system should read the file and:
     - Put it's contents on a background variable (initialized from `settings.externalDataProvider.enableBanking.privateKey`)
     - Display the filename on the right of the selector (initialized from `settings.externalDataProvider.enableBanking.privateKeyFileName`)
  - A "save changes" button should be displayed on the bottom (if any changes were made) and update the relevant settings model with display of the result like the rest of the settings
     - The button should be grayed out if not all of the input fields are filled

  ## Default Column Mappings
  Within the same section, an expandable list with with name: "Default Column Mappings" should be displayed which contain items with:
   - on the left the `enableBankingSource`
   - on the middle a "transition" kind of icon to emphasize the mapping from left to right (e.g material design icon "Arrow Right Alt")
   - on the right the expense source column displayed as text (e.g Date) initialized from the `settings.externalDataProvider.enableBanking.defaultExpenseColumnMappings[].target`
  Users should not be able to delete or add any items on the list and it's data on loading should be initialized from the `settings.externalDataProvider.enableBanking.defaultExpenseColumnMappings`
   - the data for this list should come from the settings model of: `settings.externalDataProvider.enableBanking.defaultExpenseColumnMappings`
   - if the relevant setting above is missing a value then a predefined hardcoded value (`PredefinedDefaultColumnMappings`) will be used
  
  ## EnableBankingSource
  That should be a button which should display the path from `settings.externalDataProvider.enableBanking.defaultExpenseColumnMappings[].sourceFieldPath` in text pieces from left to right separated with a "tranisition icon" (_e.g. "Transaction Amount -> Amount"_). The text pieces should be converted from "json" friendly path names to human readable ones, for example: "transaction_amount" -> "Transaction Amount". Once this button is clicked it should open a dialog window with:
   - title something like: "Select Source"
   - on the left an `Expandable Menu`
   - on the right a `Preview Section`
  ### Expandable Menu
   - That should be an expandable menu from left to right (e.g. material design "Cascading menu")
   - Every menu structure should be driven from the transation schema of enablebanking: https://enablebanking.com/docs/api/reference/#transaction
   - If a "leaf" item is selected from the current menu the whole `EnableBankingSource` dialog should close and the current menu path should be stored with "dots" on the `settings.externalDataProvider.enableBanking.defaultExpenseColumnMappings[].sourceFieldPath` (_e.g. "transaction_amount.amount"_)
   - a call to the backend settings api should be made to save that setting and a relative fading positive or negative message displayed on top of the page
  ### Preview Section
   - That should be a tab bar with 2 options: "Current Level Example", "Full Example"
   - If the first option is selected, it should display an example from synthetic predefined transaction data for the current `Expandable Menu` selected on the left, for example:
      ```
     "balance_amount": {
        "currency": "EUR",
        "amount": "1.23"
      }
      ```     
  - If the second option is selected a scrollable preview of the full synthetic predefined transaction data should be displayed
  
 ## Predefined Default Column Mappings
 ```json
 [
    {
        "target": "date",
        "sourceFieldPath": "transaction_date",
    },
    {
        "target": "merchant",
        "sourceFieldPath": "creditor_account.name",
    },
    {
        "target": "amount",
        "sourceFieldPath": "transaction_amount.amount"
    },
    {
        "target": "instrument",
        "sourceFieldPath": "debtor_account.other.identification"
    },
 ]
 ```
  