import React from 'react';

export const VerificationPage: React.FC = () => {
  return (
    <div>
      <h2 className="text-2xl font-bold text-brand-dark mb-2">Member Verification Queue</h2>
      <p className="text-brand-slate mb-6">Validate student rolls, alumni credentials, and recruiter registrations (CIN/GST).</p>
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
        <p className="text-sm text-brand-slate">No pending verification submissions.</p>
      </div>
    </div>
  );
};
