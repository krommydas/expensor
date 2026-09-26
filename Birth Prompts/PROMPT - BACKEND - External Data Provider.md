The **enableBanking** api reference is here: https://enablebanking.com/docs/api/reference/

An app wide cache would be needed for this section or something native to the web framework used
The cache should contain the following data/structure:

**Active Session Details**
  - instrumetProviderId
  - sessionId
  - startedAt 

# Verify
 - That endpoint should accept as input a credentials object containing an app Id & secret (both string)
 - It should use the secret to generate a jwt token and make a call to the "Get Application" api of enableBanking
 - If the call returns anything except a success response (200 http status code) return an error response, otherwise a positive one

# Instrument Providers
- That endpoing should accept no and return a list of instrument provider details explained below
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
  - list of: `instruments[].id`, `instrument[].name`
  - enableBanking **StartAuthorizationResponse** or just a redirect url.. depends on how the authorization on the external provider should kick in
     - url
     - authorization_id
     - psu_id_hash
 ### Logic
  The cache should be checked for an active not expired session with instrumentProviderId matching the one provided (based on hashing of name & country) in the input
  #### Cache Hit or valid session active
   1. a call to **Get session data** of enableBanking should be made with the sessionId
   2. for each of the ids in `accounts` from the response an async call to `Get account details` -> wait for all of them to finish
   3. return combination of `account_id` & `name` of each of those calls as list of instruments as explained in the Output section
  #### Cache miss or no valid session
   - previous cache or session details should be cleared
   - then, a call to **Start user authorization** should be made with the following details:
     - `aspsp` -> from the input
     - `access.valid_until` -> pick a risk averse value that doesn't compromise the user experience while trying to refine the import logic (see the relevant section on the GUI details)
     - `state` -> the instrumentProviderId (hash of country & name as explained above)
     - `redirect_url` -> the relevant location of the **Login-Callback** api mentioned below
   - the details should be returned a explained in the output section

# Login-Callback
 - on the query url it should expect either a `state` variable or just plain string with the instrumentProviderId
 - a `code` parameter as explained in the documentation should be in the body
 - a call to the **Authorize user session** should be made with that code
 - the following should be stored stored in the cache (specific cache for this) from the results
     - session_id, current_timestamp + instrumentProviderId

# Expenses
 ## Input
  - instrumentId
  - dateFrom, dateTo (optional)
 ## Output
 ## Logic
  - a call to **Get account transactions** of enableBanking should be made with accountId coming from the input (and dates, if provided)
  - if a `continuation_key` is provided, continue polling the api for data until this key is empty
  - 