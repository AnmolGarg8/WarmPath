import React from 'react';
import { Link, Outlet, useLocation } from 'react-router-dom';
import { ShieldCheck, UserCheck, LayoutDashboard, Ticket } from 'lucide-react';

export const AdminLayout: React.FC = () => {
  const location = useLocation();

  const navItems = [
    { label: 'Dashboard', path: '/', icon: LayoutDashboard },
    { label: 'Moderation', path: '/moderation', icon: ShieldCheck },
    { label: 'Verification', path: '/verification', icon: UserCheck },
    { label: 'Seats & Grants', path: '/seats', icon: Ticket },
  ];

  return (
    <div className="flex min-h-screen bg-brand-surface font-sans">
      <aside className="w-64 bg-brand-dark text-white flex flex-col">
        <div className="p-6 border-b border-brand-indigo">
          <h1 className="text-xl font-bold tracking-tight text-brand-coral">WarmPath</h1>
          <p className="text-xs text-brand-slate">Institutional Admin Panel</p>
        </div>
        <nav className="flex-1 p-4 space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${
                  active
                    ? 'bg-brand-indigo text-white'
                    : 'text-brand-slate hover:text-white hover:bg-brand-indigo/50'
                }`}
              >
                <Icon className="w-5 h-5" />
                {item.label}
              </Link>
            );
          })}
        </nav>
      </aside>
      <main className="flex-1 p-8 overflow-y-auto">
        <Outlet />
      </main>
    </div>
  );
};
