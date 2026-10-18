# WarmPath Guided Demo Script & Presentation Guide

**Target Duration:** 6 minutes (50–60 seconds per pillar + loop finale)  
**Honesty Principle:** Every demo screen prominently displays the warning banner:  
`"DEMO MODE: simulated data and simulated payments. Nothing here is live."`  
The demo runs in pure Dart with **zero backend network calls**, using the exact mathematical formulas from the production specification (`PROJECT_CONTEXT.md`).

---

## Rehearsal Timings (Stopwatch Runs on emulator-5554)
- **Run 1:** 5 minutes 44 seconds (Paced, full explanation of Bayesian smoothing)
- **Run 2:** 5 minutes 28 seconds (Smooth transitions, interactive scam test)
- **Run 3:** 5 minutes 36 seconds (Ideal demonstration timing with Q&A buffer)

---

## 6-Minute Presentation Talk Track

### 0:00 - 0:45 | Introduction & Entry
- **Screen:** Sign-In Screen (`/auth/email`)
- **Taps:** Tap the outlined **"Try guided demo"** button at the bottom.
- **What to say:**
  > "WarmPath is built on the philosophy of 'Building a Network, Not a Directory.' In early hackathon builds, teams often show invented people and fake balances with no label. Today, we present an honest, isolated Guided Demo. Every screen is clearly labelled as simulated, running the exact mathematical formulas as our backend contracts with sample personas."

---

### 0:45 - 1:40 | Pillar 1: Resume & Intent Matching
- **Screen:** Chapter 1 (Pillar 1)
- **Taps:** 
  1. Show consent toggles (DPDP compliance).
  2. Tap Next to view Riya's extracted skills. Tap **"PyTorch"** chip to add it live.
  3. Tap Next to Intent interpretation: select *"Seeking advice on cloud architecture and Kubernetes deployment"*.
  4. View ranked recommendations: point out deterministic why-lines on Arjun and Meera.
  5. Step 5: Highlight **"Why This Order & Hard Gates"**. Point out Sanjay is excluded because his weekly capacity is 0, and Vikram is excluded for unverified credentials.
- **What to say:**
  > "Rather than opaque black-box AI, our matching engine is explainable. It scores expertise (35%), intent (25%), affinity (15%), availability (10%), rating (10%), and response odds (5%). Notice the hard gates: alumni with zero remaining capacity or unverified status are instantly excluded to prevent inbox flooding."

---

### 1:40 - 2:30 | Pillar 2: Free Affinity & Paid Reach
- **Screen:** Chapter 2 (Pillar 2)
- **Taps:**
  1. Show Arjun's card: Own-college alumni connection is **Free forever**. Tap connect.
  2. Tap Next to Meera's card: Cross-college giver is **Locked** (requires Standard/High plan).
  3. View Plans: High Plan (Rs 499 for 2 credits = Rs 249.50/session).
  4. Step 4: Tap **"Simulate Successful Payment (Rs 499)"**.
  5. Step 5: View the Double-Entry Ledger table.
- **What to say:**
  > "Economic fairness is built into our core contracts. Connecting with alumni from your own college is free forever. To reach cross-college mentors, students purchase credit lots. Every transaction is logged in a cryptographic double-entry ledger where the net sum of all debits and credits is mathematically proven to equal zero."

---

### 2:30 - 3:20 | Pillar 3: Rating-Based Earning & Bands
- **Screen:** Chapter 3 (Pillar 3)
- **Taps:**
  1. Submit 5-star rating with note *"Clear architectural guidance"*.
  2. Step 2: Explain Bayesian smoothing math `(5 * 4.0 + 14.0) / (5 + 3) = 4.25`.
  3. Step 3: Drag the sessions slider from 5 -> 15 (promotes to Trusted) -> 26 (Top Rated).
  4. Step 4: Point out the payout shares: 60% for Rising, 70% for Trusted, 80% for Top Rated.
  5. Step 5: Point out the Integrity Guard flagging reciprocal 5-star swaps.
- **What to say:**
  > "On WarmPath, givers earn based on student ratings, not vanity credentials. We use Bayesian m-estimate smoothing with a prior of 4.0 so new mentors build credibility steadily. High ratings promote givers through Rising, Trusted, and Top Rated bands, earning up to 80% payout shares. Collusive rating rings are automatically down-weighted."

---

### 3:20 - 4:10 | Pillar 4: Trust by Design & Moderation
- **Screen:** Chapter 4 (Pillar 4)
- **Taps:**
  1. Type `student@demouniversity.edu` -> verified badge; type `user@gmail.com` -> restricted access.
  2. Show graduated limits: New profiles get 1 request/day; Verified get 5 requests/day.
  3. Interactive Scanner: Tap sample chip *"w h a t s a p p me"* -> Action: **BLOCK / REVIEW**.
  4. Step 4: Show contact masking (phone and email redacted to `[PHONE MASKED FOR PRIVACY]`).
  5. Step 5: Tap **"Resolve Incident"** as Moderator Priya.
- **What to say:**
  > "Trust by design protects students and alumni alike. Domain verification checks official rosters, daily request limits prevent bulk scraping, and our real-time safety scanner intercepts payment bypass attempts and off-platform pushes even when obfuscated with spaced characters."

---

### 4:10 - 5:00 | Pillar 5: Capacity-Aware Connect & Escrow
- **Screen:** Chapter 5 (Pillar 5)
- **Taps:**
  1. Show Giver availability: Arjun commits 3 slots/week and goes Online Now.
  2. Student taps *"Send Instant Connect Request & Lock Escrow"*.
  3. View simulated 20-minute video room.
  4. Step 4: Verify completion checklist (both joined, mutual overlap 18m >= 5m).
  5. Step 5: Tap **"+48h Dispute"** button to fast-forward the virtual clock and trigger escrow settlement.
- **What to say:**
  > "Givers define weekly capacity, so their calendars never get exhausted. Sessions require 5 minutes of mutual presence to count as complete. Once verified, payments enter a 48-hour dispute window. If a mentor ever no-shows, 100% of the credit returns automatically to the student's wallet."

---

### 5:00 - 5:40 | Pillar 6: Institution Network View
- **Screen:** Chapter 6 (Pillar 6)
- **Taps:**
  1. Show Dean Prof. Raman's dashboard. Point out the badge: *"Updated dynamically by your demo actions"*.
  2. View Skill-Gap Analysis: student demand for Cloud Architecture & Kubernetes exceeds alumni supply.
  3. Show the targeted recruitment recommendation: *"Recruit Cloud Architects from Class of 2018-2020"*.
- **What to say:**
  > "For university leadership, WarmPath is an intelligence engine. Every connection logs demand signals. The dashboard highlights critical skill gaps between curriculum demand and alumni supply, giving the career placement office actionable recommendations on who to recruit."

---

### 5:40 - 6:00 | Finale: The Loop & What Is Live Today
- **Screen:** Chapter 7 (Finale)
- **Taps:**
  1. Step 1: Walk through the closed-loop circular diagram.
  2. Step 3: Open **"What is Live vs Simulated"** transparency table.
- **What to say:**
  > "All six pillars form a closed feedback loop: Matching routes the student; Connect protects the session; Rating sets the band; Bands determine payout; Trust shields the network; and Institution analytics guides future recruitment. Here is our reality matrix: our core auth, verification, trust score, and safety rules are live and verified in automated tests today. This concludes our guided walkthrough."

---

## Juror Q&A Handling

### Q: "Is this app connected to a live backend right now?"
> **Answer:** "This Guided Demo runs an isolated, pure-Dart simulation using the exact mathematical formulas from our backend contracts. We created this opt-in mode specifically to avoid showing invented people and fake balances on real screens without labels. Our real backend services (FastAPI, PostgreSQL, Redis) have 11 core E2E contract tests passing in CI, and our reality status screen transparently distinguishes what is live from what is simulated."

### Q: "Why do you use Bayesian smoothing instead of normal star averages?"
> **Answer:** "If a mentor has 1 session with a 5-star review, a simple arithmetic average treats them as a perfect 5.0. If their second session is 3 stars, they plummet to 4.0. Bayesian smoothing with a prior weight of 5 dampens volatility, protecting new mentors from single-review swings and preventing gaming."

### Q: "How do you stop people from bypassing WarmPath to talk on WhatsApp?"
> **Answer:** "Our SafetyEngine runs heuristic and regex rules that detect external pushes, including obfuscations like spaced characters or digit replacements. Contact details are masked until a session is confirmed, and mentors are incentivized to stay on-platform because their rating and band payouts are held in escrow."

---

## Backup Plan
1. **Offline Mode:** The Guided Demo mode requires zero network access and works 100% in Airplane Mode.
2. **Device Redundancy:** Pixel 5 emulator running `flutter run -d emulator-5554` + second Android physical device.
3. **Screen Recordings:** High-definition video recordings of all 6 pillars stored in `docs/demo_recordings/` as an emergency fallback.
