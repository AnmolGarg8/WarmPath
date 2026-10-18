String translateSessionError(String code, [String? fallback]) {
  switch (code) {
    case 'giver_at_capacity':
      return 'This giver has reached their weekly session limit. Please check back next week.';
    case 'giver_not_online':
      return 'This giver is no longer online. You can book an upcoming slot instead.';
    case 'slot_already_booked':
      return 'This slot has already been taken. Please choose another time window.';
    case 'plan_access_denied':
      return 'Your current membership tier does not grant cross-college access to this giver. Please upgrade your plan.';
    case 'trust_denied':
      return 'You must verify your institution email before sending requests, or you have reached your daily request limit.';
    case 'intent_blocked':
      return 'Your request agenda was flagged by trust & safety filters. Please keep intent professional.';
    case 'communication_blocked':
      return 'Communication with this user is restricted.';
    case 'rate_limit_exceeded':
      return 'Daily connection request limit reached. Please try again tomorrow.';
    case 'outside_booking_horizon':
      return 'This slot is beyond the booking window permitted for your plan.';
    case 'session_not_open':
      return 'This video call is not open yet. Video calls open 10 minutes before the scheduled start time.';
    case 'rating_window_expired':
      return 'The rating window for this session has expired (ratings must be submitted within 14 days).';
    default:
      return fallback ?? 'An unexpected error occurred. Please try again.';
  }
}

String getCreditDisclosureText({
  required bool isOwnCollege,
  required String planName,
  int cost = 1,
}) {
  if (isOwnCollege) {
    return 'Free: own college network (0 credits used)';
  }
  return 'This mentorship session uses $cost credit ($planName plan)';
}
