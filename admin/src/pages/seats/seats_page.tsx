import React, { useState, useEffect, useCallback } from 'react';
import {
  Award,
  Wallet,
  HeartHandshake,
  CheckCircle2,
  AlertTriangle,
  RefreshCw,
  PlusCircle,
  Building,
} from 'lucide-react';
import { fetchApi } from '../../core/api';

interface SeatGrantItem {
  id: string;
  student_email_masked: string;
  plan_code: string;
  funding_source: string;
  granted_at: string;
}

interface SeatsData {
  sponsored_seats_granted: number;
  total_budget_inr: number;
  remaining_budget_inr: number;
  scholarship_pool_balance: number;
  donations_count: number;
  donations_amount_inr: number;
  recent_grants: SeatGrantItem[];
}

export const SeatsPage: React.FC = () => {
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [seatsData, setSeatsData] = useState<SeatsData | null>(null);

  // Form states
  const [studentEmail, setStudentEmail] = useState<string>('');
  const [planCode, setPlanCode] = useState<string>('standard');
  const [fundingSource, setFundingSource] = useState<string>('Institution Budget');
  const [granting, setGranting] = useState<boolean>(false);
  const [grantSuccessMsg, setGrantSuccessMsg] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);

  const loadSeatsData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await fetchApi<SeatsData>('/admin/dashboard/seats');
      setSeatsData(data);
    } catch (err: any) {
      setError(err?.message || 'Failed to load sponsored seats and budget metrics.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadSeatsData();
  }, [loadSeatsData]);

  const handleGrantSeat = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!studentEmail || !studentEmail.includes('@')) {
      setFormError('Please enter a valid student email address.');
      return;
    }

    setGranting(true);
    setFormError(null);
    setGrantSuccessMsg(null);

    try {
      const res = await fetchApi<{
        success: boolean;
        student_email_masked: string;
        plan_code: string;
        funding_source: string;
        remaining_budget_inr: number;
      }>('/admin/dashboard/seats/grant', {
        method: 'POST',
        body: JSON.stringify({
          student_email: studentEmail.trim().toLowerCase(),
          plan_code: planCode,
          funding_source: fundingSource,
        }),
      });

      if (res && res.success) {
        setGrantSuccessMsg(
          `Successfully granted ${res.plan_code.toUpperCase()} seat to ${res.student_email_masked} funded by ${res.funding_source}. Remaining Budget: ₹${res.remaining_budget_inr}`
        );
        setStudentEmail('');
        await loadSeatsData();
      }
    } catch (err: any) {
      setFormError(err?.message || err?.error?.message || 'Failed to grant sponsored seat. Check remaining balance.');
    } finally {
      setGranting(false);
    }
  };

  return (
    <div className="space-y-8 pb-12">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-brand-dark tracking-tight">Sponsored Seats & Grants</h1>
          <p className="text-brand-slate text-sm mt-1">
            Subsidize underprivileged students, manage CSR grants, and track the scholarship pool.
          </p>
        </div>

        <button
          onClick={loadSeatsData}
          disabled={loading}
          className="self-start md:self-auto inline-flex items-center gap-2 px-3.5 py-2 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition shadow-sm text-xs font-semibold text-slate-700"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin text-brand-coral' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-2xl p-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <AlertTriangle className="w-5 h-5 text-red-600 flex-shrink-0" />
            <p className="text-sm font-medium text-red-800">{error}</p>
          </div>
          <button
            onClick={loadSeatsData}
            className="px-3 py-1 bg-red-600 text-white rounded-lg text-xs font-semibold hover:bg-red-700 transition"
          >
            Retry
          </button>
        </div>
      )}

      {/* Top Cards: Financial & Usage Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {/* Allocated Budget */}
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
          <div className="flex items-center justify-between text-brand-slate text-xs font-semibold uppercase tracking-wider">
            <span>Total Budget</span>
            <span className="p-2 rounded-xl bg-indigo-50 text-brand-indigo">
              <Building className="w-4 h-4" />
            </span>
          </div>
          <div className="mt-3">
            <span className="text-3xl font-extrabold text-brand-dark">
              ₹{seatsData ? seatsData.total_budget_inr.toLocaleString() : '50,000'}
            </span>
          </div>
          <div className="mt-2 text-xs text-slate-500">Annual institutional subsidy</div>
        </div>

        {/* Remaining Budget */}
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
          <div className="flex items-center justify-between text-brand-slate text-xs font-semibold uppercase tracking-wider">
            <span>Remaining Budget</span>
            <span className="p-2 rounded-xl bg-teal-50 text-brand-teal">
              <Wallet className="w-4 h-4" />
            </span>
          </div>
          <div className="mt-3">
            <span className="text-3xl font-extrabold text-brand-teal">
              ₹{seatsData ? seatsData.remaining_budget_inr.toLocaleString() : '50,000'}
            </span>
          </div>
          <div className="mt-2 text-xs text-slate-500">Available for student grants</div>
        </div>

        {/* Scholarship Pool Balance */}
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
          <div className="flex items-center justify-between text-brand-slate text-xs font-semibold uppercase tracking-wider">
            <span>Scholarship Pool</span>
            <span className="p-2 rounded-xl bg-coral-50 text-brand-coral bg-orange-50">
              <HeartHandshake className="w-4 h-4 text-brand-coral" />
            </span>
          </div>
          <div className="mt-3">
            <span className="text-3xl font-extrabold text-brand-coral">
              ₹{seatsData ? seatsData.scholarship_pool_balance.toLocaleString() : '15,000'}
            </span>
          </div>
          <div className="mt-2 text-xs text-slate-500">
            {seatsData ? seatsData.donations_count : 0} alumni donations received
          </div>
        </div>

        {/* Granted Seats Count */}
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
          <div className="flex items-center justify-between text-brand-slate text-xs font-semibold uppercase tracking-wider">
            <span>Seats Granted</span>
            <span className="p-2 rounded-xl bg-purple-50 text-purple-600">
              <Award className="w-4 h-4" />
            </span>
          </div>
          <div className="mt-3">
            <span className="text-3xl font-extrabold text-brand-dark">
              {seatsData ? seatsData.sponsored_seats_granted : 0}
            </span>
            <span className="text-xs text-slate-500 ml-1">students</span>
          </div>
          <div className="mt-2 text-xs text-slate-500">100% active utilization</div>
        </div>
      </div>

      {/* Grant Form & History Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Form: Grant a Sponsored Seat */}
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm space-y-6">
          <div className="flex items-center gap-2.5">
            <span className="p-2 rounded-xl bg-coral-50 text-brand-coral bg-orange-50">
              <PlusCircle className="w-5 h-5 text-brand-coral" />
            </span>
            <div>
              <h3 className="text-base font-bold text-brand-dark">Grant Sponsored Seat</h3>
              <p className="text-xs text-slate-500">Subsidize a verified student mentorship plan</p>
            </div>
          </div>

          {grantSuccessMsg && (
            <div className="p-3 bg-teal-50 border border-teal-200 rounded-xl text-xs text-teal-800 flex items-start gap-2">
              <CheckCircle2 className="w-4 h-4 text-teal-600 flex-shrink-0 mt-0.5" />
              <span>{grantSuccessMsg}</span>
            </div>
          )}

          {formError && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-xl text-xs text-red-700 flex items-start gap-2">
              <AlertTriangle className="w-4 h-4 text-red-600 flex-shrink-0 mt-0.5" />
              <span>{formError}</span>
            </div>
          )}

          <form onSubmit={handleGrantSeat} className="space-y-4 text-xs">
            <div>
              <label className="block font-semibold text-slate-700 mb-1">Student College Email</label>
              <input
                type="email"
                required
                placeholder="e.g. rahul.sharma@vipstc.edu.in"
                value={studentEmail}
                onChange={(e) => setStudentEmail(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-brand-coral/20 focus:border-brand-coral transition text-slate-800"
              />
              <span className="text-[11px] text-slate-400 mt-1 block">
                Must be an enrolled student with an institutional domain.
              </span>
            </div>

            <div>
              <label className="block font-semibold text-slate-700 mb-1">Plan Tier</label>
              <select
                value={planCode}
                onChange={(e) => setPlanCode(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-brand-coral/20 focus:border-brand-coral transition text-slate-800 font-medium"
              >
                <option value="standard">Standard Plan — 1 Credit/mo (₹299)</option>
                <option value="high">High Plan — 2 Credits/mo (₹499)</option>
                <option value="premium">Premium Plan — 4 Credits/mo (₹899)</option>
              </select>
            </div>

            <div>
              <label className="block font-semibold text-slate-700 mb-1">Funding Source</label>
              <select
                value={fundingSource}
                onChange={(e) => setFundingSource(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-brand-coral/20 focus:border-brand-coral transition text-slate-800 font-medium"
              >
                <option value="Institution Budget">Institution Budget (Annual Subsidy)</option>
                <option value="Scholarship Pool">Scholarship Pool (Alumni Donations)</option>
                <option value="Corporate CSR">Corporate CSR Grant Partner</option>
              </select>
            </div>

            <button
              type="submit"
              disabled={granting}
              className="w-full py-2.5 px-4 bg-brand-coral text-white font-bold rounded-xl hover:bg-orange-600 transition shadow-sm flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {granting ? (
                <>
                  <RefreshCw className="w-4 h-4 animate-spin" />
                  Processing Grant...
                </>
              ) : (
                'Grant Mentorship Seat'
              )}
            </button>
          </form>
        </div>

        {/* History Table: Recent Grants */}
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-base font-bold text-brand-dark">Sponsored Seat Allocation History</h3>
              <p className="text-xs text-slate-500">
                Audited student grant allocations with privacy-preserving email masking.
              </p>
            </div>
            <span className="text-xs font-semibold text-slate-500 bg-slate-100 px-2.5 py-1 rounded-lg">
              {seatsData?.recent_grants.length || 0} Records
            </span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-slate-200 text-slate-500 uppercase tracking-wider font-semibold">
                  <th className="py-3 px-4">Student (Masked)</th>
                  <th className="py-3 px-4">Plan Tier</th>
                  <th className="py-3 px-4">Funding Source</th>
                  <th className="py-3 px-4">Date Granted</th>
                  <th className="py-3 px-4 text-center">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {seatsData && seatsData.recent_grants.length > 0 ? (
                  seatsData.recent_grants.map((grant) => (
                    <tr key={grant.id} className="hover:bg-slate-50/60 transition">
                      <td className="py-3 px-4 font-semibold text-brand-dark">{grant.student_email_masked}</td>
                      <td className="py-3 px-4">
                        <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-indigo-50 text-indigo-700 capitalize">
                          {grant.plan_code}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-slate-600">{grant.funding_source}</td>
                      <td className="py-3 px-4 text-slate-500">
                        {new Date(grant.granted_at).toLocaleDateString()}
                      </td>
                      <td className="py-3 px-4 text-center">
                        <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-teal-50 text-brand-teal">
                          Active
                        </span>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={5} className="py-12 text-center text-slate-400">
                      No sponsored seats granted yet. Use the form on the left to allocate seats.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};
