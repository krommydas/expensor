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
     - import


## Settings
Expose **CRUD** operations with validations for update operations to ensure the data consistency (e.g. a merchant can not belong to more than 1 categories).
Secrets (e.g `externalDataProvider.privateKey` & `ai.key`) should only be updatable and should be returned masked in get operations

## Expenses
Expose the following operations:
### create
  - input: either a single or a list of full expense model (without the id column) + a field per item to indicate if to override duplicates
  - output: a status indicating the result of the opretion
  - operation: add the expense model(s)
  #### ID & Duplicates
    - auto generate the id based on the hash of the fields for each item
    - the id should be a primary key and a referential constraint on the table/storage entity
    - if a flag is set to override duplicates than an extra "salt" should be entered during the id generation to be able to insert the row
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
2. Find all the unique currencies from `settings.instruments` that do not match the currency from the `settings.dataCountryProfile`
3. If there are no currencues do nothing (_all expenses stored instruments with local currency_)
4. Find the max & min dates of all expenses
5. Use an external API to get the historic rates using the min & max dates of the expenses & the currency pair combinations between the currencies found in step **2** and the local currency (`settings.dataCountryProfile`)
6. Store the results and at the same time update the flag `HistoricalRates.isLoading` to false

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
