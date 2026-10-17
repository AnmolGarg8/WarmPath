# Ratings & Dispute Module

**Owner:** M3 (Availability, Sessions & Ratings)

## Responsibilities
- Mandatory two-way ratings following session completion
- Bayesian smoothed rating calculations:
  `smoothed_avg = (prior_mean * prior_weight + sum_ratings) / (prior_weight + n)`
  (defaults: prior_mean=4.0, prior_weight=5)
- Rating band determination:
  - **Rising:** default (60% payout share)
  - **Trusted:** smoothed avg >= 4.2 & >= 5 rated sessions (70% payout share)
  - **Top Rated:** smoothed avg >= 4.6 & >= 10 rated sessions & completion rate >= 90% (80% payout share)
- 48-hour dispute window & dispute resolution pipeline (/sessions/{id}/dispute, /admin/disputes)
- RatingsPort implementation
