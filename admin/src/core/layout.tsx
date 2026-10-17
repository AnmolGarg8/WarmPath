import React from 'react';
import { Link, Outlet, useLocation } from 'react-router-dom';
import { ShieldCheck, UserCheck, LayoutDashboard, Ticket, LogOut, Building, User as UserIcon } from 'lucide-react';
import { AuthProvider, useAuth, AdminLoginPage, NoAccessPage } from './auth';
import { ToastProvider } from './toast';

const LayoutContent: React.FC = () => {
  const location = useLocation();
  const { user, isLoading, hasAccess, logout } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen bg-brand-surface flex flex-col items-center justify-center">
        <div className="w-10 h-10 border-4 border-brand-indigo/20 border-t-brand-coral rounded-full animate-spin mb-4" />
        <p className="text-sm font-medium text-brand-slate">Loading WarmPath Administration...</p>
      </div>
    );
  }

  if (!user) {
    return <AdminLoginPage />;
  }

  if (!hasAccess) {
    return <NoAccessPage />;
  }

  const navItems = [
    { label: 'Dashboard', path: '/', icon: LayoutDashboard },
    { label: 'Moderation Queue', path: '/moderation', icon: ShieldCheck },
    { label: 'Verification Queue', path: '/verification', icon: UserCheck },
    { label: 'Seats & Grants', path: '/seats', icon: Ticket },
  ];

  const primaryRole = user.roles.find((r) =>
    ['platform_admin', 'institution_admin', 'moderator'].includes(r)
  ) || user.roles[0] || 'admin';

  const roleLabel =
    primaryRole === 'platform_admin'
      ? 'Platform Admin'
      : primaryRole === 'institution_admin'
      ? 'Institution Admin'
      : 'Moderator';

  return (
    <div className="flex min-h-screen bg-brand-surface font-sans">
      {/* Sidebar */}
      <aside className="w-64 bg-brand-dark text-white flex flex-col shrink-0">
        <div className="p-6 border-b border-brand-indigo/60">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-brand-coral flex items-center justify-center font-black text-white text-base">
              W
            </div>
            <div>
              <h1 className="text-lg font-bold tracking-tight text-white leading-tight">WarmPath</h1>
              <p className="text-[10px] uppercase tracking-wider text-brand-slate font-semibold">
                Trust & Moderation
              </p>
            </div>
          </div>
        </div>

        <nav className="flex-1 p-4 space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = location.pathname === item.path || (item.path !== '/' && location.pathname.startsWith(item.path));
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${
                  active
                    ? 'bg-brand-indigo text-white shadow-sm'
                    : 'text-brand-slate hover:text-white hover:bg-brand-indigo/40'
                }`}
              >
                <Icon className={`w-5 h-5 ${active ? 'text-brand-coral' : 'text-brand-slate'}`} />
                {item.label}
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-brand-indigo/40">
          <div className="p-3 rounded-xl bg-brand-indigo/30 border border-brand-indigo/50">
            <div className="flex items-center gap-2 mb-1">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span className="text-xs font-semibold text-white uppercase tracking-wider">Pilot Target</span>
            </div>
            <p className="text-[11px] text-brand-slate leading-relaxed">
              24h SLA response window for reports & verifications.
            </p>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Top Bar */}
        <header className="h-16 bg-white border-b border-brand-slate/10 px-8 flex items-center justify-between sticky top-0 z-30 shadow-sm">
          <div className="flex items-center gap-3">
            {user.institution ? (
              <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-brand-surface text-brand-dark text-xs font-semibold border border-brand-slate/15">
                <Building className="w-3.5 h-3.5 text-brand-indigo" />
                <span>{user.institution.name}</span>
              </div>
            ) : user.institution_id ? (
              <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-brand-surface text-brand-dark text-xs font-semibold border border-brand-slate/15">
                <Building className="w-3.5 h-3.5 text-brand-indigo" />
                <span>Institution #{user.institution_id}</span>
              </div>
            ) : null}

            <span className="px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider bg-brand-teal/15 text-brand-teal border border-brand-teal/30">
              {roleLabel}
            </span>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex items-center gap-3 text-right">
              <div className="hidden sm:block">
                <p className="text-sm font-semibold text-brand-dark leading-tight">
                  {user.full_name || user.display_name || 'Admin'}
                </p>
                <p className="text-xs text-brand-slate">{user.email}</p>
              </div>
              <div className="w-9 h-9 rounded-xl bg-brand-surface border border-brand-slate/20 flex items-center justify-center text-brand-dark font-bold text-sm">
                <UserIcon className="w-4 h-4 text-brand-slate" />
              </div>
            </div>

            <button
              onClick={() => logout()}
              title="Logout"
              className="p-2 text-brand-slate hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
            >
              <LogOut className="w-5 h-5" />
            </button>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 p-8 overflow-y-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export const AdminLayout: React.FC = () => {
  return (
    <ToastProvider>
      <AuthProvider>
        <LayoutContent />
      </AuthProvider>
    </ToastProvider>
  );
};
