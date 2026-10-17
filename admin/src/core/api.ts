export interface ApiError {
  error: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
}

export const API_BASE_URL = (import.meta as unknown as { env?: Record<string, string> }).env?.VITE_API_URL || 'http://localhost:8000';

export async function fetchApi<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem('warmpath_admin_token');
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  };

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

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

