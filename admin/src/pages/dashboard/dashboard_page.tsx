import React from 'react';

export const DashboardPage: React.FC = () => {
  return (
    <div>
      <h2 className="text-2xl font-bold text-brand-dark mb-2">Institutional Analytics Dashboard</h2>
      <p className="text-brand-slate mb-6">Real-time metrics on mentorship sessions, fulfillment rates, and skill gap analytics.</p>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
          <p className="text-sm font-medium text-brand-slate">Completed Sessions</p>
          <p className="text-3xl font-bold text-brand-dark mt-2">0</p>
        </div>
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
          <p className="text-sm font-medium text-brand-slate">72hr Response Rate</p>
          <p className="text-3xl font-bold text-brand-teal mt-2">--%</p>
        </div>
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
          <p className="text-sm font-medium text-brand-slate">Active Verified Givers</p>
          <p className="text-3xl font-bold text-brand-indigo mt-2">0</p>
        </div>
      </div>
    </div>
  );
};
