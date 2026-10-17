import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { User, fetchApi } from './api';
import { ShieldAlert, LogOut, ArrowRight, CheckCircle2, Lock } from 'lucide-react';
import { useToast } from './toast';

interface AuthContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  hasAccess: boolean;
  requestOtp: (email: string) => Promise<void>;
  verifyOtp: (email: string, code: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const ALLOWED_ADMIN_ROLES = ['moderator', 'institution_admin', 'platform_admin'] as const;

export function checkUserAccess(u: User | null): boolean {
  if (!u || !u.roles) return false;
  return u.roles.some((r) => (ALLOWED_ADMIN_ROLES as readonly string[]).includes(r));
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(() => {
    const raw = localStorage.getItem('warmpath_admin_user');
    if (!raw) return null;
    try {
      return JSON.parse(raw);
    } catch {
      return null;
    }
  });
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('warmpath_admin_token'));
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const { showToast } = useToast();


  const fetchCurrentUser = useCallback(async () => {
    const savedToken = localStorage.getItem('warmpath_admin_token');
    if (!savedToken) {
      setUser(null);
      setIsLoading(false);
      return;
    }

    try {
      const userData = await fetchApi<User>('/me');
      setUser(userData);
      localStorage.setItem('warmpath_admin_user', JSON.stringify(userData));
    } catch {
      setUser(null);
      localStorage.removeItem('warmpath_admin_token');
      localStorage.removeItem('warmpath_admin_refresh_token');
      localStorage.removeItem('warmpath_admin_user');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchCurrentUser();

    const handleLogoutEvent = () => {
      setUser(null);
      setToken(null);
    };

    window.addEventListener('warmpath_admin_logout', handleLogoutEvent);
    return () => window.removeEventListener('warmpath_admin_logout', handleLogoutEvent);
  }, [fetchCurrentUser]);

  const requestOtp = async (email: string) => {
    await fetchApi('/auth/request-otp', {
      method: 'POST',
      body: JSON.stringify({ email: email.trim().toLowerCase() }),
    });
    showToast('A 6-digit OTP has been sent to your administrator email.', 'success');
  };

  const verifyOtp = async (email: string, code: string) => {
    const data = await fetchApi<{
      access_token: string;
      refresh_token: string;
      user: User;
    }>('/auth/verify-otp', {
      method: 'POST',
      body: JSON.stringify({ email: email.trim().toLowerCase(), code: code.trim() }),
    });

    localStorage.setItem('warmpath_admin_token', data.access_token);
    localStorage.setItem('warmpath_admin_refresh_token', data.refresh_token);
    localStorage.setItem('warmpath_admin_user', JSON.stringify(data.user));

    setToken(data.access_token);
    setUser(data.user);

    if (checkUserAccess(data.user)) {
      showToast(`Welcome back, ${data.user.full_name || 'Admin'}!`, 'success');
    } else {
      showToast('Login successful, but your account lacks moderation privileges.', 'warning');
    }
  };

  const logout = async () => {
    try {
      await fetchApi('/auth/logout', { method: 'POST' });
    } catch {
      // Ignore network errors during logout
    } finally {
      localStorage.removeItem('warmpath_admin_token');
      localStorage.removeItem('warmpath_admin_refresh_token');
      localStorage.removeItem('warmpath_admin_user');
      setUser(null);
      setToken(null);
      showToast('Logged out of admin panel.', 'info');
    }
  };

  const hasAccess = checkUserAccess(user);

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isLoading,
        hasAccess,
        requestOtp,
        verifyOtp,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AdminLoginPage: React.FC = () => {
  const { requestOtp, verifyOtp } = useAuth();
  const [step, setStep] = useState<'email' | 'otp'>('email');
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleRequestOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !email.includes('@')) {
      setError('Please enter a valid administrator email.');
      return;
    }

    setIsSubmitting(true);
    setError(null);
    try {
      await requestOtp(email);
      setStep('otp');
    } catch (err: any) {
      setError(err?.error?.message || 'Failed to send OTP. Please check your domain registration.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!code || code.length < 6) {
      setError('Please enter the complete 6-digit code.');
      return;
    }

    setIsSubmitting(true);
    setError(null);
    try {
      await verifyOtp(email, code);
    } catch (err: any) {
      setError(err?.error?.message || 'Invalid or expired code. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-brand-surface flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-xl border border-brand-slate/10 p-8">
        <div className="flex items-center gap-3 mb-6">
          <div className="w-10 h-10 rounded-xl bg-brand-indigo/10 flex items-center justify-center text-brand-indigo font-bold">
            <Lock className="w-5 h-5 text-brand-indigo" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-brand-dark">WarmPath Admin</h1>
            <p className="text-xs text-brand-slate">Institutional Trust & Moderation</p>
          </div>
        </div>

        {error && (
          <div className="mb-6 p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-sm">
            {error}
          </div>
        )}

        {step === 'email' ? (
          <form onSubmit={handleRequestOtp} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-brand-slate mb-2">
                Administrator Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="e.g. admin@vips.edu"
                className="w-full px-4 py-3 rounded-xl border border-brand-slate/20 focus:outline-none focus:ring-2 focus:ring-brand-coral bg-brand-surface/40 text-brand-dark text-sm"
                required
              />
            </div>
            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-brand-coral hover:bg-brand-coral/90 text-white font-semibold text-sm transition-colors disabled:opacity-50"
            >
              {isSubmitting ? (
                'Requesting OTP...'
              ) : (
                <>
                  Continue with OTP <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>
        ) : (
          <form onSubmit={handleVerifyOtp} className="space-y-4">
            <div className="p-3 bg-brand-surface rounded-xl text-xs text-brand-slate flex items-center justify-between">
              <span>Code sent to: <strong className="text-brand-dark">{email}</strong></span>
              <button
                type="button"
                onClick={() => setStep('email')}
                className="text-brand-coral font-medium hover:underline"
              >
                Change
              </button>
            </div>
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-brand-slate mb-2">
                6-Digit Verification Code
              </label>
              <input
                type="text"
                maxLength={6}
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
                placeholder="123456"
                className="w-full text-center tracking-[0.5em] text-2xl font-bold px-4 py-3 rounded-xl border border-brand-slate/20 focus:outline-none focus:ring-2 focus:ring-brand-coral bg-brand-surface/40 text-brand-dark"
                required
                autoFocus
              />
            </div>
            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-brand-coral hover:bg-brand-coral/90 text-white font-semibold text-sm transition-colors disabled:opacity-50"
            >
              {isSubmitting ? (
                'Verifying...'
              ) : (
                <>
                  Sign In to Admin Panel <CheckCircle2 className="w-4 h-4" />
                </>
              )}
            </button>
          </form>
        )}
      </div>
    </div>
  );
};

export const NoAccessPage: React.FC = () => {
  const { user, logout } = useAuth();

  return (
    <div className="min-h-screen bg-brand-surface flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-xl border border-brand-slate/10 p-8 text-center">
        <div className="w-16 h-16 rounded-2xl bg-rose-50 text-rose-600 flex items-center justify-center mx-auto mb-4">
          <ShieldAlert className="w-8 h-8" />
        </div>
        <h1 className="text-xl font-bold text-brand-dark mb-2">Access Restricted</h1>
        <p className="text-sm text-brand-slate mb-6">
          Your account ({user?.email}) is authenticated, but does not hold an authorized moderation role
          (<strong>moderator</strong>, <strong>institution_admin</strong>, or <strong>platform_admin</strong>).
        </p>
        <div className="p-3 bg-brand-surface rounded-xl text-xs text-brand-slate mb-6 text-left">
          <strong>Assigned Roles:</strong> {user?.roles?.length ? user.roles.join(', ') : 'None'}
        </div>
        <button
          onClick={logout}
          className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-brand-indigo hover:bg-brand-indigo/90 text-white font-semibold text-sm transition-colors"
        >
          <LogOut className="w-4 h-4" /> Sign In with Different Account
        </button>
      </div>
    </div>
  );
};
