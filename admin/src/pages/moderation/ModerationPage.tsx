import React from 'react';
import { ShieldAlert } from 'lucide-react';

export const ModerationPage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-3">
        <ShieldAlert className="w-6 h-6 text-coral-500" />
        <h2 className="text-2xl font-bold text-indigo-950">Safety Moderation Queue</h2>
      </div>
      <div className="bg-white p-6 rounded-xl border border-slate-200">
        <p className="text-slate-600">
          Scaffolded moderation queue. Flags suspicious message requests, scam patterns, and external platform redirect links.
        </p>
      </div>
    </div>
  );
};
