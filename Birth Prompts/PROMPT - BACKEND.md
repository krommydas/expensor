Use modern, mature, lightweight technologies.

# Data Models

 _See **PROMPT - BACKEND - Model.md**_ 

# API

Choose based on the requirements on the GUI section about the API type (rest or graphql or grpc).

The following resources/operations/endpoints/actions should be supported:
  - settings
  - expenses
  - search
  - fileImport
  - aggergatedData
  - externalAggregatedData
  - syncExternalAggregatedData
  - syncHistoricalrates
  - dataExport
  - dataImport
  - dataReset
  - externalDataProvider
     - verify
     - instrumentProviders
     - loginCallback
     - instruments
     - expenses


## Settings
Expose **CRUD** operations with validations for update operations to ensure the data consistency (e.g. a merchant can not belong to more than 1 categories).

## Expenses
Expose the following operations:
### create
  - input: either a single or a list of full expense model (without the id column)
  - output: a status indicating the result of the opretion
  - operation: add the expense model(s) (autogenerate the id) 
### update
  - input: a list of expense models
  - output: a status indicating the result of the operation
  - operation: -> update the relevant expense models based on their id -> if any of the update fails, fail the whole operation and rollback
### delete
  - input: a list of expense model ids
  - output: a status indicating the result of the opretion
  - operation: -> delete the relevant expense models based on their id -> if any of the delete fails, fail the whole operation and rollback

 ## Search

 _See **PROMPT - BACKEND - Search.md**_ 

## File Parse

_See **PROMPT - BACKEND - File Import.md**_ 


## Syncing Historical rates
The api should accept no parameters and do the following:

1. If the `HistoricalRates.isLoading` is **true** schedule to start again a bit later (add max retries), otherwise update the value to `true` 
2. Find the max & min dates of all expenses
3. Find the max & min dates of all `HistoricalRates`
4. Find all the unique currencies from `settings.instruments` that do not match the currency from the `settings.dataCountryProfile`
5. If there are no currencues do nothing (_all expenses stored instruments with local currency_)
6. If the min & max of the rates conrtain the equivalent dates for expenses and all currencies from step **4**, finish the flow
7. If not, use an external API to get the historic rates using the min & max dates of the expenses & the currency pair combinations between the currencies found in step **4** and the local currency (`settings.dataCountryProfile`)
8. Store the results and at the same time update the flag `HistoricalRates.isLoading` to false

## Aggregated Data
_See **PROMPT - BACKEND - Aggregated Data.md**_ 

## External Aggregated Data
_See **PROMPT - BACKEND - Aggregated Data.md**_ 

## Syncing External Aggregated Data
_See **PROMPT - BACKEND - Aggregated Data.md**_ 

## Export/Import

2 distinct APIs to import or export all data from/to file
 - file should be compressed/decompressed
 - data should be encrypted/decrepted -> use an embedded private key

## Reset

An api with no inputs, which on call it should delete all of the stored data

## External Data Provider
_See **PROMPT - BACKEND - External Data Provider.md**_ 
