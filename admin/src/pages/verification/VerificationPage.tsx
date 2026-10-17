import React from 'react';
import { UserCheck } from 'lucide-react';

export const VerificationPage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-3">
        <UserCheck className="w-6 h-6 text-teal-500" />
        <h2 className="text-2xl font-bold text-indigo-950">Identity Verification Queue</h2>
      </div>
      <div className="bg-white p-6 rounded-xl border border-slate-200">
        <p className="text-slate-600">
          Review student and alumnus identity proofs against institution records.
        </p>
      </div>
    </div>
  );
};
