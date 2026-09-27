The **enableBanking** api reference is here: https://enablebanking.com/docs/api/reference/

An app wide cache would be needed for this section or something native to the web framework used
The cache should contain the following data/structure:

**Active Session Details**
  - instrumetProviderId
  - sessionId
  - startedAt 

**Pending Authorization**

# Verify
 - That endpoint should accept as input a credentials object containing an app Id & secret (both string)
 - It should use the secret to generate a jwt token and make a call to the "Get Application" api of enableBanking
 - If the call returns anything except a success response (200 http status code) return an error response, otherwise a positive one

# Instrument Providers
- That endpoing should accept nothing and return a list of instrument provider details explained below
- A call to enableNaking **Get list of ASPSPs** should be made with the following parameters:
  - the jwt token generated from the `settings.externalDataProvider.enableBanking.privateKey`
  - country passed from the input
  - `psu_type=Personal`
  - `service=AIS`
- If the call fails a relevant error message should be returned with the reason
- If the call succeeeds a list of the following should be returned:
  - name
  - logo
  - country
  - id -> hash of name & Country fields

# Instruments
 ## Input
  selected Instrument Provider
   - name
   - country
 ## Output
  It will be one of the following:
  - list of: id, name, currency, settingsKey
  - enableBanking **StartAuthorizationResponse** or just a redirect url.. depends on how the authorization on the external provider should kick in
     - url
     - authorization_id
     - psu_id_hash
  - something to indicate an authorization session is in progress (e.g. Http Status Code: 202 - Accepted)
 ### Logic
  The cache should be checked for an active not expired session with instrumentProviderId matching the one provided (based on hashing of name & country) in the input.
  Also, the existence of a pending authorization entry should be checked   
  #### Cache Hit or valid session active
   1. a call to **Get session data** of enableBanking should be made with the sessionId
   2. for each of the ids in `accounts` from the response an async call to `Get account details` -> wait for all of them to finish
   3. use the following mapping from the responses of all of those call to construct the list of items for the Output
      - uid -> `id`
      - identification_hash -> `settingsKey`
      - currency
      - _details_ **or. if empty** _account_id.iban_ **or, if empty** _account_id.other.identification_ -> `name`
  #### Cache miss or no valid session & No Pending Authorization 
   - previous cache or session details should be cleared
   - then, a call to **Start user authorization** should be made with the following details:
     - `aspsp` -> from the input
     - `access.valid_until` -> pick a risk averse value that doesn't compromise the user experience while trying to refine the import logic (see the relevant section on the GUI details)
     - `state` -> the instrumentProviderId (hash of country & name as explained above)
     - `redirect_url` -> the **External Provider Enablebanking Callback Page** as explained in _PROMPT - GUI.md_ file
   - the details should be returned a explained in the output section
   - a cache entry should be written as "pending authorization" with ttl a reasonable value until the user finishes the authorization flow
  #### Cache miss or no valid session & Pending Authorization
   - return immediately a relative response as explained in the Output section above

# Login-Callback
 ## Input
   code, instrumentProviderId
 ## Logic
 - a call to the **Authorize user session** should be made with that code
 - the following should be stored stored in the cache (specific cache for this) from the results (if the call succeeeds)
     - session_id, current_timestamp + instrumentProviderId
     - the entry should have a ttl equal to the enableBanking session expiration time picked when doing the **Start user authorization** at the `Instruments` api
 - the **Pending Authorization** entry should be deleted from the cache -> that action should happen even if the previous call fails


# Import
 ## Input
  - instrumentId
  - instrumentSettingsId
  - dateFrom, dateTo (optional)
 ## Output
 - A list of parsed rows, each containing expense model fields (some may be empty) **without** the `id` column/field
 - A sample list of rows parsed (not mapped to expense columns):
   - include the header row if one is found
   - include a list of rows with each row having either a list of column values (text) or column attributes & values
 - the column mappings (type of `settings.instrumentProviders.sourceColumns` - except of the sourceIndex) used for this mapping
 ## Logic
  1. a call to **Get account transactions** of enableBanking should be made with accountId coming from the input (and dates, if provided)
  2. if a `continuation_key` is provided, continue polling the api for data until this key is empty
  3. flatten the response nested structure data (e.g. `transaction_amount.amount` & `transaction_amount.currency`)
  4. follow **Duplicate protection** as explained here _PROMPT - BACKEND - File Import.md_ (maybe a generic functionality ?)
    - use the _instrumentProviderId_ from the cache to find the relevant settings entry
    - the mnemonic should contain the following:
       - instrument provider name (maybe shorten if too long) -> use instrumentSettingsId from input to find it in the `settings`
       - instrument name (maybe shorten if too long) -> use instrumentProviderId from the cache to find it in the `settings`
       - datefrom(if applicable) 
       - dateTo (if applicable) 
       - currentTimestamp
  5. try to find the mapping logic to the native **expense** model using the the first approach that is applicable from below
     - if a `settings.instrumentProviders[].key` == _cache.instrumetProviderId_ record is found with sourceColumns mappings, use it to map the data
     - if a `settings.externalDataProvider.enableBanking.defaultExpenseColumnMappings` entry is found use it to map the data
     - use the **Predefined Default Column Mappings** as explained in -> _PROMPT - GUI - Settings - External Data Providers.md_ 
  6. map the data following the **Apply Columns Mapping** as explained in -> _PROMPT - BACKEND - File Import.md_ (maybe a generic functionality ?)
  7. follow the **Post Processing** as explained in -> _PROMPT - BACKEND - File Import.md_ (maybe a generic functionality ?)
  8. return the data as explained in the _Output_ section

