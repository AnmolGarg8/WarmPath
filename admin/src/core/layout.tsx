import React from 'react';
import { Link, Outlet, useLocation } from 'react-router-dom';
import { ShieldCheck, UserCheck, LayoutDashboard, Ticket, Clock } from 'lucide-react';
import { fetchPublicConfig, PublicConfig } from './api';

export const AdminLayout: React.FC = () => {
  const location = useLocation();
  const [config, setConfig] = React.useState<PublicConfig | null>(null);

  React.useEffect(() => {
    fetchPublicConfig()
      .then(setConfig)
      .catch(() => {
        // Fallback gracefully if API is offline
      });
  }, []);

  const navItems = [
    { label: 'Dashboard', path: '/', icon: LayoutDashboard },
    { label: 'Moderation', path: '/moderation', icon: ShieldCheck },
    { label: 'Verification', path: '/verification', icon: UserCheck },
    { label: 'Seats & Grants', path: '/seats', icon: Ticket },
  ];

  return (
    <div className="flex flex-col min-h-screen bg-brand-surface font-sans">
      {config?.demo_profile && (
        <div
          role="status"
          aria-label="Demo Profile Active"
          className="bg-amber-500 text-slate-950 px-4 py-2 text-xs font-semibold flex items-center justify-center gap-2 border-b border-amber-600 shadow-sm"
        >
          <Clock className="w-4 h-4 shrink-0" />
          <span>Demo profile: timers are shortened for the demo</span>
        </div>
      )}
      <div className="flex flex-1">
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
    </div>
  );
};
