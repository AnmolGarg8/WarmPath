import React from 'react';

export const ModerationPage: React.FC = () => {
  return (
    <div>
      <h2 className="text-2xl font-bold text-brand-dark mb-2">Safety & Moderation Queue</h2>
      <p className="text-brand-slate mb-6">Review flagged messages, money-request alerts, and user reports.</p>
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
        <p className="text-sm text-brand-slate">No pending moderation items in queue.</p>
      </div>
    </div>
  );
};
