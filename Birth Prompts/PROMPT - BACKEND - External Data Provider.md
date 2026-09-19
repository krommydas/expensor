The **enableBanking** api reference is here: https://enablebanking.com/docs/api/reference/
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

# Login
 ## Input
  enableBanking **Aspsp** details:
   - name
   - country
 ## Output
  It will be one of the following:
   - void and a relevant OK void response
   - enableBanking **StartAuthorizationResponse**:
     - url
     - authorization_id
     - psu_id_hash
   - error with details of the issue
 ### Logic
- The relevant enableBanking session details (see below) should be checked from the cache and evaluate if they have been expired
- If not expired and available the call should return a success response
- If expired or not available a call to **Start user authorization** should be made with the following details:
   - `aspsp` -> the input Aspsp details
   - `access.valid_until` -> pick a risk averse value that doesn't compromise the user experience while trying to refine the import logic (see the relevant section on the GUI details)
   - `state` -> ""
   - `redirect_url` -> the relevant location of the **Login-Callback** api mentioned below

# Login-Callback
 - on the query url it should expect a `code` parameter as explained in the documentation
 - a call to the **Authorize user session** should be made with that code
 - the following should be stored stored in the cache (specific cache for this) from the results
     - list of: `accounts[].account_id`, `accounts[].name` 
     - the cache entry(ies) should have an entry epxiry time equal to the one selected in the `access.valid_until` from the Login api above
 - if the call fails a relevant entry should be made to the cache for the error

# Instruments
 This api should accept no input and return back one of the following:
  - a success response with the account details stored in the cache (if available) as explained in the `Login-Callback` api
  - an error response with the details from the relevant cache entry (if available) as explained in the `Login-Callback` api
  - an empty response indicating a "waiting" stage if none of the above is available