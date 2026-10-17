export interface ApiError {
  error: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
}
export interface User {
  id: string;
  email: string;
  full_name: string;
  display_name?: string;
  headline?: string;
  avatar_url?: string;
  roles: string[];
  badges?: string[];
  verification_level: string;
  trust_level: string;
  status: string;
  institution_id?: number;
  institution?: {
    id: number;
    name: string;
  };
}

export interface ModerationItem {
  id: string;
  type: 'report' | 'flagged_message' | 'restricted_account';
  status: 'pending' | 'resolved' | 'dismissed';
  severity: 'high' | 'medium' | 'low';
  reporter_id: string | null;
  target_user_id: string | null;
  reason: string;
  details: string | null;
  created_at: string;
}

export interface ModerationQueueResponse {
  items: ModerationItem[];
  next_cursor: string | null;
}

export interface VerificationQueueItem {
  id: string;
  user_id: string;
  user_email: string;
  user_full_name: string;
  kind: 'alumnus' | 'employer' | 'expert' | 'faculty';
  evidence_text: string;
  evidence_urls: string[];
  company_name?: string | null;
  company_registration?: string | null;
  status: string;
  created_at: string;
}

export interface VerificationQueueResponse {
  items: VerificationQueueItem[];
  next_cursor: string | null;
}

export interface ApprovedMembersUploadResponse {
  total_rows: number;
  inserted: number;
  duplicates_skipped: number;
  errors: string[];
}

export interface AuditLogItem {
  id: string;
  actor_id: string;
  actor_email: string;
  action: string;
  target_type: string;
  target_id: string;
  institution_id?: number | null;
  details: Record<string, unknown>;
  created_at: string;
}

export interface AuditLogResponse {
  items: AuditLogItem[];
  next_cursor: string | null;
}

export const API_BASE_URL = (import.meta as any).env?.VITE_API_URL || 'http://localhost:8000';

let isRefreshing = false;
let refreshSubscribers: ((token: string) => void)[] = [];

function onTokenRefreshed(newToken: string) {
  refreshSubscribers.forEach((cb) => cb(newToken));
  refreshSubscribers = [];
}

export async function fetchApi<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem('warmpath_admin_token');
  const isFormData = options.body instanceof FormData;

  const headers: HeadersInit = {
    ...(isFormData ? {} : { 'Content-Type': 'application/json' }),
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  };

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

  // Handle 401 Unauthorized with automatic token refresh
  if (response.status === 401 && !endpoint.includes('/auth/refresh') && !endpoint.includes('/auth/verify-otp')) {
    const refreshToken = localStorage.getItem('warmpath_admin_refresh_token');
    if (!refreshToken) {
      localStorage.removeItem('warmpath_admin_token');
      localStorage.removeItem('warmpath_admin_refresh_token');
      localStorage.removeItem('warmpath_admin_user');
      window.dispatchEvent(new Event('warmpath_admin_logout'));
      throw { error: { code: 'unauthorized', message: 'Session expired' } };
    }

    if (!isRefreshing) {
      isRefreshing = true;
      try {
        const refreshRes = await fetch(`${API_BASE_URL}/auth/refresh`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ refresh_token: refreshToken }),
        });

        if (refreshRes.ok) {
          const refreshData = await refreshRes.json();
          localStorage.setItem('warmpath_admin_token', refreshData.access_token);
          localStorage.setItem('warmpath_admin_refresh_token', refreshData.refresh_token);
          isRefreshing = false;
          onTokenRefreshed(refreshData.access_token);

          // Retry the original request with new token
          const retryHeaders = {
            ...headers,
            Authorization: `Bearer ${refreshData.access_token}`,
          };
          const retryRes = await fetch(`${API_BASE_URL}${endpoint}`, {
            ...options,
            headers: retryHeaders,
          });
          if (!retryRes.ok) {
            const err = await retryRes.json().catch(() => ({
              error: { code: 'unknown_error', message: retryRes.statusText },
            }));
            throw err;
          }
          return retryRes.json();
        } else {
          throw new Error('Refresh failed');
        }
      } catch {
        isRefreshing = false;
        localStorage.removeItem('warmpath_admin_token');
        localStorage.removeItem('warmpath_admin_refresh_token');
        localStorage.removeItem('warmpath_admin_user');
        window.dispatchEvent(new Event('warmpath_admin_logout'));
        throw { error: { code: 'unauthorized', message: 'Session expired' } };
      }
    } else {
      // Queue request while refresh is in flight
      return new Promise<T>((resolve, reject) => {
        refreshSubscribers.push(async (newToken: string) => {
          try {
            const retryHeaders = {
              ...headers,
              Authorization: `Bearer ${newToken}`,
            };
            const retryRes = await fetch(`${API_BASE_URL}${endpoint}`, {
              ...options,
              headers: retryHeaders,
            });
            if (!retryRes.ok) {
              const err = await retryRes.json().catch(() => ({
                error: { code: 'unknown_error', message: retryRes.statusText },
              }));
              reject(err);
            } else {
              resolve(await retryRes.json());
            }
          } catch (e) {
            reject(e);
          }
        });
      });
    }
  }

  if (!response.ok) {
    const errorData: ApiError = await response.json().catch(() => ({
      error: { code: 'unknown_error', message: response.statusText },
    }));
    throw errorData;
  }

  return response.json();
}

export interface PublicConfig {
  demo_profile: boolean;
  test_mode: boolean;
  windows: {
    dispute_minutes: number;
    no_reply_minutes: number;
    min_call_seconds: number;
  };
  band_thresholds?: {
    trusted_min_sessions: number;
    top_rated_min_sessions: number;
    lowered: boolean;
  };
}

export async function fetchPublicConfig(): Promise<PublicConfig> {
  return fetchApi<PublicConfig>('/config/public');
}

