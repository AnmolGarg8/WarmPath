# WarmPath Trust, Safety & Compliance Model

Trust cannot be treated as a checkbox at signup. Open platforms allow bad actors to create fake profiles, promise jobs in exchange for "registration fees", and push vulnerable students to unmoderated channels like WhatsApp or Telegram. 

WarmPath implements a layered defensive architecture designed specifically for college ecosystems.

## The 7-Layer Trust Architecture

| Layer | Implementation | Threat Prevented |
| :--- | :--- | :--- |
| **1. Identity at Entry** | College email + roll number matched against verified institutional lists. Corporate domains + CIN/GST verification for employers. Single-review portfolio check for independent experts. | Impersonation, fake alumni, fake recruiters |
| **2. Layered Badges** | Explicit badges for `Verified Student`, `Verified Alumnus`, `Verified Employer`, and `Verified Expert`. Badges reflect verified data sources, not self-declarations. | Unclear credentials, inflated titles |
| **3. Graduated Privileges** | Accounts start with conservative limits (e.g., maximum daily outgoing requests, inability to post opportunities). Limits expand only as trust scores rise through verified, dispute-free sessions. | Throwaway spam accounts, mass scraping |
| **4. In-App Communication** | All messaging, voice, and video calls happen through in-app channels. Contact numbers and personal emails are never shared by default. | Off-platform harassment, external payment demands |
| **5. Scam Detection Filters** | Automatic rule-based and NLP checks flag triggers like "registration fee", "security deposit", requests for external payment, or links to Telegram/WhatsApp. | Recruitment fraud, upfront payment scams |
| **6. Human Moderation Queue** | One-tap reporting on all messages and user cards. High-severity reports are routed to an admin queue with a pilot target resolution window of 24 hours. | Harassment, repeated bad behavior |
| **7. Incident Learning Loop** | Every verified dispute or breach triggers a post-mortem to update automated detection regex and heuristics. | Repeated attack vectors |

## Recruiter & Job Opportunity Safeguards

Students seeking internships are targets for recruitment scams. We apply strict friction to anyone offering employment:
- Recruiters cannot message students or post opportunities until their company domain and registration (CIN/GST) are validated.
- Automated filters actively block any message requesting money from a candidate for tests, interview slots, or onboarding materials.
- Any attempt to demand payment results in immediate account suspension and notification sent to all contacted students.

## Privacy by Design (DPDP Act Alignment)

WarmPath is designed around India's Digital Personal Data Protection Act:
- **Purpose Limitation**: Resume parsing occurs only after clear, unbundled consent.
- **Data Minimization**: Resumes are not searchable by general users or indexed by search engines. They are only exposed to givers whom the student explicitly chooses to book.
- **Editable Extraction**: Extracted resume entities are displayed to the student for confirmation or redaction prior to vectorization.
- **Data Rights**: Built-in mechanisms allow students to request an export of their data or execute a complete account deletion.
- **Institution Data Ownership**: Roster records supplied by universities remain university property under strict data processing agreements.
