import React from 'react';
import { Users } from 'lucide-react';

export const SeatsPage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-3">
        <Users className="w-6 h-6 text-indigo-950" />
        <h2 className="text-2xl font-bold text-indigo-950">Sponsored Seats & Roster</h2>
      </div>
      <div className="bg-white p-6 rounded-xl border border-slate-200">
        <p className="text-slate-600">
          Manage college-funded seats and monitor credit utilization for students reaching cross-college givers.
        </p>
      </div>
    </div>
  );
};
