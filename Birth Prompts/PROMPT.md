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
- Use free for personal use technologies
- AI cost management should be first class citizen in the final build system (wherever & whenever is used)

