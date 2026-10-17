import React, { useState, useEffect, useRef } from 'react';
import {
  ShieldCheck,
  UserCheck,
  Building,
  GraduationCap,
  Award,
  UploadCloud,
  FileText,
  AlertCircle,
  CheckCircle,
  XCircle,
  ExternalLink,
  Search,
  Filter,
  RefreshCw,
  ChevronRight,
  X,
  FileSpreadsheet,
} from 'lucide-react';
import {
  fetchApi,
  VerificationQueueItem,
  VerificationQueueResponse,
  ApprovedMembersUploadResponse,
} from '../../core/api';
import { useToast } from '../../core/toast';
import { useAuth } from '../../core/auth';

type Tab = 'queue' | 'upload';

interface ParsedCsvRow {
  line: number;
  fullName: string;
  email: string;
  role: string;
  batch?: string;
  department?: string;
  errors: string[];
}

export const VerificationPage: React.FC = () => {
  const { user } = useAuth();
  const { addToast } = useToast();

  const [activeTab, setActiveTab] = useState<Tab>('queue');

  // --- Queue State ---
  const [items, setItems] = useState<VerificationQueueItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filterKind, setFilterKind] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedItem, setSelectedItem] = useState<VerificationQueueItem | null>(null);

  // --- Decision Modal State ---
  const [decisionMode, setDecisionMode] = useState<'approve' | 'reject' | null>(null);
  const [decisionBadge, setDecisionBadge] = useState<string>('');
  const [decisionNote, setDecisionNote] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // --- CSV Upload State ---
  const [csvFile, setCsvFile] = useState<File | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [parsedRows, setParsedRows] = useState<ParsedCsvRow[]>([]);
  const [csvParsingError, setCsvParsingError] = useState<string | null>(null);
  const [isUploadingCsv, setIsUploadingCsv] = useState(false);
  const [uploadResult, setUploadResult] = useState<ApprovedMembersUploadResponse | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Load verification queue
  const loadQueue = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await fetchApi<VerificationQueueResponse>('/admin/verification/queue?limit=50');
      setItems(data.items || []);
    } catch (err: any) {
      setError(err?.error?.message || 'Failed to load verification queue');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadQueue();
  }, []);

  // Update default badge when selecting item
  useEffect(() => {
    if (selectedItem) {
      const kindStr: string = selectedItem.kind;
      if (kindStr === 'alumnus') setDecisionBadge('Verified Alumnus');
      else if (kindStr === 'employer') setDecisionBadge('Verified Employer');
      else if (kindStr === 'expert') setDecisionBadge('Verified Expert');
      else if (kindStr === 'faculty') setDecisionBadge('Verified Faculty');
      else setDecisionBadge(`Verified ${kindStr.charAt(0).toUpperCase() + kindStr.slice(1)}`);
      setDecisionNote('');
      setDecisionMode(null);
    }
  }, [selectedItem]);

  // Handle Decision Submit
  const handleDecisionSubmit = async () => {
    if (!selectedItem || !decisionMode) return;
    if (decisionMode === 'reject' && !decisionNote.trim()) {
      addToast('error', 'A rejection reason is required to notify the applicant.');
      return;
    }

    setIsSubmitting(true);
    try {
      await fetchApi(`/admin/verification/${selectedItem.id}/decide`, {
        method: 'POST',
        body: JSON.stringify({
          decision: decisionMode,
          badge: decisionMode === 'approve' ? decisionBadge || undefined : undefined,
          note: decisionNote.trim() || undefined,
        }),
      });

      addToast(
        'success',
        decisionMode === 'approve'
          ? `Approved ${selectedItem.user_full_name} (${decisionBadge})`
          : `Rejected request for ${selectedItem.user_full_name}`
      );

      // Remove from list
      setItems((prev) => prev.filter((i) => i.id !== selectedItem.id));
      setSelectedItem(null);
      setDecisionMode(null);
    } catch (err: any) {
      addToast('error', err?.error?.message || 'Failed to submit verification decision');
    } finally {
      setIsSubmitting(false);
    }
  };

  // CSV Drag and Drop
  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      processCsvFile(e.dataTransfer.files[0]);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      processCsvFile(e.target.files[0]);
    }
  };

  // Parse and validate CSV client-side
  const processCsvFile = (file: File) => {
    if (!file.name.endsWith('.csv')) {
      setCsvParsingError('Please select a valid CSV file (.csv)');
      return;
    }

    setCsvFile(file);
    setUploadResult(null);
    setCsvParsingError(null);

    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const text = event.target?.result as string;
        if (!text) {
          setCsvParsingError('The selected file is empty.');
          setParsedRows([]);
          return;
        }

        const lines = text.split(/\r?\n/).map((l) => l.trim()).filter((l) => l.length > 0);
        if (lines.length < 2) {
          setCsvParsingError('CSV file must have a header row and at least one data row.');
          setParsedRows([]);
          return;
        }

        // Header verification
        const headers = lines[0].split(',').map((h) => h.trim().toLowerCase().replace(/^["']|["']$/g, ''));
        const requiredHeaders = ['full_name', 'email', 'role'];
        const missing = requiredHeaders.filter((rh) => !headers.includes(rh));

        if (missing.length > 0) {
          setCsvParsingError(`Missing required column headers: ${missing.join(', ')}. (Expected: full_name, email, role, [batch, department])`);
          setParsedRows([]);
          return;
        }

        const nameIdx = headers.indexOf('full_name');
        const emailIdx = headers.indexOf('email');
        const roleIdx = headers.indexOf('role');
        const batchIdx = headers.indexOf('batch');
        const deptIdx = headers.indexOf('department');

        const rows: ParsedCsvRow[] = [];

        for (let i = 1; i < lines.length; i++) {
          const rawParts = lines[i].split(',').map((p) => p.trim().replace(/^["']|["']$/g, ''));
          const rowErrors: string[] = [];

          const fullName = rawParts[nameIdx] || '';
          const email = (rawParts[emailIdx] || '').toLowerCase();
          const role = (rawParts[roleIdx] || '').toLowerCase();
          const batch = batchIdx >= 0 ? rawParts[batchIdx] : undefined;
          const department = deptIdx >= 0 ? rawParts[deptIdx] : undefined;

          if (!fullName) rowErrors.push('Missing full_name');
          if (!email || !email.includes('@') || !email.includes('.')) {
            rowErrors.push(`Invalid email: "${email}"`);
          }
          if (!['student', 'alumnus', 'faculty'].includes(role)) {
            rowErrors.push(`Invalid role: "${role}" (must be student, alumnus, or faculty)`);
          }

          rows.push({
            line: i + 1,
            fullName,
            email,
            role,
            batch,
            department,
            errors: rowErrors,
          });
        }

        setParsedRows(rows);
      } catch {
        setCsvParsingError('Failed to parse CSV file. Ensure valid comma-delimited encoding.');
        setParsedRows([]);
      }
    };
    reader.readAsText(file);
  };

  // Upload CSV to Backend
  const handleUploadRoster = async () => {
    if (!csvFile) return;

    setIsUploadingCsv(true);
    setUploadResult(null);

    const formData = new FormData();
    formData.append('file', csvFile);
    if (user?.institution_id) {
      formData.append('institution_id', user.institution_id.toString());
    }

    try {
      const result = await fetchApi<ApprovedMembersUploadResponse>('/admin/approved-members/upload', {
        method: 'POST',
        body: formData,
      });
      setUploadResult(result);
      addToast('success', `Roster imported: ${result.inserted} added, ${result.duplicates_skipped} duplicates skipped.`);
    } catch (err: any) {
      addToast('error', err?.error?.message || 'Failed to upload approved members CSV');
    } finally {
      setIsUploadingCsv(false);
    }
  };

  // Reset CSV upload
  const resetCsvUpload = () => {
    setCsvFile(null);
    setParsedRows([]);
    setCsvParsingError(null);
    setUploadResult(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  // Filter items
  const filteredItems = items.filter((item) => {
    if (filterKind !== 'all' && item.kind !== filterKind) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const matchName = item.user_full_name.toLowerCase().includes(q);
      const matchEmail = item.user_email.toLowerCase().includes(q);
      const matchCompany = (item.company_name || '').toLowerCase().includes(q);
      if (!matchName && !matchEmail && !matchCompany) return false;
    }
    return true;
  });

  const getKindIcon = (kind: string) => {
    switch (kind) {
      case 'alumnus':
        return <GraduationCap className="w-4 h-4 text-brand-indigo" />;
      case 'employer':
        return <Building className="w-4 h-4 text-brand-coral" />;
      case 'faculty':
        return <UserCheck className="w-4 h-4 text-brand-teal" />;
      case 'expert':
        return <Award className="w-4 h-4 text-brand-amber" />;
      default:
        return <ShieldCheck className="w-4 h-4 text-brand-slate" />;
    }
  };

  const getKindBadgeClass = (kind: string) => {
    switch (kind) {
      case 'alumnus':
        return 'bg-indigo-50 text-brand-indigo border-indigo-200';
      case 'employer':
        return 'bg-orange-50 text-brand-coral border-orange-200';
      case 'faculty':
        return 'bg-teal-50 text-brand-teal border-teal-200';
      case 'expert':
        return 'bg-amber-50 text-brand-amber border-amber-200';
      default:
        return 'bg-slate-50 text-brand-slate border-slate-200';
    }
  };

  const hasCsvErrors = parsedRows.some((r) => r.errors.length > 0);

  return (
    <div className="space-y-6">
      {/* Header and Tabs */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-200 pb-5">
        <div>
          <h1 className="text-2xl font-bold text-brand-dark flex items-center gap-2">
            <ShieldCheck className="w-7 h-7 text-brand-teal" />
            Verification & Institutional Rosters
          </h1>
          <p className="text-sm text-brand-slate mt-1">
            Review identity and role credentials, issue institutional trust badges, and import verified member rosters.
          </p>
        </div>

        {/* Tab Switcher */}
        <div className="flex bg-slate-100 p-1 rounded-xl w-fit">
          <button
            onClick={() => setActiveTab('queue')}
            className={`flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg transition-all ${
              activeTab === 'queue'
                ? 'bg-white text-brand-dark shadow-sm'
                : 'text-brand-slate hover:text-brand-dark'
            }`}
          >
            <UserCheck className="w-4 h-4" />
            Verification Queue
            {items.length > 0 && (
              <span className="bg-brand-coral text-white text-xs px-2 py-0.5 rounded-full font-bold">
                {items.length}
              </span>
            )}
          </button>
          <button
            onClick={() => setActiveTab('upload')}
            className={`flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg transition-all ${
              activeTab === 'upload'
                ? 'bg-white text-brand-dark shadow-sm'
                : 'text-brand-slate hover:text-brand-dark'
            }`}
          >
            <UploadCloud className="w-4 h-4" />
            Approved Members Upload
          </button>
        </div>
      </div>

      {/* TAB 1: VERIFICATION QUEUE */}
      {activeTab === 'queue' && (
        <div className="space-y-6">
          {/* Controls Bar */}
          <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-100 flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-2 w-full md:w-auto">
              <div className="relative w-full md:w-64">
                <Search className="w-4 h-4 absolute left-3 top-3 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search applicant or company..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-teal/30 focus:border-brand-teal"
                />
              </div>

              <div className="flex items-center gap-1 bg-slate-50 border border-slate-200 rounded-lg p-1">
                <Filter className="w-4 h-4 text-slate-400 ml-2" />
                <select
                  value={filterKind}
                  onChange={(e) => setFilterKind(e.target.value)}
                  className="bg-transparent text-xs font-medium text-brand-dark py-1 pr-3 pl-1 focus:outline-none"
                >
                  <option value="all">All Roles</option>
                  <option value="alumnus">Alumnus</option>
                  <option value="employer">Employer</option>
                  <option value="expert">Expert</option>
                  <option value="faculty">Faculty</option>
                </select>
              </div>
            </div>

            <button
              onClick={loadQueue}
              disabled={loading}
              className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-brand-slate hover:text-brand-dark border border-slate-200 hover:border-slate-300 rounded-lg transition-all"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
              Refresh
            </button>
          </div>

          {/* Error Message */}
          {error && (
            <div className="p-4 bg-red-50 border border-red-200 rounded-xl flex items-center gap-3 text-sm text-red-700">
              <AlertCircle className="w-5 h-5 flex-shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {/* Queue Content */}
          {loading ? (
            <div className="bg-white rounded-2xl p-12 text-center border border-slate-100 shadow-sm">
              <div className="w-8 h-8 border-3 border-brand-teal border-t-transparent rounded-full animate-spin mx-auto mb-3" />
              <p className="text-sm text-brand-slate font-medium">Loading verification submissions...</p>
            </div>
          ) : filteredItems.length === 0 ? (
            <div className="bg-white rounded-2xl p-12 text-center border border-slate-100 shadow-sm">
              <CheckCircle className="w-12 h-12 text-brand-teal mx-auto mb-3 opacity-80" />
              <h3 className="text-base font-bold text-brand-dark mb-1">Queue is clear!</h3>
              <p className="text-sm text-brand-slate max-w-md mx-auto">
                There are no pending verification submissions matching your filter criteria.
              </p>
            </div>
          ) : (
            <div className="bg-white rounded-xl shadow-sm border border-slate-100 overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-100">
                    <tr>
                      <th className="py-3 px-4">Applicant</th>
                      <th className="py-3 px-4">Role Requested</th>
                      <th className="py-3 px-4">Evidence & Credentials</th>
                      <th className="py-3 px-4">Submitted</th>
                      <th className="py-3 px-4 text-right">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filteredItems.map((item) => (
                      <tr
                        key={item.id}
                        className="hover:bg-slate-50/70 transition-colors cursor-pointer"
                        onClick={() => setSelectedItem(item)}
                      >
                        <td className="py-3.5 px-4">
                          <div className="font-semibold text-brand-dark">{item.user_full_name}</div>
                          <div className="text-xs text-brand-slate">{item.user_email}</div>
                        </td>
                        <td className="py-3.5 px-4">
                          <span
                            className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold border ${getKindBadgeClass(
                              item.kind
                            )}`}
                          >
                            {getKindIcon(item.kind)}
                            <span className="capitalize">{item.kind}</span>
                          </span>
                        </td>
                        <td className="py-3.5 px-4 max-w-xs">
                          {item.company_name && (
                            <div className="text-xs font-medium text-brand-dark flex items-center gap-1 mb-0.5">
                              <Building className="w-3 h-3 text-slate-400" />
                              {item.company_name}
                              {item.company_registration && (
                                <span className="text-slate-400">({item.company_registration})</span>
                              )}
                            </div>
                          )}
                          <div className="text-xs text-brand-slate line-clamp-1 truncate">
                            {item.evidence_text || 'No text note'}
                          </div>
                          {item.evidence_urls && item.evidence_urls.length > 0 && (
                            <div className="text-[11px] text-brand-teal flex items-center gap-1 mt-0.5 font-medium">
                              <ExternalLink className="w-3 h-3" />
                              {item.evidence_urls.length} link(s) attached
                            </div>
                          )}
                        </td>
                        <td className="py-3.5 px-4 text-xs text-brand-slate">
                          {new Date(item.created_at).toLocaleDateString(undefined, {
                            month: 'short',
                            day: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </td>
                        <td className="py-3.5 px-4 text-right">
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              setSelectedItem(item);
                            }}
                            className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-semibold text-brand-teal hover:bg-teal-50 border border-teal-200 rounded-lg transition-colors"
                          >
                            Review
                            <ChevronRight className="w-3.5 h-3.5" />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}

      {/* TAB 2: APPROVED MEMBERS CSV UPLOAD */}
      {activeTab === 'upload' && (
        <div className="space-y-6">
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
            <h2 className="text-lg font-bold text-brand-dark mb-1 flex items-center gap-2">
              <FileSpreadsheet className="w-5 h-5 text-brand-teal" />
              Institutional Member Roster Import
            </h2>
            <p className="text-sm text-brand-slate mb-6">
              Upload your verified roster of students, alumni, and faculty to enable automatic badge assignment and
              instant passwordless access.
            </p>

            {/* Dropzone */}
            <div
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              onClick={() => fileInputRef.current?.click()}
              className={`border-2 border-dashed rounded-2xl p-8 text-center cursor-pointer transition-all ${
                isDragging
                  ? 'border-brand-teal bg-teal-50/50 scale-[0.99]'
                  : 'border-slate-200 hover:border-slate-300 bg-slate-50/50'
              }`}
            >
              <input
                ref={fileInputRef}
                type="file"
                accept=".csv"
                className="hidden"
                onChange={handleFileChange}
              />
              <UploadCloud className="w-12 h-12 text-slate-400 mx-auto mb-3" />
              <div className="font-semibold text-brand-dark text-base mb-1">
                {csvFile ? csvFile.name : 'Choose a CSV file or drag & drop it here'}
              </div>
              <p className="text-xs text-brand-slate max-w-md mx-auto mb-2">
                Required columns: <code className="bg-slate-100 px-1 py-0.5 rounded text-brand-indigo">full_name</code>,{' '}
                <code className="bg-slate-100 px-1 py-0.5 rounded text-brand-indigo">email</code>,{' '}
                <code className="bg-slate-100 px-1 py-0.5 rounded text-brand-indigo">role</code> (student, alumnus, faculty).
                Optional: <code className="bg-slate-100 px-1 py-0.5 rounded text-slate-600">batch</code>,{' '}
                <code className="bg-slate-100 px-1 py-0.5 rounded text-slate-600">department</code>.
              </p>
              {csvFile && (
                <div className="inline-flex items-center gap-1.5 text-xs text-brand-teal font-semibold mt-2 bg-white px-3 py-1 rounded-full border border-teal-200">
                  <FileText className="w-3.5 h-3.5" />
                  {(csvFile.size / 1024).toFixed(1)} KB • {parsedRows.length} rows loaded
                </div>
              )}
            </div>

            {/* Client-side Validation Error Banner */}
            {csvParsingError && (
              <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-xl flex items-center justify-between text-sm text-red-700">
                <div className="flex items-center gap-3">
                  <AlertCircle className="w-5 h-5 flex-shrink-0" />
                  <span>{csvParsingError}</span>
                </div>
                <button
                  onClick={resetCsvUpload}
                  className="text-xs font-semibold text-red-700 hover:underline"
                >
                  Clear
                </button>
              </div>
            )}

            {/* Parsed Rows Preview */}
            {parsedRows.length > 0 && (
              <div className="mt-6 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <span className="text-sm font-bold text-brand-dark">Roster Preview:</span>
                    <span className="text-xs text-slate-500 font-medium">
                      {parsedRows.length} total rows parsed
                    </span>
                    {hasCsvErrors ? (
                      <span className="bg-red-50 text-red-700 border border-red-200 text-xs px-2.5 py-0.5 rounded-full font-semibold flex items-center gap-1">
                        <AlertCircle className="w-3.5 h-3.5" />
                        {parsedRows.filter((r) => r.errors.length > 0).length} row(s) with errors
                      </span>
                    ) : (
                      <span className="bg-teal-50 text-brand-teal border border-teal-200 text-xs px-2.5 py-0.5 rounded-full font-semibold flex items-center gap-1">
                        <CheckCircle className="w-3.5 h-3.5" />
                        All rows valid
                      </span>
                    )}
                  </div>

                  <div className="flex items-center gap-2">
                    <button
                      onClick={resetCsvUpload}
                      className="px-3 py-1.5 text-xs font-semibold text-slate-600 hover:text-slate-800 border border-slate-200 rounded-lg transition-colors"
                    >
                      Clear File
                    </button>
                    <button
                      onClick={handleUploadRoster}
                      disabled={isUploadingCsv || hasCsvErrors}
                      className={`flex items-center gap-2 px-4 py-2 text-xs font-bold rounded-lg transition-all ${
                        hasCsvErrors
                          ? 'bg-slate-200 text-slate-400 cursor-not-allowed'
                          : 'bg-brand-teal text-white hover:bg-teal-600 shadow-sm'
                      }`}
                    >
                      {isUploadingCsv ? (
                        <>
                          <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                          Uploading...
                        </>
                      ) : (
                        <>
                          <UploadCloud className="w-4 h-4" />
                          Confirm & Import Roster
                        </>
                      )}
                    </button>
                  </div>
                </div>

                <div className="max-h-72 overflow-y-auto border border-slate-100 rounded-xl overflow-hidden">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50 text-slate-600 font-semibold sticky top-0 border-b border-slate-100">
                      <tr>
                        <th className="py-2.5 px-3">Line</th>
                        <th className="py-2.5 px-3">Full Name</th>
                        <th className="py-2.5 px-3">Email</th>
                        <th className="py-2.5 px-3">Role</th>
                        <th className="py-2.5 px-3">Batch</th>
                        <th className="py-2.5 px-3">Department</th>
                        <th className="py-2.5 px-3">Status</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {parsedRows.slice(0, 50).map((row) => (
                        <tr
                          key={row.line}
                          className={row.errors.length > 0 ? 'bg-red-50/60' : 'hover:bg-slate-50/50'}
                        >
                          <td className="py-2 px-3 text-slate-400 font-mono">{row.line}</td>
                          <td className="py-2 px-3 font-medium text-brand-dark">{row.fullName || '—'}</td>
                          <td className="py-2 px-3 text-slate-600 font-mono">{row.email || '—'}</td>
                          <td className="py-2 px-3">
                            <span className="capitalize px-1.5 py-0.5 rounded bg-slate-100 text-slate-700">
                              {row.role || '—'}
                            </span>
                          </td>
                          <td className="py-2 px-3 text-slate-500">{row.batch || '—'}</td>
                          <td className="py-2 px-3 text-slate-500">{row.department || '—'}</td>
                          <td className="py-2 px-3">
                            {row.errors.length > 0 ? (
                              <span className="text-red-700 font-medium">{row.errors.join(', ')}</span>
                            ) : (
                              <span className="text-brand-teal font-medium flex items-center gap-1">
                                <CheckCircle className="w-3 h-3" /> Valid
                              </span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  {parsedRows.length > 50 && (
                    <div className="p-2 text-center text-xs text-slate-400 bg-slate-50 border-t border-slate-100">
                      Showing first 50 of {parsedRows.length} rows
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Upload Result Report */}
            {uploadResult && (
              <div className="mt-6 p-5 bg-teal-50 border border-teal-200 rounded-xl space-y-3">
                <div className="flex items-center gap-2 text-brand-teal font-bold text-sm">
                  <CheckCircle className="w-5 h-5" />
                  Roster Upload Completed Successfully
                </div>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
                  <div className="bg-white p-3 rounded-lg border border-teal-100">
                    <div className="text-xs text-slate-500">Total Rows</div>
                    <div className="text-lg font-bold text-brand-dark">{uploadResult.total_rows}</div>
                  </div>
                  <div className="bg-white p-3 rounded-lg border border-teal-100">
                    <div className="text-xs text-brand-teal">Inserted</div>
                    <div className="text-lg font-bold text-brand-teal">+{uploadResult.inserted}</div>
                  </div>
                  <div className="bg-white p-3 rounded-lg border border-teal-100">
                    <div className="text-xs text-amber-600">Duplicates Skipped</div>
                    <div className="text-lg font-bold text-amber-600">{uploadResult.duplicates_skipped}</div>
                  </div>
                  <div className="bg-white p-3 rounded-lg border border-teal-100">
                    <div className="text-xs text-slate-500">Errors</div>
                    <div className="text-lg font-bold text-slate-700">{uploadResult.errors.length}</div>
                  </div>
                </div>

                {uploadResult.errors.length > 0 && (
                  <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-lg text-xs text-red-700">
                    <div className="font-bold mb-1">Server Reported Validation Errors:</div>
                    <ul className="list-disc list-inside space-y-0.5">
                      {uploadResult.errors.map((err, i) => (
                        <li key={i}>{err}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      )}

      {/* REVIEW & DECISION DRAWER / MODAL */}
      {selectedItem && (
        <div
          className="fixed inset-0 z-50 bg-brand-dark/40 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setSelectedItem(null)}
        >
          <div
            className="bg-white rounded-2xl shadow-xl border border-slate-100 max-w-xl w-full p-6 space-y-5 animate-in fade-in zoom-in-95 duration-150"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal Header */}
            <div className="flex items-center justify-between border-b border-slate-100 pb-4">
              <div className="flex items-center gap-3">
                <div className={`p-2 rounded-xl border ${getKindBadgeClass(selectedItem.kind)}`}>
                  {getKindIcon(selectedItem.kind)}
                </div>
                <div>
                  <h3 className="font-bold text-brand-dark text-lg">{selectedItem.user_full_name}</h3>
                  <p className="text-xs text-brand-slate">{selectedItem.user_email}</p>
                </div>
              </div>
              <button
                onClick={() => setSelectedItem(null)}
                className="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Submission Metadata */}
            <div className="space-y-3 bg-slate-50 p-4 rounded-xl text-xs">
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <span className="text-slate-400 block">Requested Role</span>
                  <span className="font-bold text-brand-dark capitalize">{selectedItem.kind}</span>
                </div>
                <div>
                  <span className="text-slate-400 block">Submitted At</span>
                  <span className="font-semibold text-slate-700">
                    {new Date(selectedItem.created_at).toLocaleString()}
                  </span>
                </div>
              </div>

              {selectedItem.company_name && (
                <div className="pt-2 border-t border-slate-200">
                  <span className="text-slate-400 block">Organization</span>
                  <span className="font-bold text-brand-dark">{selectedItem.company_name}</span>
                  {selectedItem.company_registration && (
                    <span className="text-slate-500 ml-2">
                      (CIN / Reg ID: {selectedItem.company_registration})
                    </span>
                  )}
                </div>
              )}

              <div className="pt-2 border-t border-slate-200">
                <span className="text-slate-400 block mb-1">Applicant Evidence & Rationale:</span>
                <p className="text-brand-dark whitespace-pre-wrap leading-relaxed font-sans bg-white p-2.5 rounded-lg border border-slate-200">
                  {selectedItem.evidence_text || 'No description provided.'}
                </p>
              </div>

              {selectedItem.evidence_urls && selectedItem.evidence_urls.length > 0 && (
                <div className="pt-2 border-t border-slate-200">
                  <span className="text-slate-400 block mb-1">Attached Links & Portfolios:</span>
                  <div className="space-y-1">
                    {selectedItem.evidence_urls.map((url, idx) => (
                      <a
                        key={idx}
                        href={url}
                        target="_blank"
                        rel="noreferrer"
                        className="text-brand-teal hover:underline flex items-center gap-1.5 truncate"
                      >
                        <ExternalLink className="w-3.5 h-3.5 flex-shrink-0" />
                        {url}
                      </a>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Action State: Choice vs Form */}
            {!decisionMode ? (
              <div className="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setDecisionMode('reject')}
                  className="flex items-center gap-1.5 px-4 py-2 text-xs font-semibold text-red-600 hover:bg-red-50 border border-red-200 rounded-lg transition-colors"
                >
                  <XCircle className="w-4 h-4" />
                  Reject Request
                </button>
                <button
                  type="button"
                  onClick={() => setDecisionMode('approve')}
                  className="flex items-center gap-1.5 px-4 py-2 text-xs font-bold text-white bg-brand-teal hover:bg-teal-600 rounded-lg transition-colors shadow-sm"
                >
                  <CheckCircle className="w-4 h-4" />
                  Approve Verification
                </button>
              </div>
            ) : decisionMode === 'approve' ? (
              <div className="space-y-4 pt-2 border-t border-slate-100">
                <div className="text-xs font-bold text-brand-teal flex items-center gap-1">
                  <CheckCircle className="w-4 h-4" />
                  Approving Verification
                </div>

                <div>
                  <label className="block text-xs font-semibold text-brand-dark mb-1">
                    Badge to Assign
                  </label>
                  <select
                    value={decisionBadge}
                    onChange={(e) => setDecisionBadge(e.target.value)}
                    className="w-full text-xs border border-slate-200 rounded-lg p-2.5 focus:outline-none focus:ring-2 focus:ring-brand-teal/30 focus:border-brand-teal"
                  >
                    <option value="Verified Alumnus">Verified Alumnus</option>
                    <option value="Verified Employer">Verified Employer</option>
                    <option value="Verified Expert">Verified Expert</option>
                    <option value="Verified Faculty">Verified Faculty</option>
                    <option value="Verified Student">Verified Student</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-brand-dark mb-1">
                    Approval Audit Note (Optional)
                  </label>
                  <textarea
                    rows={2}
                    value={decisionNote}
                    onChange={(e) => setDecisionNote(e.target.value)}
                    placeholder="e.g., Credentials confirmed via institutional registrar database"
                    className="w-full text-xs border border-slate-200 rounded-lg p-2.5 focus:outline-none focus:ring-2 focus:ring-brand-teal/30 focus:border-brand-teal"
                  />
                </div>

                <div className="flex items-center justify-end gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setDecisionMode(null)}
                    disabled={isSubmitting}
                    className="px-3 py-1.5 text-xs font-semibold text-slate-500 hover:text-slate-700"
                  >
                    Back
                  </button>
                  <button
                    type="button"
                    onClick={handleDecisionSubmit}
                    disabled={isSubmitting}
                    className="px-4 py-2 text-xs font-bold text-white bg-brand-teal hover:bg-teal-600 rounded-lg transition-colors flex items-center gap-2"
                  >
                    {isSubmitting ? 'Saving...' : 'Confirm Approval'}
                  </button>
                </div>
              </div>
            ) : (
              <div className="space-y-4 pt-2 border-t border-slate-100">
                <div className="text-xs font-bold text-red-600 flex items-center gap-1">
                  <XCircle className="w-4 h-4" />
                  Rejecting Verification Submission
                </div>

                <div>
                  <label className="block text-xs font-semibold text-brand-dark mb-1">
                    Rejection Reason <span className="text-red-500">*</span>
                  </label>
                  <textarea
                    rows={3}
                    value={decisionNote}
                    onChange={(e) => setDecisionNote(e.target.value)}
                    placeholder="Explain why the request was rejected so the applicant can submit valid documentation..."
                    className="w-full text-xs border border-slate-200 rounded-lg p-2.5 focus:outline-none focus:ring-2 focus:ring-red-500/30 focus:border-red-500"
                  />
                </div>

                <div className="flex items-center justify-end gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setDecisionMode(null)}
                    disabled={isSubmitting}
                    className="px-3 py-1.5 text-xs font-semibold text-slate-500 hover:text-slate-700"
                  >
                    Back
                  </button>
                  <button
                    type="button"
                    onClick={handleDecisionSubmit}
                    disabled={isSubmitting}
                    className="px-4 py-2 text-xs font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors flex items-center gap-2"
                  >
                    {isSubmitting ? 'Saving...' : 'Confirm Rejection'}
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
