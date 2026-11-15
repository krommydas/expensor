ngrok is used as reverse proxy for the login callback from external banking. It's documentation can be found here: https://ngrok.com/docs/start.
An agent sdk applying to the application coding language should be used to start the reverse proxy when needed

# Verify
That call should verify/sync the set up needed for the reverse proxy. It will expect an API key
 1. First it should call the list `credentials` (get) resource fron ngrok
 2. If the call fails than a related error response should be returned
 3. If the result succeeds and the list contains any element with `token` = `settings.externalDataProvider.callback.agentToken` then a sucess response should be returned
 4. If there is no item on the response that matches the above condition than the `create` (POST) call should be used on the same resource to create a new item
 5. If the create call fails a a related error response should be returned
 6. If the create call succeeds than the `token` from the response should be saved to the related `settings` field and a sucess response should be returned

 # Start Proxy
 
