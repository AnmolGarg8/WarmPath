import React, { useState, useEffect, useCallback } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  ShieldAlert,
  Flag,
  UserX,
  Clock,
  CheckCircle,
  XCircle,
  AlertTriangle,
  ChevronRight,
  X,
  History,
  Filter,
} from 'lucide-react';
import {
  fetchApi,
  ModerationItem,
  ModerationQueueResponse,
  AuditLogResponse,
} from '../../core/api';
import { useToast } from '../../core/toast';

export const ModerationPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'queue' | 'audit'>('queue');
  const [statusFilter, setStatusFilter] = useState<string>('pending');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [cursor, setCursor] = useState<string | null>(null);
  const [selectedItem, setSelectedItem] = useState<ModerationItem | null>(null);

  // Audit filters
  const [auditActionFilter, setAuditActionFilter] = useState<string>('all');
  const [auditTargetFilter, setAuditTargetFilter] = useState<string>('');

  const { showToast } = useToast();
  const queryClient = useQueryClient();

  // Fetch Moderation Queue
  const {
    data: queueData,
    isLoading: isQueueLoading,
    error: queueError,
    refetch: refetchQueue,
  } = useQuery<ModerationQueueResponse>({
    queryKey: ['moderation-queue', statusFilter, typeFilter, cursor],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (statusFilter !== 'all') params.set('status', statusFilter);
      if (typeFilter !== 'all') params.set('type', typeFilter);
      if (cursor) params.set('cursor', cursor);
      params.set('limit', '20');
      return fetchApi<ModerationQueueResponse>(`/admin/moderation/queue?${params.toString()}`);
    },
    enabled: activeTab === 'queue',
  });

  // Fetch Audit Log
  const {
    data: auditData,
    isLoading: isAuditLoading,
    error: auditError,
    refetch: refetchAudit,
  } = useQuery<AuditLogResponse>({
    queryKey: ['audit-log', auditActionFilter, auditTargetFilter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (auditActionFilter !== 'all') params.set('action', auditActionFilter);
      if (auditTargetFilter.trim()) params.set('target_id', auditTargetFilter.trim());
      params.set('limit', '30');
      return fetchApi<AuditLogResponse>(`/admin/audit-log?${params.toString()}`);
    },
    enabled: activeTab === 'audit',
  });

  // Moderation Resolution Mutation
  const resolveMutation = useMutation({
    mutationFn: async ({
      id,
      decision,
      note,
    }: {
      id: string;
      decision: string;
      note: string;
    }) => {
      return fetchApi(`/admin/moderation/${id}/resolve`, {
        method: 'POST',
        body: JSON.stringify({ decision, note }),
      });
    },
    onSuccess: (_, variables) => {
      showToast(`Item resolved with decision: "${variables.decision.toUpperCase()}"`, 'success');
      queryClient.invalidateQueries({ queryKey: ['moderation-queue'] });
      queryClient.invalidateQueries({ queryKey: ['audit-log'] });
      setSelectedItem(null);
    },
    onError: (err: any) => {
      showToast(err?.error?.message || 'Failed to resolve moderation item.', 'error');
    },
  });

  // Keyboard Shortcuts for Triage
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setSelectedItem(null);
      }
    },
    []
  );

  useEffect(() => {
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);

  const calculateSla = (createdAtString: string) => {
    const created = new Date(createdAtString);
    const now = new Date();
    const ageHours = (now.getTime() - created.getTime()) / (1000 * 60 * 60);

    if (ageHours < 12) {
      return {
        label: `${Math.round(ageHours)}h ago (On Track)`,
        color: 'bg-emerald-50 text-emerald-700 border-emerald-200',
        breached: false,
      };
    } else if (ageHours <= 24) {
      return {
        label: `${Math.round(ageHours)}h ago (Approaching SLA)`,
        color: 'bg-amber-50 text-amber-700 border-amber-200',
        breached: false,
      };
    } else {
      return {
        label: `${Math.round(ageHours)}h ago (SLA Breached)`,
        color: 'bg-rose-50 text-rose-700 border-rose-200 font-bold',
        breached: true,
      };
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Title & Navigation Tabs */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-brand-dark">Community Trust & Moderation</h1>
          <p className="text-sm text-brand-slate">
            Review user reports, automated safety filter catches, and system audit trails.
          </p>
        </div>

        <div className="flex items-center gap-2 p-1 bg-white rounded-xl border border-brand-slate/15 shadow-sm">
          <button
            onClick={() => setActiveTab('queue')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
              activeTab === 'queue'
                ? 'bg-brand-indigo text-white shadow-sm'
                : 'text-brand-slate hover:text-brand-dark'
            }`}
          >
            <ShieldAlert className="w-4 h-4" /> Queue
          </button>
          <button
            onClick={() => setActiveTab('audit')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
              activeTab === 'audit'
                ? 'bg-brand-indigo text-white shadow-sm'
                : 'text-brand-slate hover:text-brand-dark'
            }`}
          >
            <History className="w-4 h-4" /> Audit Log
          </button>
        </div>
      </div>

      {activeTab === 'queue' ? (
        <>
          {/* Filters Bar */}
          <div className="bg-white p-4 rounded-2xl border border-brand-slate/10 shadow-sm flex flex-wrap items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold uppercase tracking-wider text-brand-slate mr-2 flex items-center gap-1">
                <Filter className="w-3.5 h-3.5" /> Status:
              </span>
              {['pending', 'all', 'resolved', 'dismissed'].map((status) => (
                <button
                  key={status}
                  onClick={() => {
                    setStatusFilter(status);
                    setCursor(null);
                  }}
                  className={`px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition-colors ${
                    statusFilter === status
                      ? 'bg-brand-coral text-white shadow-sm'
                      : 'bg-brand-surface text-brand-slate hover:text-brand-dark'
                  }`}
                >
                  {status}
                </button>
              ))}
            </div>

            <div className="flex items-center gap-2">
              <span className="text-xs font-bold uppercase tracking-wider text-brand-slate mr-2">Type:</span>
              <select
                value={typeFilter}
                onChange={(e) => {
                  setTypeFilter(e.target.value);
                  setCursor(null);
                }}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-brand-surface border border-brand-slate/20 text-brand-dark focus:outline-none focus:ring-1 focus:ring-brand-coral"
              >
                <option value="all">All Item Types</option>
                <option value="report">User Reports</option>
                <option value="flagged_message">Automated Flagged Messages</option>
              </select>

              <button
                onClick={() => refetchQueue()}
                className="px-3 py-1.5 rounded-lg text-xs font-medium text-brand-slate hover:text-brand-dark bg-brand-surface border border-brand-slate/20"
              >
                Refresh
              </button>
            </div>
          </div>

          {/* Queue Table */}
          <div className="bg-white rounded-2xl border border-brand-slate/10 shadow-sm overflow-hidden">
            {isQueueLoading ? (
              <div className="p-12 text-center text-brand-slate">
                <div className="w-8 h-8 border-4 border-brand-indigo/20 border-t-brand-coral rounded-full animate-spin mx-auto mb-3" />
                <p className="text-sm font-medium">Fetching moderation queue...</p>
              </div>
            ) : queueError ? (
              <div className="p-8 text-center text-rose-600 bg-rose-50/50">
                <AlertTriangle className="w-8 h-8 mx-auto mb-2 text-rose-500" />
                <p className="text-sm font-semibold">Failed to load moderation queue.</p>
                <button
                  onClick={() => refetchQueue()}
                  className="mt-3 px-4 py-2 bg-white text-xs font-semibold rounded-lg border border-rose-200 text-rose-700 hover:bg-rose-50"
                >
                  Retry
                </button>
              </div>
            ) : !queueData?.items?.length ? (
              <div className="p-12 text-center text-brand-slate">
                <CheckCircle className="w-10 h-10 mx-auto mb-3 text-emerald-500" />
                <p className="text-base font-bold text-brand-dark">Queue is All Clear!</p>
                <p className="text-xs text-brand-slate mt-1">
                  No moderation items match the current filter criteria.
                </p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse text-sm">
                  <thead>
                    <tr className="bg-brand-surface/60 border-b border-brand-slate/10 text-brand-slate text-xs uppercase tracking-wider font-semibold">
                      <th className="py-3.5 px-4">Type</th>
                      <th className="py-3.5 px-4">Subject & Reason</th>
                      <th className="py-3.5 px-4">Severity</th>
                      <th className="py-3.5 px-4">Status</th>
                      <th className="py-3.5 px-4">Pilot SLA (24h)</th>
                      <th className="py-3.5 px-4 text-right">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-brand-slate/10">
                    {queueData.items.map((item) => {
                      const sla = calculateSla(item.created_at);
                      const isReport = item.type === 'report';

                      return (
                        <tr
                          key={item.id}
                          className="hover:bg-brand-surface/30 transition-colors cursor-pointer"
                          onClick={() => setSelectedItem(item)}
                        >
                          <td className="py-3.5 px-4">
                            <div className="flex items-center gap-2">
                              {isReport ? (
                                <span className="p-2 rounded-lg bg-indigo-50 text-brand-indigo">
                                  <Flag className="w-4 h-4" />
                                </span>
                              ) : (
                                <span className="p-2 rounded-lg bg-amber-50 text-amber-700">
                                  <ShieldAlert className="w-4 h-4" />
                                </span>
                              )}
                              <span className="font-semibold text-xs text-brand-dark capitalize">
                                {item.type.replace('_', ' ')}
                              </span>
                            </div>
                          </td>
                          <td className="py-3.5 px-4 max-w-xs">
                            <p className="font-semibold text-brand-dark truncate">{item.reason}</p>
                            <p className="text-xs text-brand-slate truncate">
                              {item.details || 'No additional details provided'}
                            </p>
                          </td>
                          <td className="py-3.5 px-4">
                            <span
                              className={`px-2.5 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${
                                item.severity === 'high'
                                  ? 'bg-rose-50 text-rose-700 border border-rose-200'
                                  : 'bg-amber-50 text-amber-700 border border-amber-200'
                              }`}
                            >
                              {item.severity}
                            </span>
                          </td>
                          <td className="py-3.5 px-4">
                            <span
                              className={`px-2.5 py-1 rounded-full text-xs font-semibold capitalize ${
                                item.status === 'pending'
                                  ? 'bg-amber-50 text-amber-700'
                                  : item.status === 'resolved'
                                  ? 'bg-emerald-50 text-emerald-700'
                                  : 'bg-slate-100 text-slate-700'
                              }`}
                            >
                              {item.status}
                            </span>
                          </td>
                          <td className="py-3.5 px-4">
                            <div className="flex items-center gap-1.5">
                              <Clock className="w-3.5 h-3.5 text-brand-slate" />
                              <span
                                className={`px-2 py-0.5 rounded text-xs border ${sla.color}`}
                              >
                                {sla.label}
                              </span>
                            </div>
                          </td>
                          <td className="py-3.5 px-4 text-right">
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setSelectedItem(item);
                              }}
                              className="px-3 py-1.5 rounded-lg bg-brand-surface hover:bg-brand-indigo hover:text-white text-brand-dark text-xs font-bold transition-colors inline-flex items-center gap-1"
                            >
                              Review <ChevronRight className="w-3.5 h-3.5" />
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      ) : (
        /* Audit Log Section */
        <div className="space-y-4">
          <div className="bg-white p-4 rounded-2xl border border-brand-slate/10 shadow-sm flex flex-wrap items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold uppercase tracking-wider text-brand-slate">Action:</span>
              <select
                value={auditActionFilter}
                onChange={(e) => setAuditActionFilter(e.target.value)}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-brand-surface border border-brand-slate/20 text-brand-dark focus:outline-none"
              >
                <option value="all">All Actions</option>
                <option value="moderation.resolve">Moderation Resolutions</option>
                <option value="verification.decide">Verification Decisions</option>
                <option value="approved_members.upload">Approved Roster Uploads</option>
                <option value="user.auto_restricted">Automated User Restrictions</option>
              </select>
            </div>

            <div className="flex items-center gap-2">
              <input
                type="text"
                placeholder="Filter by Target ID..."
                value={auditTargetFilter}
                onChange={(e) => setAuditTargetFilter(e.target.value)}
                className="px-3 py-1.5 rounded-lg text-xs bg-brand-surface border border-brand-slate/20 text-brand-dark focus:outline-none"
              />
              <button
                onClick={() => refetchAudit()}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-brand-indigo text-white hover:bg-brand-indigo/90"
              >
                Filter
              </button>
            </div>
          </div>

          <div className="bg-white rounded-2xl border border-brand-slate/10 shadow-sm overflow-hidden">
            {isAuditLoading ? (
              <div className="p-12 text-center text-brand-slate">
                <div className="w-8 h-8 border-4 border-brand-indigo/20 border-t-brand-coral rounded-full animate-spin mx-auto mb-3" />
                <p className="text-sm font-medium">Loading immutable audit logs...</p>
              </div>
            ) : auditError ? (
              <div className="p-8 text-center text-rose-600">Failed to load audit logs.</div>
            ) : !auditData?.items?.length ? (
              <div className="p-12 text-center text-brand-slate">No audit records found.</div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse text-sm">
                  <thead>
                    <tr className="bg-brand-surface/60 border-b border-brand-slate/10 text-brand-slate text-xs uppercase tracking-wider font-semibold">
                      <th className="py-3 px-4">Timestamp</th>
                      <th className="py-3 px-4">Actor</th>
                      <th className="py-3 px-4">Action</th>
                      <th className="py-3 px-4">Target</th>
                      <th className="py-3 px-4">Details</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-brand-slate/10 font-mono text-xs">
                    {auditData.items.map((log) => (
                      <tr key={log.id} className="hover:bg-brand-surface/20">
                        <td className="py-3 px-4 whitespace-nowrap text-brand-slate">
                          {new Date(log.created_at).toLocaleString()}
                        </td>
                        <td className="py-3 px-4 font-semibold text-brand-dark">{log.actor_email}</td>
                        <td className="py-3 px-4">
                          <span className="px-2 py-0.5 rounded bg-brand-surface text-brand-indigo font-bold border border-brand-slate/15">
                            {log.action}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-brand-slate">
                          {log.target_type}: {log.target_id}
                        </td>
                        <td className="py-3 px-4 max-w-sm truncate text-brand-slate font-sans">
                          {JSON.stringify(log.details)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Moderation Review Detail Drawer */}
      {selectedItem && (
        <ModerationDetailDrawer
          item={selectedItem}
          onClose={() => setSelectedItem(null)}
          onResolve={(decision, note) => {
            resolveMutation.mutate({
              id: selectedItem.id,
              decision,
              note,
            });
          }}
          isSubmitting={resolveMutation.isPending}
        />
      )}
    </div>
  );
};

interface DetailDrawerProps {
  item: ModerationItem;
  onClose: () => void;
  onResolve: (decision: string, note: string) => void;
  isSubmitting: boolean;
}

const ModerationDetailDrawer: React.FC<DetailDrawerProps> = ({
  item,
  onClose,
  onResolve,
  isSubmitting,
}) => {
  const [decision, setDecision] = useState<string>('warn');
  const [note, setNote] = useState<string>('');
  const [noteError, setNoteError] = useState<string | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!note.trim() || note.trim().length < 5) {
      setNoteError('Please provide an actionable resolution note (min 5 characters).');
      return;
    }
    setNoteError(null);
    onResolve(decision, note.trim());
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden bg-black/40 backdrop-blur-xs flex justify-end animate-in fade-in">
      <div className="w-full max-w-lg bg-white h-full shadow-2xl flex flex-col justify-between border-l border-brand-slate/15 overflow-y-auto">
        <div>
          {/* Drawer Header */}
          <div className="p-6 border-b border-brand-slate/10 flex items-center justify-between bg-brand-surface/40">
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold uppercase tracking-wider text-brand-coral">
                  {item.type.replace('_', ' ')}
                </span>
                <span className="text-xs text-brand-slate">#{item.id.slice(0, 8)}</span>
              </div>
              <h2 className="text-lg font-bold text-brand-dark mt-1">{item.reason}</h2>
            </div>
            <button
              onClick={onClose}
              className="p-2 text-brand-slate hover:text-brand-dark hover:bg-white rounded-lg transition-colors"
              title="Close (Esc)"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Drawer Content */}
          <div className="p-6 space-y-6">
            {/* Content snippet */}
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-brand-slate mb-2">
                Reported Content / Flagged Message
              </label>
              <div className="p-4 rounded-xl bg-brand-surface/80 border border-brand-slate/15 text-sm text-brand-dark whitespace-pre-wrap font-sans">
                {item.details || 'No textual content attached.'}
              </div>
            </div>

            {/* Target and Reporter Context */}
            <div className="grid grid-cols-2 gap-4">
              <div className="p-3.5 rounded-xl border border-brand-slate/10 bg-white">
                <p className="text-xs font-bold text-brand-slate uppercase">Reporter</p>
                <p className="text-sm font-semibold text-brand-dark mt-1">
                  {item.reporter_id ? `User #${item.reporter_id.slice(0, 8)}` : 'Automated Safety Engine'}
                </p>
              </div>

              <div className="p-3.5 rounded-xl border border-brand-slate/10 bg-white">
                <p className="text-xs font-bold text-brand-slate uppercase">Target Subject</p>
                <p className="text-sm font-semibold text-brand-dark mt-1">
                  {item.target_user_id ? `User #${item.target_user_id.slice(0, 8)}` : 'System Entity'}
                </p>
                <p className="text-[11px] text-brand-teal font-medium mt-0.5">
                  Trust Profile: Active Member
                </p>
              </div>
            </div>

            {/* Triage Decision Form */}
            <form onSubmit={handleSubmit} className="space-y-4 pt-4 border-t border-brand-slate/10">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-brand-slate mb-2">
                  Resolution Decision *
                </label>
                <div className="grid grid-cols-2 gap-2 text-xs font-semibold">
                  {[
                    { id: 'dismiss', label: 'Dismiss Report', desc: 'No violation found' },
                    { id: 'warn', label: 'Issue Warning', desc: 'Notify user of violation' },
                    { id: 'restrict', label: 'Restrict Account', desc: 'Cap daily quota to 1' },
                    { id: 'suspend', label: 'Suspend Access', desc: 'Temporary account freeze' },
                    { id: 'ban', label: 'Permanent Ban', desc: 'Delete and blacklist' },
                  ].map((act) => (
                    <label
                      key={act.id}
                      className={`p-3 rounded-xl border cursor-pointer transition-all ${
                        decision === act.id
                          ? 'bg-brand-indigo/5 border-brand-indigo text-brand-indigo shadow-xs'
                          : 'bg-white border-brand-slate/20 text-brand-slate hover:bg-brand-surface/40'
                      }`}
                    >
                      <input
                        type="radio"
                        name="decision"
                        value={act.id}
                        checked={decision === act.id}
                        onChange={() => setDecision(act.id)}
                        className="sr-only"
                      />
                      <p className="font-bold text-brand-dark">{act.label}</p>
                      <p className="text-[10px] text-brand-slate mt-0.5">{act.desc}</p>
                    </label>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-brand-slate mb-2">
                  Resolution Note (Required for Audit Trail) *
                </label>
                <textarea
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  rows={3}
                  placeholder="Detail the rationale, violation rule, or communication sent to user..."
                  className="w-full p-3 rounded-xl border border-brand-slate/20 text-sm focus:outline-none focus:ring-2 focus:ring-brand-coral bg-brand-surface/30 text-brand-dark"
                  required
                />
                {noteError && <p className="text-xs text-rose-600 mt-1">{noteError}</p>}
              </div>

              <div className="pt-2 flex items-center gap-3">
                <button
                  type="button"
                  onClick={onClose}
                  className="flex-1 py-2.5 px-4 rounded-xl border border-brand-slate/20 text-brand-slate font-semibold text-xs hover:bg-brand-surface transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="flex-1 py-2.5 px-4 rounded-xl bg-brand-coral hover:bg-brand-coral/90 text-white font-bold text-xs transition-colors disabled:opacity-50"
                >
                  {isSubmitting ? 'Resolving...' : 'Confirm Resolution'}
                </button>
              </div>
            </form>
          </div>
        </div>

        {/* Drawer Footer with triage shortcuts */}
        <div className="p-4 bg-brand-surface/50 border-t border-brand-slate/10 text-xs text-brand-slate flex items-center justify-between">
          <span>Shortcuts: <kbd className="px-1.5 py-0.5 bg-white border rounded">Esc</kbd> Close</span>
          <span className="text-[11px]">All resolutions are immutably logged</span>
        </div>
      </div>
    </div>
  );
};
