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
  - historicalData
  - dataExport
  - dataImport

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

## Aggregated Data

### Input 
- `PeriodStart` -> date
- `PeriodEnd` -> date
- `Filters` -> array of [filter on any of the expense model fields - except date] (_optional_)
- `Aggregator` -> one of: Merchant, Category, Category group, Instrument (_optional_)
### Output
 A list of:
- `Value` -> number (Int)
- `PeriodStart` -> date
- `PeriodEnd` -> date
- `AggregatorValue` -> text (_optional_)

# Background Jobs

## Syncing Historical Data



