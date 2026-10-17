import { ModerationItem, VerificationQueueItem } from './api';

/**
 * Checks whether an item in the moderation queue has breached or is close to
 * the 24-hour pilot SLA target.
 */
export function calculateSlaStatus(createdAt: string | Date): {
  hoursElapsed: number;
  isBreached: boolean;
  isWarning: boolean;
  label: string;
} {
  const created = new Date(createdAt);
  const now = new Date();
  const diffMs = now.getTime() - created.getTime();
  const hoursElapsed = Math.max(0, Math.floor(diffMs / (1000 * 60 * 60)));

  const isBreached = hoursElapsed >= 24;
  const isWarning = hoursElapsed >= 18 && hoursElapsed < 24;

  let label = `${hoursElapsed}h ago`;
  if (isBreached) {
    label = `SLA BREACH (${hoursElapsed}h)`;
  } else if (isWarning) {
    label = `SLA Warning (${hoursElapsed}h)`;
  }

  return {
    hoursElapsed,
    isBreached,
    isWarning,
    label,
  };
}

/**
 * Filter moderation queue items by status and item type.
 */
export function filterModerationItems(
  items: ModerationItem[],
  statusFilter: string,
  typeFilter: string
): ModerationItem[] {
  return items.filter((item) => {
    if (statusFilter !== 'all' && item.status !== statusFilter) return false;
    if (typeFilter !== 'all' && item.type !== typeFilter) return false;
    return true;
  });
}

/**
 * Filter verification queue items by requested kind and search query.
 */
export function filterVerificationItems(
  items: VerificationQueueItem[],
  kindFilter: string,
  searchQuery: string
): VerificationQueueItem[] {
  const q = searchQuery.trim().toLowerCase();
  return items.filter((item) => {
    if (kindFilter !== 'all' && item.kind !== kindFilter) return false;
    if (q) {
      const matchName = item.user_full_name.toLowerCase().includes(q);
      const matchEmail = item.user_email.toLowerCase().includes(q);
      const matchCompany = (item.company_name || '').toLowerCase().includes(q);
      if (!matchName && !matchEmail && !matchCompany) return false;
    }
    return true;
  });
}

/**
 * Validates a moderation triage resolution submission.
 * Every action requires a non-empty audit rationale note.
 */
export function validateModerationAction(decision: string, note: string): {
  isValid: boolean;
  error?: string;
  payload?: { decision: string; note: string };
} {
  const validDecisions = ['dismiss', 'warn', 'restrict', 'suspend', 'ban'];
  if (!validDecisions.includes(decision)) {
    return {
      isValid: false,
      error: `Invalid decision '${decision}'. Must be one of: ${validDecisions.join(', ')}`,
    };
  }

  const trimmedNote = note.trim();
  if (!trimmedNote) {
    return {
      isValid: false,
      error: 'An audit note is required for all moderation decisions.',
    };
  }

  if (trimmedNote.length < 5) {
    return {
      isValid: false,
      error: 'Audit note must be at least 5 characters.',
    };
  }

  return {
    isValid: true,
    payload: {
      decision,
      note: trimmedNote,
    },
  };
}

/**
 * Validates a verification queue decision submission.
 */
export function validateVerificationAction(
  decision: 'approve' | 'reject',
  badge?: string,
  note?: string
): {
  isValid: boolean;
  error?: string;
  payload?: { decision: string; badge?: string; note?: string };
} {
  const trimmedNote = (note || '').trim();

  if (decision === 'reject') {
    if (!trimmedNote) {
      return {
        isValid: false,
        error: 'A rejection rationale note is required to inform the applicant.',
      };
    }
    return {
      isValid: true,
      payload: {
        decision: 'reject',
        note: trimmedNote,
      },
    };
  }

  if (decision === 'approve') {
    const assignedBadge = (badge || '').trim();
    return {
      isValid: true,
      payload: {
        decision: 'approve',
        badge: assignedBadge || undefined,
        note: trimmedNote || undefined,
      },
    };
  }

  return {
    isValid: false,
    error: `Unsupported decision '${decision}'. Must be 'approve' or 'reject'.`,
  };
}

export interface CsvValidationRow {
  line: number;
  fullName: string;
  email: string;
  role: string;
  batch?: string;
  department?: string;
  errors: string[];
}

/**
 * Parses and validates raw CSV roster text on the client side.
 */
export function parseAndValidateCsv(csvText: string): {
  success: boolean;
  error?: string;
  rows: CsvValidationRow[];
  validCount: number;
  invalidCount: number;
} {
  if (!csvText || !csvText.trim()) {
    return {
      success: false,
      error: 'CSV content is empty.',
      rows: [],
      validCount: 0,
      invalidCount: 0,
    };
  }

  const lines = csvText
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l.length > 0);

  if (lines.length < 2) {
    return {
      success: false,
      error: 'CSV must contain a header row and at least one data row.',
      rows: [],
      validCount: 0,
      invalidCount: 0,
    };
  }

  const headers = lines[0]
    .split(',')
    .map((h) => h.trim().toLowerCase().replace(/^["']|["']$/g, ''));
  const required = ['full_name', 'email', 'role'];
  const missing = required.filter((r) => !headers.includes(r));

  if (missing.length > 0) {
    return {
      success: false,
      error: `Missing required column headers: ${missing.join(', ')}`,
      rows: [],
      validCount: 0,
      invalidCount: 0,
    };
  }

  const nameIdx = headers.indexOf('full_name');
  const emailIdx = headers.indexOf('email');
  const roleIdx = headers.indexOf('role');
  const batchIdx = headers.indexOf('batch');
  const deptIdx = headers.indexOf('department');

  const rows: CsvValidationRow[] = [];
  let validCount = 0;
  let invalidCount = 0;

  for (let i = 1; i < lines.length; i++) {
    const parts = lines[i].split(',').map((p) => p.trim().replace(/^["']|["']$/g, ''));
    const errors: string[] = [];

    const fullName = parts[nameIdx] || '';
    const email = (parts[emailIdx] || '').toLowerCase();
    const role = (parts[roleIdx] || '').toLowerCase();
    const batch = batchIdx >= 0 ? parts[batchIdx] : undefined;
    const department = deptIdx >= 0 ? parts[deptIdx] : undefined;

    if (!fullName) {
      errors.push('Missing full_name');
    }
    if (!email || !email.includes('@') || !email.includes('.')) {
      errors.push(`Invalid email: '${email}'`);
    }
    if (!['student', 'alumnus', 'faculty'].includes(role)) {
      errors.push(`Invalid role: '${role}'. Allowed: student, alumnus, faculty`);
    }

    if (errors.length === 0) {
      validCount++;
    } else {
      invalidCount++;
    }

    rows.push({
      line: i + 1,
      fullName,
      email,
      role,
      batch,
      department,
      errors,
    });
  }

  return {
    success: true,
    rows,
    validCount,
    invalidCount,
  };
}
