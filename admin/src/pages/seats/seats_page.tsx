import React from 'react';

export const SeatsPage: React.FC = () => {
  return (
    <div>
      <h2 className="text-2xl font-bold text-brand-dark mb-2">Sponsored Seats & Grants</h2>
      <p className="text-brand-slate mb-6">Manage institutional student subsidies and CSR scholarship pool allocations.</p>
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
        <p className="text-sm text-brand-slate">0 sponsored seats currently allocated.</p>
      </div>
    </div>
  );
};
