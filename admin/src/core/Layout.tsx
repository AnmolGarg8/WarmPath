import React from 'react';
import { NavLink, Outlet } from 'react-router-dom';
import { ShieldAlert, UserCheck, LayoutDashboard, Users, Shield } from 'lucide-react';

export const Layout: React.FC = () => {
  return (
    <div className="flex h-screen bg-surface">
      {/* Sidebar */}
      <aside className="w-64 bg-indigo-950 text-white flex flex-col">
        <div className="p-6 border-b border-indigo-900 flex items-center space-x-3">
          <div className="p-2 bg-coral-500 rounded-lg text-white font-bold">
            WP
          </div>
          <div>
            <h1 className="font-bold text-lg leading-tight">WarmPath</h1>
            <p className="text-xs text-slate-400">Admin Intelligence</p>
          </div>
        </div>

        <nav className="flex-1 p-4 space-y-1">
          <NavLink
            to="/dashboard"
            className={({ isActive }) =>
              `flex items-center px-4 py-3 rounded-lg text-sm font-medium transition-colors ${
                isActive ? 'bg-indigo-900 text-coral-500' : 'text-slate-300 hover:bg-indigo-900/50'
              }`
            }
          >
            <LayoutDashboard className="w-5 h-5 mr-3" />
            Dashboard
          </NavLink>

          <NavLink
            to="/verification"
            className={({ isActive }) =>
              `flex items-center px-4 py-3 rounded-lg text-sm font-medium transition-colors ${
                isActive ? 'bg-indigo-900 text-coral-500' : 'text-slate-300 hover:bg-indigo-900/50'
              }`
            }
          >
            <UserCheck className="w-5 h-5 mr-3" />
            Verification Queue
          </NavLink>

          <NavLink
            to="/moderation"
            className={({ isActive }) =>
              `flex items-center px-4 py-3 rounded-lg text-sm font-medium transition-colors ${
                isActive ? 'bg-indigo-900 text-coral-500' : 'text-slate-300 hover:bg-indigo-900/50'
              }`
            }
          >
            <ShieldAlert className="w-5 h-5 mr-3" />
            Moderation & Safety
          </NavLink>

          <NavLink
            to="/seats"
            className={({ isActive }) =>
              `flex items-center px-4 py-3 rounded-lg text-sm font-medium transition-colors ${
                isActive ? 'bg-indigo-900 text-coral-500' : 'text-slate-300 hover:bg-indigo-900/50'
              }`
            }
          >
            <Users className="w-5 h-5 mr-3" />
            Sponsored Seats
          </NavLink>
        </nav>

        <div className="p-4 border-t border-indigo-900">
          <div className="flex items-center space-x-3 text-xs text-slate-400">
            <Shield className="w-4 h-4 text-teal-500" />
            <span>7-Layer Guard Active</span>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        <header className="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-8">
          <div className="text-sm font-semibold text-indigo-950">
            Institution & Platform Administration
          </div>
          <div className="text-xs px-2.5 py-1 rounded bg-amber-100 text-amber-800 font-medium">
            Test Mode
          </div>
        </header>

        <main className="flex-1 overflow-y-auto p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
