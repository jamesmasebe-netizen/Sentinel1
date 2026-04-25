import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, onAuthStateChanged } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db, signInWithGoogle, logOut } from '../lib/firebase';

interface UserProfile {
  uid: string;
  email: string | null;
  fullName?: string;
  role: 'admin' | 'executive' | 'safety_manager' | 'contractor' | 'employee';
  siteId?: string;
}

interface AuthContextType {
  user: User | null;
  profile: UserProfile | null;
  loading: boolean;
  signIn: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);
      if (currentUser) {
        const userDoc = await getDoc(doc(db, 'users', currentUser.uid));
        if (userDoc.exists()) {
          const data = userDoc.data();
          // Automatically grant executive role to the app owner for preview purposes
          if (currentUser.email === 'JAMESMASEBE@gmail.com') {
            data.role = 'executive';
          }
          setProfile({ uid: currentUser.uid, email: currentUser.email, ...data } as UserProfile);
        } else {
          // Default role for new users
          const defaultRole = currentUser.email === 'JAMESMASEBE@gmail.com' ? 'executive' : 'employee';
          setProfile({ uid: currentUser.uid, email: currentUser.email, role: defaultRole });
        }
      } else {
        setProfile(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return (
    <AuthContext.Provider value={{ user, profile, loading, signIn: signInWithGoogle, signOut: logOut }}>
      {!loading && children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
