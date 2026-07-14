# Cloudsquare – Partner Application Case Study

## Overview

This solution accepts partner applications through two channels — a public Experience
Cloud form and a public REST webhook — both routed through the **same Apex service**
(`ApplicationProcessingService`).

- If a matching `Account` is found (by Federal Tax ID, or by Name if the Tax ID is
  blank), an **Opportunity** is created.
- If no match is found, a **Lead** is created.

---

## 1. Setup Instructions

### 1.1 Get git repo

Clone this repository:

```bash
git clone https://github.com/vinivilhegasdev/cloud-square.git
```
### 1.2 Deploy the metadata

```bash
sf project deploy start -d force-app/main/default -o <your-org>
```

### 1.3 Experience Cloud site (Guest User)

1. **Setup → Digital Experiences → Enable → New Site** → template **"Build Your Own (LWR)"**.
2. In **Experience Builder**, drag the `applicationForm` LWC onto a public page and
   **Publish**.
3. In the site's **Guest User Profile**:
   - **Apex Class Access**: `ApplicationFormController`, `ApplicationWebhook`.     
   - **Object Permissions**: Read and Create on `Lead` and `Opportunity`; Read on `Account`.
   - **Field-Level Security**: Visible on all fields the form/webhook read or write
     (including `Federal_Tax_Id__c` and `Application_Source__c`).
4. Enable **guest user access to Apex REST** in the site's Security settings so
   `/services/apexrest/external/applications` is reachable without authentication.

### 1.4 Webhook URL

```
https://<your-site-domain>.my.site.com/services/apexrest/external/applications
```

Test with:
```bash
curl -X POST https://<your-site-domain>.my.site.com/services/apexrest/external/applications \
  -H "Content-Type: application/json" \
  -d '{
    "companyName": "Acme Corp",
    "federalTaxId": "BG123456789",
    "contact": {
      "firstName": "Ivan", "lastName": "Ivanov",
      "email": "ivan@example.com", "phone": "+359888123456"
    },
    "annualRevenue": 500000
  }'
```

---

## 2. How the Community Form and Webhook Work

Both entry points are thin adapters over one shared service:

```
Guest User (browser)  →  applicationForm (LWC)
                              │
                              ▼
                  ApplicationFormController.submitApplication()
                        (sets Application_Source__c = "Community")
                              │
                              ▼
              ApplicationProcessingService.processApplication()  ◄──┐
                              ▲                                     │
                              │                                     │
                  ApplicationWebhook.handlePost()                  │
                        (sets Application_Source__c = "Webhook")   │
                              │                                     │
External system  →  POST /services/apexrest/external/applications ┘
```

`ApplicationProcessingService.processApplication(ApplicationDTO app)` is the single
source of truth for the matching + record-creation logic:

1. Look up `Account` by `Federal_Tax_Id__c`; if blank or no match, fall back to an exact
   `Name` match.
2. Match found → create `Opportunity` (`Prospecting`, `CloseDate` = today + 30 days,
   linked to the matched Account).
3. No match → create `Lead` (`Company`, `Federal_Tax_Id__c`, contact fields).
4. Return `{ success, recordType, recordId, message }` regardless of the caller.

Neither the LWC nor the webhook contain any of this logic themselves — they only map
their own input shape into `ApplicationDTO` and pass it along, which is what lets both
channels stay in sync by construction.

---

## 3. Troubleshooting Notes (from actual development)

Two real issues came up while building this, worth knowing if you extend the solution:

1. **Guest User REST class access.** A `global` method's return type must itself be
   `global` — `WebhookResponse` had to be declared `global class`, not `public class`,
   or the compiler rejects `ApplicationWebhook` with "Global methods do not support
   return type of X".

2. **Wrapper serialization to/from LWC.** In this org, plain public fields on
   `ApplicationDTO`/`ApplicationResult` (e.g. `@AuraEnabled public String companyName;`)
   were *not* reliably serialized between the LWC and Apex — inbound data arrived as
   `null` on the Apex side, and outbound fields like `recordType` came back `undefined`
   in the browser. Switching every `@AuraEnabled` field to an explicit property
   (`@AuraEnabled public String companyName { get; set; }`) resolved it. If you add new
   fields to either wrapper, use the same pattern.
