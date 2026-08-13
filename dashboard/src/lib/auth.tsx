'use client';

import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { api, User } from './api';

interface AuthState {
  user: User | null;
  loading: boolean;
  login: (email: string, pin: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = api.getToken();
    if (token) {
      try {
        const payload = JSON.parse(atob(token.split('.')[1]));
        if (payload.exp * 1000 > Date.now()) {
          setUser({ id: payload.userId, name: '', role: payload.role });
        } else {
          api.setToken(null);
        }
      } catch {
        api.setToken(null);
      }
    }
    setLoading(false);
  }, []);

  const login = async (email: string, pin: string) => {
    const res = await api.post<{ token: string; user: User }>('/api/auth/login', { email, pin });
    api.setToken(res.token);
    setUser(res.user);
  };

  const logout = () => {
    api.setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be inside AuthProvider');
  return ctx;
}
