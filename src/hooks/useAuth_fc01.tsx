import React, { useState, useEffect, createContext, useContext, ReactNode } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase_fc01 } from '@/integrations/supabase/client_fc01';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signUp: (email: string, password: string, fullName?: string) => Promise<{ error: Error | null }>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<{ error: Error | null }>;
  updatePassword: (newPassword: string) => Promise<{ error: Error | null }>;
  selectedCompany: string | null;
  selectCompany: (empresaId: string) => void;
}

const globalForAuth = globalThis as unknown as {
  __APP_AUTH_CONTEXT__?: React.Context<AuthContextType | undefined>;
};

const AuthContext =
  globalForAuth.__APP_AUTH_CONTEXT__ ??
  (globalForAuth.__APP_AUTH_CONTEXT__ = createContext<AuthContextType | undefined>(undefined));

export function AuthProvider_fc01({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedCompany, setSelectedCompany] = useState<string | null>(() => {
    // Try to get selected company from localStorage
    if (typeof window !== 'undefined') {
      return localStorage.getItem('selectedCompany');
    }
    return null;
  });

  useEffect(() => {
    // Get initial session
    supabase_fc01.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);
    });

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase_fc01.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase_fc01.auth.signInWithPassword({
      email,
      password,
    });
    return { error };
  };

  const signUp = async (email: string, password: string, fullName?: string) => {
    const { error } = await supabase_fc01.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
        },
      },
    });
    return { error };
  };

  const signOut = async () => {
    await supabase_fc01.auth.signOut();
    setSelectedCompany(null);
    localStorage.removeItem('selectedCompany');
  };

  const resetPassword = async (email: string) => {
    const { error } = await supabase_fc01.auth.resetPasswordForEmail(email);
    return { error };
  };

  const updatePassword = async (newPassword: string) => {
    const { error } = await supabase_fc01.auth.updateUser({
      password: newPassword,
    });
    return { error };
  };

  const selectCompany = (empresaId: string) => {
    setSelectedCompany(empresaId);
    localStorage.setItem('selectedCompany', empresaId);
  };

  const value: AuthContextType = {
    user,
    session,
    loading,
    signIn,
    signUp,
    signOut,
    resetPassword,
    updatePassword,
    selectedCompany,
    selectCompany,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth_fc01() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth_fc01 must be used within an AuthProvider_fc01');
  }
  return context;
}