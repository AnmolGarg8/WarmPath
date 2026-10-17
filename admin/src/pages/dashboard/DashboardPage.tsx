import React from 'react';
import { LayoutDashboard, TrendingUp, Users, CheckCircle } from 'lucide-react';

export const DashboardPage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-3">
        <LayoutDashboard className="w-6 h-6 text-indigo-900" />
        <h2 className="text-2xl font-bold text-indigo-950">Institution Intelligence Dashboard</h2>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-xl border border-slate-200">
          <div className="flex items-center justify-between">
            <span className="text-sm text-slate-500">Active Students</span>
            <Users className="w-5 h-5 text-indigo-900" />
          </div>
          <p className="text-3xl font-bold text-indigo-950 mt-2">--</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-slate-200">
          <div className="flex items-center justify-between">
            <span className="text-sm text-slate-500">Mentorship Sessions</span>
            <CheckCircle className="w-5 h-5 text-teal-500" />
          </div>
          <p className="text-3xl font-bold text-indigo-950 mt-2">--</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-slate-200">
          <div className="flex items-center justify-between">
            <span className="text-sm text-slate-500">Avg Rating</span>
            <TrendingUp className="w-5 h-5 text-amber-500" />
          </div>
          <p className="text-3xl font-bold text-indigo-950 mt-2">--</p>
        </div>
      </div>
    </div>
  );
};
