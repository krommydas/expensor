# Expensor — System Prompt

Create an expense management system called **"expensor"** on this repo (monorepo approach) with the following concepts:

## 1. Backend Server

_See **PROMPT - BACKEND.md**_ 

## 2. Frontend

_See **PROMPT - GUI.md**_

## 3. Persistence
Use the best choise for a database based on the whole system requirements

## 4. Deployment
Use a containerization approach for each component and a turnkey based start/stop
Add the option for "hot-reload" to deploy incremental code changes to each component on the fly

## 5. Hosting
Assume a local "home" set-up with the system exposed to the local network.
Add instructions or create a turnkey hosting set up for someone who only knows how to connect to a wifi

## 5. Non Functionals
- Assume personal use with negligible scaling requirements
- Assume local no auth0/authZ set up with the potential to add in the future
- Assume data volume of 1000 entries per month that span across 10 years
- Assume relatively fast import of data of up to 10000 enties simultaneously
- Priotize consistency across network failures or accessibility
- Use technologies/apis/tools that are mature, popular (for the given task), well maintained, stable and have personal-use free licences
- Prefer off-the-shelve technologies instead of building custom
- AI cost management should be first class citizen in the final build system (wherever & whenever is used)
- any AI prompt entered by the user should be carefully santizied to avoid any injection attacks
- Add e2e tests (including headless browser) to test the functionality:
    - avoid unit tests
    - prefer regression tests cases but also functional ones
    - use mostly a hermetic environment with no real integration to 3rd parties
    - try to use realistic synthetic data
    - add some real integration tests assuming a small set of data, a custom test specific AI API integration approach (cost free if possible) and same for the bank integrations/imports
 - Add a Continious integration gtihub file which should start a pipeline for every commit with the following characteristics:
   - build the whole app/platform on every commit -> fail the pipeline if not success
   - test everything (not the real integration tests) -> fail the pipeline if not success
   - add the support to run manually, if needed, the integration tests
   - the pipeline should be fast to complete

