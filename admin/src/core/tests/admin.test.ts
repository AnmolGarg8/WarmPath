import { describe, it } from 'node:test';
import assert from 'node:assert';
import { checkUserAccess, ALLOWED_ADMIN_ROLES } from '../auth';
import {
  calculateSlaStatus,
  filterModerationItems,
  filterVerificationItems,
  validateModerationAction,
  validateVerificationAction,
  parseAndValidateCsv,
} from '../admin_helpers';
import { User, ModerationItem, VerificationQueueItem } from '../api';

describe('WarmPath Admin Core & Moderation Test Suite', () => {
  // ==========================================
  // 1. Role Gating Tests
  // ==========================================
  describe('Role Gating (checkUserAccess)', () => {
    it('grants access to platform_admin', () => {
      const user: User = {
        id: 'u-1',
        email: 'super@warmpath.internal',
        full_name: 'Platform Admin',
        roles: ['platform_admin'],
        verification_level: 'verified',
        trust_level: 'established',
        status: 'active',
      };
      assert.strictEqual(checkUserAccess(user), true);
    });

    it('grants access to institution_admin', () => {
      const user: User = {
        id: 'u-2',
        email: 'admin@vips.edu',
        full_name: 'College Dean',
        roles: ['institution_admin', 'faculty'],
        institution_id: 1,
        verification_level: 'verified',
        trust_level: 'established',
        status: 'active',
      };
      assert.strictEqual(checkUserAccess(user), true);
    });

    it('grants access to moderator', () => {
      const user: User = {
        id: 'u-3',
        email: 'mod@vips.edu',
        full_name: 'Safety Moderator',
        roles: ['moderator'],
        verification_level: 'verified',
        trust_level: 'verified',
        status: 'active',
      };
      assert.strictEqual(checkUserAccess(user), true);
    });

    it('grants access to dual student/moderator role', () => {
      const user: User = {
        id: 'u-4',
        email: 'lead.student@vips.edu',
        full_name: 'Peer Moderator',
        roles: ['student', 'moderator'],
        verification_level: 'verified',
        trust_level: 'verified',
        status: 'active',
      };
      assert.strictEqual(checkUserAccess(user), true);
    });

    it('denies access to normal student or alumnus accounts', () => {
      const student: User = {
        id: 'u-5',
        email: 'student@vips.edu',
        full_name: 'Regular Student',
        roles: ['student'],
        verification_level: 'verified',
        trust_level: 'new',
        status: 'active',
      };
      const alumnus: User = {
        id: 'u-6',
        email: 'alum@gmail.com',
        full_name: 'Senior Alumnus',
        roles: ['alumnus'],
        verification_level: 'verified',
        trust_level: 'established',
        status: 'active',
      };
      assert.strictEqual(checkUserAccess(student), false);
      assert.strictEqual(checkUserAccess(alumnus), false);
    });

    it('denies access to null or empty role arrays', () => {
      assert.strictEqual(checkUserAccess(null), false);
      const emptyUser = {
        id: 'u-7',
        email: 'nobody@nowhere.com',
        full_name: 'Empty',
        roles: [],
        verification_level: 'email_only',
        trust_level: 'new',
        status: 'active',
      };
      assert.strictEqual(checkUserAccess(emptyUser), false);
    });

    it('has exact allowed admin roles', () => {
      assert.deepStrictEqual([...ALLOWED_ADMIN_ROLES], [
        'moderator',
        'institution_admin',
        'platform_admin',
      ]);
    });
  });

  // ==========================================
  // 2. Queue Filters & SLA Tests
  // ==========================================
  describe('Queue Filters & SLA Monitoring', () => {
    const mockItems: ModerationItem[] = [
      {
        id: 'item-1',
        type: 'report',
        status: 'pending',
        severity: 'high',
        reporter_id: 'r1',
        target_user_id: 't1',
        reason: 'scam',
        details: 'Fee demanded',
        created_at: new Date(Date.now() - 3600 * 1000 * 2).toISOString(), // 2h ago
      },
      {
        id: 'item-2',
        type: 'flagged_message',
        status: 'pending',
        severity: 'medium',
        reporter_id: null,
        target_user_id: 't2',
        reason: 'Safety Flagged: whatsapp_offsite',
        details: 'Contact me on wa.me',
        created_at: new Date(Date.now() - 3600 * 1000 * 20).toISOString(), // 20h ago (warning)
      },
      {
        id: 'item-3',
        type: 'report',
        status: 'resolved',
        severity: 'low',
        reporter_id: 'r3',
        target_user_id: 't3',
        reason: 'spam',
        details: 'Duplicate outreach',
        created_at: new Date(Date.now() - 3600 * 1000 * 30).toISOString(), // 30h ago (breached)
      },
    ];

    it('filters moderation queue by status', () => {
      const pending = filterModerationItems(mockItems, 'pending', 'all');
      assert.strictEqual(pending.length, 2);
      assert.strictEqual(pending[0].id, 'item-1');
      assert.strictEqual(pending[1].id, 'item-2');

      const resolved = filterModerationItems(mockItems, 'resolved', 'all');
      assert.strictEqual(resolved.length, 1);
      assert.strictEqual(resolved[0].id, 'item-3');
    });

    it('filters moderation queue by type', () => {
      const flagged = filterModerationItems(mockItems, 'all', 'flagged_message');
      assert.strictEqual(flagged.length, 1);
      assert.strictEqual(flagged[0].id, 'item-2');

      const reports = filterModerationItems(mockItems, 'all', 'report');
      assert.strictEqual(reports.length, 2);
    });

    it('computes 24-hour SLA targets and flags breaches', () => {
      // Recent (2h)
      const recent = calculateSlaStatus(new Date(Date.now() - 3600 * 1000 * 2));
      assert.strictEqual(recent.hoursElapsed, 2);
      assert.strictEqual(recent.isBreached, false);
      assert.strictEqual(recent.isWarning, false);

      // Warning (20h)
      const warning = calculateSlaStatus(new Date(Date.now() - 3600 * 1000 * 20));
      assert.strictEqual(warning.hoursElapsed, 20);
      assert.strictEqual(warning.isWarning, true);
      assert.strictEqual(warning.isBreached, false);

      // Breached (26h)
      const breach = calculateSlaStatus(new Date(Date.now() - 3600 * 1000 * 26));
      assert.strictEqual(breach.hoursElapsed, 26);
      assert.strictEqual(breach.isBreached, true);
      assert.match(breach.label, /SLA BREACH/);
    });

    it('filters verification items by role kind and search term', () => {
      const verificationItems: VerificationQueueItem[] = [
        {
          id: 'v1',
          user_id: 'u1',
          user_email: 'alum@google.com',
          user_full_name: 'Anita Sharma',
          kind: 'alumnus',
          evidence_text: 'Graduated Batch 2021',
          evidence_urls: ['https://linkedin.com/in/anita'],
          status: 'pending',
          created_at: new Date().toISOString(),
        },
        {
          id: 'v2',
          user_id: 'u2',
          user_email: 'recruiter@techcorp.in',
          user_full_name: 'Rajesh Verma',
          kind: 'employer',
          evidence_text: 'Campus hiring manager',
          evidence_urls: [],
          company_name: 'TechCorp India Ltd',
          company_registration: 'U72900DL2020PTC123456',
          status: 'pending',
          created_at: new Date().toISOString(),
        },
      ];

      // Filter kind
      const alumniOnly = filterVerificationItems(verificationItems, 'alumnus', '');
      assert.strictEqual(alumniOnly.length, 1);
      assert.strictEqual(alumniOnly[0].kind, 'alumnus');

      // Search by company
      const searchCompany = filterVerificationItems(verificationItems, 'all', 'TechCorp');
      assert.strictEqual(searchCompany.length, 1);
      assert.strictEqual(searchCompany[0].company_name, 'TechCorp India Ltd');

      // Search by email
      const searchEmail = filterVerificationItems(verificationItems, 'all', 'alum@google');
      assert.strictEqual(searchEmail.length, 1);
      assert.strictEqual(searchEmail[0].user_full_name, 'Anita Sharma');
    });
  });

  // ==========================================
  // 3. Action Forms & Validation Tests
  // ==========================================
  describe('Action Forms & Validation', () => {
    it('validates moderation triage actions with required note', () => {
      // Valid action
      const valid = validateModerationAction('warn', 'User warned for posting external link');
      assert.strictEqual(valid.isValid, true);
      assert.strictEqual(valid.payload?.decision, 'warn');
      assert.strictEqual(valid.payload?.note, 'User warned for posting external link');

      // Empty note rejected
      const emptyNote = validateModerationAction('restrict', '   ');
      assert.strictEqual(emptyNote.isValid, false);
      assert.match(emptyNote.error || '', /required/i);

      // Invalid decision rejected
      const invalidDecision = validateModerationAction('forgive', 'Valid note here');
      assert.strictEqual(invalidDecision.isValid, false);
      assert.match(invalidDecision.error || '', /invalid decision/i);
    });

    it('validates verification approval and rejection actions', () => {
      // Approve with badge
      const approved = validateVerificationAction('approve', 'Verified Alumnus', 'Degree verified');
      assert.strictEqual(approved.isValid, true);
      assert.strictEqual(approved.payload?.decision, 'approve');
      assert.strictEqual(approved.payload?.badge, 'Verified Alumnus');

      // Reject requires explanation note
      const rejectWithoutNote = validateVerificationAction('reject', undefined, '');
      assert.strictEqual(rejectWithoutNote.isValid, false);
      assert.match(rejectWithoutNote.error || '', /rejection rationale note is required/i);

      const rejectWithNote = validateVerificationAction('reject', undefined, 'CIN registration number not found on MCA portal.');
      assert.strictEqual(rejectWithNote.isValid, true);
      assert.strictEqual(rejectWithNote.payload?.decision, 'reject');
      assert.strictEqual(rejectWithNote.payload?.note, 'CIN registration number not found on MCA portal.');
    });

    it('parses and validates approved members CSV roster', () => {
      const validCsv = `full_name,email,role,batch,department
Rohan Mehta,rohan@vips.edu,student,2025,Computer Science
Dr. Sunita Rao,s.rao@vips.edu,faculty,2018,Information Technology
Karan Gill,karan.alumni@vips.edu,alumnus,2021,BCA`;

      const parsed = parseAndValidateCsv(validCsv);
      assert.strictEqual(parsed.success, true);
      assert.strictEqual(parsed.rows.length, 3);
      assert.strictEqual(parsed.validCount, 3);
      assert.strictEqual(parsed.invalidCount, 0);

      // Test validation errors on bad CSV
      const badCsv = `full_name,email,role
Invalid Email User,not-an-email,student
Bad Role User,badrole@vips.edu,mentor
Valid User,valid@vips.edu,faculty`;

      const parsedBad = parseAndValidateCsv(badCsv);
      assert.strictEqual(parsedBad.success, true);
      assert.strictEqual(parsedBad.rows.length, 3);
      assert.strictEqual(parsedBad.validCount, 1);
      assert.strictEqual(parsedBad.invalidCount, 2);

      // Check specific error messages
      assert.match(parsedBad.rows[0].errors[0], /invalid email/i);
      assert.match(parsedBad.rows[1].errors[0], /invalid role/i);
      assert.strictEqual(parsedBad.rows[2].errors.length, 0);
    });

    it('rejects CSV missing required columns', () => {
      const missingHeadersCsv = `name,contact
Rohan,9999999999`;
      const res = parseAndValidateCsv(missingHeadersCsv);
      assert.strictEqual(res.success, false);
      assert.match(res.error || '', /missing required column headers/i);
    });
  });
});
