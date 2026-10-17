import { useState, useEffect } from 'react';

export interface AdminUser {
  id: string;
  email: string;
  role: string;
}

export function useAuth() {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('warmpath_admin_token');
    if (token) {
      setUser({
        id: 'admin-1',
        email: 'admin@warmpath.org',
        role: 'platform_admin',
      });
    }
    setLoading(false);
  }, []);

  return { user, loading };
}
