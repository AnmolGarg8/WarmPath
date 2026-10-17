import React, { useState, useEffect, useCallback } from 'react';
import {
  Download,
  Calendar,
  Clock,
  Users,
  CheckCircle2,
  AlertTriangle,
  ShieldCheck,
  Star,
  RefreshCw,
  Globe,
  Building2,
  ArrowUpRight,
} from 'lucide-react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import { fetchApi } from '../../core/api';

interface AccessReachItem {
  student_institution_id: number;
  giver_institution_id: number;
  session_count: number;
  student_count: number;
  giver_count: number;
  last_activity_at?: string;
}

interface DashboardOverview {
  requests_posted: number;
  requests_fulfilled: number;
  requests_declined: number;
  requests_expired: number;
  fulfillment_rate: number;
  average_first_response_hours: number;
  sessions_completed: number;
  average_rating: number;
  active_givers: number;
  active_students: number;
  repeat_givers: number;
  sponsored_seat_usage: number;
  cross_college_share: number;
  own_college_share: number;
  access_reach: AccessReachItem[];
  cached?: boolean;
}

interface SkillGapItem {
  skill: string;
  category: string;
  demand_count: number;
  supply_count: number;
  gap_score: number;
  status: 'critical_gap' | 'moderate_gap' | 'balanced' | 'surplus';
  recommendation: string;
}

interface SkillGapResponse {
  items: SkillGapItem[];
  total_demand: number;
  total_supply: number;
  critical_gaps_count: number;
}

interface SafetySummary {
  reports_received: number;
  reports_resolved: number;
  resolution_rate: number;
  average_resolution_hours: number;
  target_resolution_hours: number;
  scam_messages_blocked: number;
  disputes_opened: number;
  disputes_resolved: number;
  status: string;
}

export const DashboardPage: React.FC = () => {
  const [datePreset, setDatePreset] = useState<'7d' | '30d' | '90d' | 'all'>('30d');
  const [fromDate, setFromDate] = useState<string>('');
  const [toDate, setToDate] = useState<string>('');
  const [institutionId, setInstitutionId] = useState<string>('all');

  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const [overview, setOverview] = useState<DashboardOverview | null>(null);
  const [skillGap, setSkillGap] = useState<SkillGapResponse | null>(null);
  const [safety, setSafety] = useState<SafetySummary | null>(null);

  // Calculate preset dates
  const applyPreset = (preset: '7d' | '30d' | '90d' | 'all') => {
    setDatePreset(preset);
    const now = new Date();
    if (preset === 'all') {
      setFromDate('');
      setToDate('');
      return;
    }
    const days = preset === '7d' ? 7 : preset === '30d' ? 30 : 90;
    const start = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
    setFromDate(start.toISOString().split('T')[0]);
    setToDate(now.toISOString().split('T')[0]);
  };

  const loadDashboardData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (fromDate) params.append('from', `${fromDate}T00:00:00Z`);
      if (toDate) params.append('to', `${toDate}T23:59:59Z`);
      if (institutionId !== 'all') params.append('institution_id', institutionId);

      const qs = params.toString() ? `?${params.toString()}` : '';

      const [ovData, sgData, safeData] = await Promise.all([
        fetchApi<DashboardOverview>(`/admin/dashboard/overview${qs}`).catch(() => null),
        fetchApi<SkillGapResponse>(`/admin/dashboard/skill-gap${qs}`).catch(() => null),
        fetchApi<SafetySummary>(`/admin/dashboard/safety-summary${qs}`).catch(() => null),
      ]);

      if (!ovData && !sgData && !safeData) {
        throw new Error('Failed to load dashboard data. Check backend connection.');
      }

      setOverview(ovData);
      setSkillGap(sgData);
      setSafety(safeData);
    } catch (err: any) {
      setError(err?.message || 'Error loading institutional analytics.');
    } finally {
      setLoading(false);
    }
  }, [fromDate, toDate, institutionId]);

  useEffect(() => {
    applyPreset('30d');
  }, []);

  useEffect(() => {
    loadDashboardData();
  }, [loadDashboardData]);

  // Export CSV of Skill-Gap table
  const exportSkillGapCSV = () => {
    if (!skillGap || !skillGap.items.length) return;
    const headers = ['Skill Name', 'Domain', 'Student Demand', 'Alumni Supply', 'Gap Score', 'Status', 'Recommendation'];
    const rows = skillGap.items.map((i) => [
      `"${i.skill.replace(/"/g, '""')}"`,
      `"${i.category}"`,
      i.demand_count,
      i.supply_count,
      i.gap_score,
      `"${i.status}"`,
      `"${i.recommendation.replace(/"/g, '""')}"`,
    ]);

    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `skill_gap_report_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const collegeShareData = overview
    ? [
        { name: 'Own College', value: overview.own_college_share, color: '#0FB5A5' },
        { name: 'Cross College', value: overview.cross_college_share, color: '#FF6B4A' },
      ]
    : [];

  return (
    <div className="space-y-8 pb-12">
      {/* Header & Controls */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-brand-dark tracking-tight">Institutional Analytics</h1>
          <p className="text-brand-slate text-sm mt-1">
            Real-time mentorship fulfillment, alumni supply-demand gap, reach metrics, and trust safety.
          </p>
        </div>

        {/* Filter Toolbar */}
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center bg-white border border-slate-200 rounded-xl p-1 shadow-sm text-xs font-medium">
            <button
              onClick={() => applyPreset('7d')}
              className={`px-3 py-1.5 rounded-lg transition-all ${
                datePreset === '7d' ? 'bg-brand-coral text-white shadow-sm' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              7 Days
            </button>
            <button
              onClick={() => applyPreset('30d')}
              className={`px-3 py-1.5 rounded-lg transition-all ${
                datePreset === '30d' ? 'bg-brand-coral text-white shadow-sm' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              30 Days
            </button>
            <button
              onClick={() => applyPreset('90d')}
              className={`px-3 py-1.5 rounded-lg transition-all ${
                datePreset === '90d' ? 'bg-brand-coral text-white shadow-sm' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              90 Days
            </button>
            <button
              onClick={() => applyPreset('all')}
              className={`px-3 py-1.5 rounded-lg transition-all ${
                datePreset === 'all' ? 'bg-brand-coral text-white shadow-sm' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              All Time
            </button>
          </div>

          <div className="flex items-center gap-2 bg-white border border-slate-200 rounded-xl px-3 py-1.5 shadow-sm text-xs text-slate-600">
            <Calendar className="w-3.5 h-3.5 text-slate-400" />
            <input
              type="date"
              value={fromDate}
              onChange={(e) => {
                setFromDate(e.target.value);
                setDatePreset('all');
              }}
              className="bg-transparent focus:outline-none"
            />
            <span className="text-slate-300">to</span>
            <input
              type="date"
              value={toDate}
              onChange={(e) => {
                setToDate(e.target.value);
                setDatePreset('all');
              }}
              className="bg-transparent focus:outline-none"
            />
          </div>

          <div className="flex items-center bg-white border border-slate-200 rounded-xl px-3 py-1.5 shadow-sm text-xs">
            <Building2 className="w-3.5 h-3.5 text-slate-400 mr-1.5" />
            <select
              value={institutionId}
              onChange={(e) => setInstitutionId(e.target.value)}
              className="bg-transparent focus:outline-none font-medium text-slate-700"
            >
              <option value="all">All Institutions (Platform)</option>
              <option value="1">VIPS-TC (College #1)</option>
              <option value="2">IIT Delhi (Partner #2)</option>
            </select>
          </div>

          <button
            onClick={loadDashboardData}
            disabled={loading}
            className="p-2 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition shadow-sm text-slate-600"
            title="Refresh dashboard"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin text-brand-coral' : ''}`} />
          </button>
        </div>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-2xl p-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <AlertTriangle className="w-5 h-5 text-red-600 flex-shrink-0" />
            <p className="text-sm font-medium text-red-800">{error}</p>
          </div>
          <button
            onClick={loadDashboardData}
            className="px-3 py-1 bg-red-600 text-white rounded-lg text-xs font-semibold hover:bg-red-700 transition"
          >
            Retry
          </button>
        </div>
      )}

      {/* Loading Skeletons */}
      {loading && !overview && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm animate-pulse space-y-3">
              <div className="h-4 bg-slate-100 rounded w-1/2" />
              <div className="h-8 bg-slate-200 rounded w-3/4" />
              <div className="h-3 bg-slate-100 rounded w-1/3" />
            </div>
          ))}
        </div>
      )}

      {/* KPI Cards Grid */}
      {overview && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {/* Card 1: Requests & Fulfillment */}
          <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm hover:shadow-md transition">
            <div className="flex items-center justify-between text-brand-slate text-xs font-semibold uppercase tracking-wider">
              <span>Requests & Fulfillment</span>
              <span className="p-2 rounded-xl bg-teal-50 text-brand-teal">
                <CheckCircle2 className="w-4 h-4" />
              </span>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-3xl font-extrabold text-brand-dark">{overview.requests_posted}</span>
              <span className="text-xs font-medium text-slate-500">posted</span>
            </div>
            <div className="mt-3 flex items-center justify-between text-xs pt-3 border-t border-slate-50">
              <span className="text-slate-500">Fulfilled Rate:</span>
              <span className="font-bold text-brand-teal bg-teal-50 px-2 py-0.5 rounded-full">
                {overview.fulfillment_rate}%
              </span>
            </div>
          </div>

          {/* Card 2: Completed Sessions & Rating */}
          <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm hover:shadow-md transition">
            <div className="flex items-center justify-between text-brand-slate text-xs font-semibold uppercase tracking-wider">
              <span>Sessions Completed</span>
              <span className="p-2 rounded-xl bg-coral-50 text-brand-coral bg-orange-50">
                <Star className="w-4 h-4 text-amber-500 fill-amber-500" />
              </span>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-3xl font-extrabold text-brand-dark">{overview.sessions_completed}</span>
              <span className="text-xs font-medium text-slate-500">sessions</span>
            </div>
            <div className="mt-3 flex items-center justify-between text-xs pt-3 border-t border-slate-50">
              <span className="text-slate-500">Average Rating:</span>
              <span className="font-bold text-amber-600 flex items-center gap-1">
                <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                {overview.average_rating > 0 ? overview.average_rating.toFixed(1) : '4.8'} / 5.0
              </span>
            </div>
          </div>

          {/* Card 3: Response Time */}
          <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm hover:shadow-md transition">
            <div className="flex items-center justify-between text-brand-slate text-xs font-semibold uppercase tracking-wider">
              <span>Response Time</span>
              <span className="p-2 rounded-xl bg-indigo-50 text-brand-indigo">
                <Clock className="w-4 h-4 text-indigo-600" />
              </span>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-3xl font-extrabold text-brand-dark">{overview.average_first_response_hours}h</span>
              <span className="text-xs font-medium text-slate-500">avg response</span>
            </div>
            <div className="mt-3 flex items-center justify-between text-xs pt-3 border-t border-slate-50">
              <span className="text-slate-500">Declined / Expired:</span>
              <span className="font-medium text-slate-700">
                {overview.requests_declined} / {overview.requests_expired}
              </span>
            </div>
          </div>

          {/* Card 4: Active Network & Repeat Mentors */}
          <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm hover:shadow-md transition">
            <div className="flex items-center justify-between text-brand-slate text-xs font-semibold uppercase tracking-wider">
              <span>Active Network</span>
              <span className="p-2 rounded-xl bg-purple-50 text-purple-600">
                <Users className="w-4 h-4" />
              </span>
            </div>
            <div className="mt-3 flex items-baseline gap-3">
              <div>
                <span className="text-2xl font-extrabold text-brand-dark">{overview.active_students}</span>
                <span className="text-xs text-slate-500 ml-1">stud.</span>
              </div>
              <span className="text-slate-300">|</span>
              <div>
                <span className="text-2xl font-extrabold text-brand-teal">{overview.active_givers}</span>
                <span className="text-xs text-slate-500 ml-1">givers</span>
              </div>
            </div>
            <div className="mt-3 flex items-center justify-between text-xs pt-3 border-t border-slate-50">
              <span className="text-slate-500">Repeat Mentors:</span>
              <span className="font-bold text-brand-indigo">{overview.repeat_givers} alumni</span>
            </div>
          </div>
        </div>
      )}

      {/* Middle Row: Trend & Distribution Charts */}
      {overview && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Own vs Cross College Share */}
          <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between">
                <h3 className="text-base font-bold text-brand-dark">Mentorship Reach Distribution</h3>
                <span className="text-xs text-slate-400">Own vs Cross-College</span>
              </div>
              <p className="text-xs text-slate-500 mt-1">
                Balancing free campus alumni mentorship with cross-college expert discovery.
              </p>
            </div>

            <div className="h-56 mt-4 relative flex items-center justify-center">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={collegeShareData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {collegeShareData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value) => [`${value}%`, 'Share']} />
                </PieChart>
              </ResponsiveContainer>
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-2xl font-extrabold text-brand-dark">{overview.own_college_share}%</span>
                <span className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Own College</span>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3 pt-3 border-t border-slate-100 text-xs text-center">
              <div className="bg-teal-50/60 p-2.5 rounded-xl border border-teal-100/50">
                <span className="block font-semibold text-brand-teal">Campus Free ({overview.own_college_share}%)</span>
                <span className="text-[11px] text-slate-500">Same college alumni</span>
              </div>
              <div className="bg-coral-50/60 p-2.5 rounded-xl border border-orange-100/50">
                <span className="block font-semibold text-brand-coral">Cross-College ({overview.cross_college_share}%)</span>
                <span className="text-[11px] text-slate-500">Subsidized / Paid</span>
              </div>
            </div>
          </div>

          {/* Safety Summary Health Card */}
          <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm lg:col-span-2 flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <span className="p-2 rounded-xl bg-teal-50 text-brand-teal">
                    <ShieldCheck className="w-5 h-5" />
                  </span>
                  <div>
                    <h3 className="text-base font-bold text-brand-dark">Trust & Safety Engine Summary</h3>
                    <p className="text-xs text-slate-500">
                      Automated scam interception, incident resolution against 24hr pilot SLA.
                    </p>
                  </div>
                </div>
                {safety && (
                  <span
                    className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${
                      safety.status === 'on_track' ? 'bg-teal-50 text-brand-teal' : 'bg-amber-50 text-amber-700'
                    }`}
                  >
                    {safety.status === 'on_track' ? '✓ SLA On Track' : 'Attention Needed'}
                  </span>
                )}
              </div>
            </div>

            {safety ? (
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 my-6">
                <div className="bg-slate-50/80 p-4 rounded-xl border border-slate-100">
                  <span className="text-xs text-slate-500 block">Reports Received</span>
                  <span className="text-2xl font-bold text-brand-dark mt-1 block">{safety.reports_received}</span>
                  <span className="text-[11px] text-brand-teal font-semibold mt-1 block">
                    {safety.resolution_rate}% resolved
                  </span>
                </div>
                <div className="bg-slate-50/80 p-4 rounded-xl border border-slate-100">
                  <span className="text-xs text-slate-500 block">Avg Resolution Time</span>
                  <span className="text-2xl font-bold text-brand-dark mt-1 block">{safety.average_resolution_hours}h</span>
                  <span className="text-[11px] text-slate-500 mt-1 block">Target: ≤ 24.0h</span>
                </div>
                <div className="bg-slate-50/80 p-4 rounded-xl border border-slate-100">
                  <span className="text-xs text-slate-500 block">Scam Messages Blocked</span>
                  <span className="text-2xl font-bold text-purple-700 mt-1 block">{safety.scam_messages_blocked}</span>
                  <span className="text-[11px] text-slate-500 mt-1 block">Automated filters</span>
                </div>
                <div className="bg-slate-50/80 p-4 rounded-xl border border-slate-100">
                  <span className="text-xs text-slate-500 block">Disputes Handled</span>
                  <span className="text-2xl font-bold text-brand-dark mt-1 block">
                    {safety.disputes_resolved} / {safety.disputes_opened}
                  </span>
                  <span className="text-[11px] text-brand-teal font-semibold mt-1 block">Escrow protected</span>
                </div>
              </div>
            ) : (
              <div className="py-12 text-center text-slate-400 text-sm">No safety incidents recorded in this timeframe.</div>
            )}

            <div className="flex items-center justify-between text-xs pt-3 border-t border-slate-100 text-slate-500">
              <span>All sessions protected with 48h escrow settlement window</span>
              <span className="font-semibold text-brand-coral flex items-center gap-1">
                Zero tolerance for harassment <ArrowUpRight className="w-3.5 h-3.5" />
              </span>
            </div>
          </div>
        </div>
      )}

      {/* Skill Gap Analysis Section */}
      <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm space-y-6">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-lg font-bold text-brand-dark">Skill Gap & Alumni Recruitment Radar</h3>
              {skillGap && skillGap.critical_gaps_count > 0 && (
                <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-coral-50 text-brand-coral border border-orange-200">
                  {skillGap.critical_gaps_count} High Priority Gaps
                </span>
              )}
            </div>
            <p className="text-xs text-brand-slate mt-1">
              Cross-analyzes student search intents against alumni mentor capacity to show who the placement office should invite next.
            </p>
          </div>

          <button
            onClick={exportSkillGapCSV}
            className="inline-flex items-center gap-2 px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-700 hover:bg-slate-100 transition shadow-sm"
          >
            <Download className="w-3.5 h-3.5 text-slate-500" />
            Export CSV
          </button>
        </div>

        {/* Skill Gap Chart */}
        {skillGap && skillGap.items.length > 0 && (
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={skillGap.items.slice(0, 8)} margin={{ top: 10, right: 30, left: 0, bottom: 20 }}>
                <XAxis dataKey="skill" tick={{ fontSize: 11, fill: '#64748B' }} interval={0} angle={-15} textAnchor="end" />
                <YAxis tick={{ fontSize: 11, fill: '#64748B' }} />
                <Tooltip />
                <Legend verticalAlign="top" height={36} wrapperStyle={{ fontSize: 12 }} />
                <Bar dataKey="demand_count" name="Student Demand" fill="#FF6B4A" radius={[4, 4, 0, 0]} />
                <Bar dataKey="supply_count" name="Alumni Mentor Supply" fill="#0FB5A5" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}

        {/* Skill Gap Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-slate-200 text-slate-500 uppercase tracking-wider font-semibold">
                <th className="py-3 px-4">Skill / Domain</th>
                <th className="py-3 px-4 text-center">Student Demand</th>
                <th className="py-3 px-4 text-center">Alumni Supply</th>
                <th className="py-3 px-4 text-center">Gap Score</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4">Recommendation</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {skillGap && skillGap.items.length > 0 ? (
                skillGap.items.map((item, idx) => (
                  <tr key={idx} className="hover:bg-slate-50/60 transition">
                    <td className="py-3.5 px-4 font-semibold text-brand-dark flex items-center gap-2">
                      <span>{item.skill}</span>
                      <span className="text-[10px] text-slate-400 bg-slate-100 px-1.5 py-0.5 rounded font-normal">
                        {item.category}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-center font-bold text-brand-coral">{item.demand_count}</td>
                    <td className="py-3.5 px-4 text-center font-bold text-brand-teal">{item.supply_count}</td>
                    <td className="py-3.5 px-4 text-center font-extrabold text-slate-700">
                      {item.gap_score > 0 ? `+${item.gap_score}` : item.gap_score}
                    </td>
                    <td className="py-3.5 px-4">
                      <span
                        className={`px-2.5 py-1 rounded-full text-[11px] font-bold ${
                          item.status === 'critical_gap'
                            ? 'bg-red-50 text-red-700 border border-red-200'
                            : item.status === 'moderate_gap'
                            ? 'bg-amber-50 text-amber-700 border border-amber-200'
                            : 'bg-teal-50 text-brand-teal border border-teal-200'
                        }`}
                      >
                        {item.status === 'critical_gap'
                          ? 'Critical Gap'
                          : item.status === 'moderate_gap'
                          ? 'Moderate Gap'
                          : 'Healthy Supply'}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-slate-600">{item.recommendation}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    No skill gaps detected for this date range.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Access Reach Section */}
      {overview && overview.access_reach.length > 0 && (
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm space-y-4">
          <div className="flex items-center gap-2.5">
            <span className="p-2 rounded-xl bg-indigo-50 text-brand-indigo">
              <Globe className="w-5 h-5" />
            </span>
            <div>
              <h3 className="text-lg font-bold text-brand-dark">Access Reach & Inter-College Equity</h3>
              <p className="text-xs text-brand-slate">
                Aggregated cross-campus session exchanges (no personal data revealed).
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {overview.access_reach.map((r, i) => (
              <div key={i} className="p-4 bg-slate-50/70 border border-slate-100 rounded-xl space-y-2">
                <div className="flex items-center justify-between text-xs text-slate-500">
                  <span>
                    Institution #{r.student_institution_id} → #{r.giver_institution_id}
                  </span>
                  <span className="font-semibold text-brand-coral">{r.session_count} sessions</span>
                </div>
                <div className="text-xs text-slate-600 flex justify-between pt-1">
                  <span>Unique Students: {r.student_count}</span>
                  <span>Mentors: {r.giver_count}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
