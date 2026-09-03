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
### Logic
 1. Load the `HistoricalRates` items from the storage -> if `isLoading` field is _true_ throw an exception and return a relevant error response
 2. Cache the rates per date and `currencyFromISO`
 3. The expenses should be loaded/filtered using the period and filters (if any)
 4. Find the unique values of the selected aggregator field from the expenses loaded
 5. The period should be split into months/buckets and for each one calculate the combinations with the aggegator values
 6. For each of those final buckets find all expenses that fall within (based on their date and aggregator field value)
 7. Reduce the expenses by summing their amount field on each bucket
     - The final amount value per backet should be on the currency of the `settings.reports.dataCountryProfile` 
     - If any expense belongs to an instrument with currency different from that currency use the cached rates to convert the amount accordingly
     - The final sum amount should be rounded to an integer value
 8. Return those buckets as response

## External Aggregated Data
### Input 
- `PeriodStart` -> date
- `PeriodEnd` -> date
- `Source` -> string
### Output
 A list of:
- `Value` -> number (Int)
- `PeriodStart` -> date
- `PeriodEnd` -> date
- `AggregatorValue`
### Logic
1. Load the `ExternalAggregatedData` items from the storage -> if `isLoading` field is _true_ throw an exception and return a relevant error response
2. Filter the data with the source field matching the provided input
3. The period should be split into months/buckets and for each one there should be a start & end date
4. For each bucket find the relevant entry in the loaded entry
5. Return the results according to the Output of the call mentioned above

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

## Syncing External Aggregated Data
The api should accept no parameters and do the following:

1. Load the `settings.reports.assistedHistoricalDataProfiles` and if they are empty do nothing 
2. If the `ExternalAggregatedData.isLoading` is **true** schedule to start again a bit later (add max retries), otherwise update the value to `true` 
3. Load all expenses and find the following:
   - max & min dates
   - all the unique categories (using the relevant setting)
4. Split the period into months and out of them create aggregated data "buckets" with combinations of categories
   - every bucket should have a start & end date and an expense category value
5. Calculate all of the possible permutations of `settings.reports.assistedHistoricalDataProfiles` & buckets
6. Load of the existing permutations from `ExternalAggregatedData.items` (assume bucket.category == aggregatorValue && assistedHistoricalDataProfiles[] == source)
7. If the existing permutations is a superset of the calculated ones do nothing and exit the flow
8. For every calculated permutation that is missing from the existing ones, use the configured AI model from the settings to load the dats from the internet using a prompt like:
  ```
  "For the period: {bucket.start - bucket.end} get the average expenses spending for the category: {bucket.category} using the following spending profile: {assistedHistoricalDataProfiles item} and expressed in the following currency: {currency of the settings.reports.dataCountryProfile}
  ```
9. For each AI call you should get an amount number back and when all are finished the results should be stored in the `ExternalAggregatedData.items` accordingly
10. At the end the `ExternalAggregatedData.isLoading` flag should be set to false

## Export/Import

2 distinct APIs to import or export all data from/to a compressed file

## Reset

An api with no inputs, which on call it should delete all of the stored data
