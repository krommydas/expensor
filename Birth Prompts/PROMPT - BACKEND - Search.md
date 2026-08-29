# Input / Output

The api method input should be:
  - `searchTerm` -> text
  - `useAI` -> boolean
  - `dateFilter` -> { `from`: date, `to`: data (optional) } (optional if `useAI`= true)

 Output should be a list of expense model items

# Logic
First of all, for the *dateFilter.to* field if it's not defined then use the current date.

Also, the search logic should be fast:
 - consider creating a materialized facade of the *expense* model with all the possible search fields enriched to speed up things

 ## when useAI=false

If the `searchTerm` is not empty search for the expense rows where either of the following is true:
 - a field contains the *searchTerm* (except the `id` field)
 - the instrument field belongs to an instrument from the **settings model** where:
    - the `name` or `currency` match the *searchTerm* **OR**
    - the provider field belongs to a *instrumentProvider* entry from the **settings model** where the `name` field match the *searchTerm*
 - the category field belongs to a category entry from the **settings model** where the `group` field  match the *searchTerm*

If the `searchTerm` is empty, then select all expense rows.

Besides the `searchTerm` filtering criteria the `dateFilter` should **always** be applied:
 - the expense model `date` field should be within the *from* & *to* parameters of the filter

## when useAI=true

 - for this mode use either an embedded LLM or the ai settings to talk to an external model to convert the `searchTerm` into a query that can filter and sort the data when applied.
 - the input of that operation should be the `searchTerm` and the output the mentioned query (be mindful of leaking sensitive data if relying on an external AI model).
 - the system should apply the query to filter & short the data before returning them on the output
 - the system should expose a query definition that includes filtering & shorting options on all the possible data fields (names & types of data)
   - consider an "enriched" facade of all possible expense columns should be used for the fields defintion
   - consider if the use of a predefined off-the-shelve querying language would help in that logic (e.g graphQL) 