import React, { useEffect, useState } from 'react';
import { onAuthStateChanged, signOut, type User } from 'firebase/auth';
import { auth } from '../lib/firebase';

export default function UserMenu() {
    const [user, setUser] = useState<User | null>(null);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
            setUser(currentUser);
        });
        return () => unsubscribe();
    }, []);

    const handleLogout = async () => {
        try {
            await signOut(auth);
            window.location.href = '/login';
        } catch (e) {
            console.error("Logout error:", e);
        }
    };

    if (!user) return null;

    return (
        <div className="p-4 border-t border-slate-700 flex items-center justify-between">
            <div className="flex items-center gap-3 overflow-hidden">
                <div className="w-10 h-10 rounded-full bg-purple-600 flex items-center justify-center font-bold text-white flex-shrink-0">
                    {user.email ? user.email.charAt(0).toUpperCase() : 'A'}
                </div>
                <div className="truncate">
                    <p className="text-sm font-medium text-white truncate">{user.displayName || 'Admin'}</p>
                    <p className="text-xs text-slate-400 truncate">{user.email}</p>
                </div>
            </div>
            <button
                onClick={handleLogout}
                title="Cerrar Sesión"
                className="p-2 rounded-lg text-slate-400 hover:text-red-400 hover:bg-slate-700 transition-colors"
            >
                🚪
            </button>
        </div>
    );
}
