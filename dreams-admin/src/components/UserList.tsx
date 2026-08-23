import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query } from 'firebase/firestore';
import { db } from '../lib/firebase';

interface UserItem {
    id: string;
    name?: string;
    email?: string;
    phoneNumber?: string;
    contactConsent?: boolean;
    wantsContact?: boolean;
    currentStreak?: number;
    streak?: number;
    longestStreak?: number;
    lastVisit?: any;
    isPresentToday?: boolean;
    tier?: string;
    createdAt?: any;
    rut?: string;
}

export default function UserList() {
    const [users, setUsers] = useState<UserItem[]>([]);
    const [prizes, setPrizes] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [streakFilter, setStreakFilter] = useState<'all' | 'active' | 'high' | 'vip' | 'none'>('all');
    const [presenceFilter, setPresenceFilter] = useState<'all' | 'today' | 'inactive5' | 'inactive10'>('all');
    const [consentOnly, setConsentOnly] = useState(false);

    useEffect(() => {
        const qUsers = query(collection(db, 'users'));
        const unsubscribeUsers = onSnapshot(qUsers, (snapshot) => {
            const list = snapshot.docs.map((d) => ({
                id: d.id,
                ...d.data()
            })) as UserItem[];
            setUsers(list);
            setLoading(false);
        }, (err) => {
            console.error("Error reading users:", err);
            setLoading(false);
        });

        const qPrizes = query(collection(db, 'user_prizes'));
        const unsubscribePrizes = onSnapshot(qPrizes, (snapshot) => {
            const list = snapshot.docs.map((d) => ({
                id: d.id,
                ...d.data()
            }));
            setPrizes(list);
        }, (err) => {
            console.error("Error reading prizes:", err);
        });

        return () => {
            unsubscribeUsers();
            unsubscribePrizes();
        };
    }, []);

    // Helper to check if lastVisit is strictly today in server/client time
    const isLastVisitToday = (lastVisit: any): boolean => {
        if (!lastVisit) return false;
        const date = lastVisit.toDate ? lastVisit.toDate() : new Date(lastVisit);
        const today = new Date();
        return date.getDate() === today.getDate() &&
               date.getMonth() === today.getMonth() &&
               date.getFullYear() === today.getFullYear();
    };

    // Calcular días sin asistir desde lastVisit
    const getDaysSinceLastVisit = (lastVisit: any): number => {
        if (!lastVisit) return 999;
        const date = lastVisit.toDate ? lastVisit.toDate() : new Date(lastVisit);
        const diffTime = Math.abs(new Date().getTime() - date.getTime());
        return Math.floor(diffTime / (1000 * 60 * 60 * 24));
    };

    // Mapear estadísticas de premios por usuario
    const getUserPrizeStats = (u: UserItem) => {
        const userPrizes = prizes.filter(p => 
            p.userId === u.id || 
            (u.email && p.userId === u.email) || 
            (u.rut && p.userId === u.rut)
        );
        const total = userPrizes.length;
        const claimed = userPrizes.filter(p => p.status === 'cobrado').length;
        return { total, claimed };
    };

    // Filtrar usuarios
    const filteredUsers = users.filter((u) => {
        // Búsqueda textual
        const name = (u.name || '').toLowerCase();
        const email = (u.email || '').toLowerCase();
        const phone = (u.phoneNumber || '').toLowerCase();
        const matchesSearch = name.includes(searchTerm.toLowerCase()) ||
                              email.includes(searchTerm.toLowerCase()) ||
                              phone.includes(searchTerm.toLowerCase());

        if (!matchesSearch) return false;

        // Filtro por racha
        const streak = u.currentStreak || u.streak || 0;
        if (streakFilter === 'active' && streak < 1) return false;
        if (streakFilter === 'high' && streak < 5) return false;
        if (streakFilter === 'vip' && streak < 10) return false;
        if (streakFilter === 'none' && streak > 0) return false;

        // Filtro por presencia / inactividad
        const daysInactive = getDaysSinceLastVisit(u.lastVisit);
        const visitedToday = isLastVisitToday(u.lastVisit);
        if (presenceFilter === 'today' && !visitedToday) return false;
        if (presenceFilter === 'inactive5' && daysInactive <= 5) return false;
        if (presenceFilter === 'inactive10' && daysInactive <= 10) return false;

        // Filtro por consentimiento de contacto
        if (consentOnly && !(u.contactConsent || u.wantsContact)) return false;

        return true;
    });

    if (loading) {
        return (
            <div className="flex justify-center items-center py-20 text-slate-400">
                <div className="w-8 h-8 border-4 border-purple-500 border-t-transparent rounded-full animate-spin mr-3"></div>
                Cargando usuarios...
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Tarjetas de Métricas Resumen */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="bg-slate-800 border border-slate-700 rounded-2xl p-5 shadow-lg">
                    <p className="text-xs font-semibold uppercase text-slate-400">Total Registrados</p>
                    <p className="text-3xl font-bold text-white mt-2">{users.length}</p>
                </div>

                <div className="bg-slate-800 border border-slate-700 rounded-2xl p-5 shadow-lg">
                    <p className="text-xs font-semibold uppercase text-slate-400">Con Racha Activa (≥1 Día)</p>
                    <p className="text-3xl font-bold text-emerald-400 mt-2">
                        {users.filter(u => (u.currentStreak || u.streak || 0) >= 1).length}
                    </p>
                </div>

                <div className="bg-slate-800 border border-slate-700 rounded-2xl p-5 shadow-lg">
                    <p className="text-xs font-semibold uppercase text-slate-400">Presentes Hoy</p>
                    <p className="text-3xl font-bold text-purple-400 mt-2">
                        {users.filter(u => isLastVisitToday(u.lastVisit)).length}
                    </p>
                </div>

                <div className="bg-slate-800 border border-slate-700 rounded-2xl p-5 shadow-lg">
                    <p className="text-xs font-semibold uppercase text-slate-400">Autorizan Contacto</p>
                    <p className="text-3xl font-bold text-amber-400 mt-2">
                        {users.filter(u => u.contactConsent).length}
                    </p>
                </div>
            </div>

            {/* Barra de Filtros y Búsqueda */}
            <div className="bg-slate-800 border border-slate-700 rounded-2xl p-6 shadow-xl space-y-4">
                <div className="flex flex-col md:flex-row gap-4 justify-between items-center">
                    <div className="w-full md:w-1/3 relative">
                        <input
                             type="text"
                             placeholder="🔍 Buscar por nombre, email o teléfono..."
                             value={searchTerm}
                             onChange={(e) => setSearchTerm(e.target.value)}
                             className="w-full px-4 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:border-purple-500 text-sm"
                        />
                    </div>

                    <div className="flex flex-wrap items-center gap-3 w-full md:w-auto">
                        {/* Selector de Racha */}
                        <select
                            value={streakFilter}
                            onChange={(e) => setStreakFilter(e.target.value as any)}
                            className="px-3 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-sm text-slate-200 focus:outline-none focus:border-purple-500"
                        >
                            <option value="all">🔥 Todas las Rachas</option>
                            <option value="active">🔥 Activa (≥1 Día)</option>
                            <option value="high">⚡ Racha Alta (≥5 Días)</option>
                            <option value="vip">👑 Racha VIP (≥10 Días)</option>
                            <option value="none">❄️ Sin Racha (0 Días)</option>
                        </select>

                        {/* Selector de Asistencia / Presencia */}
                        <select
                            value={presenceFilter}
                            onChange={(e) => setPresenceFilter(e.target.value as any)}
                            className="px-3 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-sm text-slate-200 focus:outline-none focus:border-purple-500"
                        >
                            <option value="all">📍 Toda la Asistencia</option>
                            <option value="today">🏢 Presente Hoy en Casino</option>
                            <option value="inactive5">⏳ Inactivo (&gt;5 Días sin asistir)</option>
                            <option value="inactive10">⚠️ Inactivo (&gt;10 Días sin asistir)</option>
                        </select>

                        {/* Checkbox Permiso de Contacto */}
                        <label className="flex items-center gap-2 cursor-pointer bg-slate-900 px-3 py-2 rounded-xl border border-slate-700 text-xs text-slate-300">
                            <input
                                type="checkbox"
                                checked={consentOnly}
                                onChange={(e) => setConsentOnly(e.target.checked)}
                                className="rounded text-purple-600 focus:ring-purple-500 bg-slate-800 border-slate-700"
                            />
                            <span>Permite Contacto</span>
                        </label>
                    </div>
                </div>
            </div>

            {/* Tabla de Usuarios */}
            <div className="bg-slate-800 border border-slate-700 rounded-2xl overflow-hidden shadow-xl">
                <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm text-slate-300">
                        <thead className="bg-slate-900/50 text-xs uppercase text-slate-400 border-b border-slate-700">
                            <tr>
                                <th className="px-6 py-4">Usuario</th>
                                <th className="px-6 py-4">Contacto</th>
                                <th className="px-6 py-4">Racha Actual / Récord</th>
                                <th className="px-6 py-4">Presencia / Última Visita</th>
                                <th className="px-6 py-4">Premios</th>
                                <th className="px-6 py-4">Permite Contacto</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-700/50">
                            {filteredUsers.length === 0 ? (
                                <tr>
                                    <td colSpan={6} className="px-6 py-12 text-center text-slate-500">
                                        No se encontraron usuarios con los filtros seleccionados.
                                    </td>
                                </tr>
                            ) : (
                                filteredUsers.map((u) => {
                                    const streak = u.currentStreak || u.streak || 0;
                                    const longest = u.longestStreak || streak;
                                    const daysInactive = getDaysSinceLastVisit(u.lastVisit);
                                    const visitedToday = isLastVisitToday(u.lastVisit);
                                    const { total: totalPrizes, claimed: claimedPrizes } = getUserPrizeStats(u);

                                    return (
                                        <tr key={u.id} className="hover:bg-slate-750 transition-colors">
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-purple-600 to-pink-600 flex items-center justify-center font-bold text-white text-xs">
                                                        {(u.name || u.email || 'U').charAt(0).toUpperCase()}
                                                    </div>
                                                    <div>
                                                        <p className="font-semibold text-white">{u.name || 'Usuario Dreams'}</p>
                                                        <p className="text-xs text-slate-400">{u.id}</p>
                                                    </div>
                                                </div>
                                            </td>

                                            <td className="px-6 py-4">
                                                <p className="text-slate-200">{u.email || 'Sin correo'}</p>
                                                <p className="text-xs text-slate-400">{u.phoneNumber || 'Sin teléfono'}</p>
                                            </td>

                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-2">
                                                    <span className={`px-2.5 py-1 rounded-lg font-semibold text-xs ${
                                                        streak >= 10 ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30' :
                                                        streak >= 5 ? 'bg-purple-500/20 text-purple-300 border border-purple-500/30' :
                                                        streak >= 1 ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30' :
                                                        'bg-slate-700 text-slate-400'
                                                    }`}>
                                                        🔥 {streak} días
                                                    </span>
                                                    <span className="text-xs text-slate-500">Récord: {longest}d</span>
                                                </div>
                                            </td>

                                            <td className="px-6 py-4">
                                                {visitedToday ? (
                                                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                                                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                                                        En Casino Hoy
                                                    </span>
                                                ) : (
                                                    <span className={`text-xs ${daysInactive > 10 ? 'text-red-400 font-medium' : daysInactive > 5 ? 'text-amber-400' : 'text-slate-400'}`}>
                                                        {daysInactive === 999 ? 'Sin registros' : `Hace ${daysInactive} días`}
                                                    </span>
                                                )}
                                            </td>

                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-1.5">
                                                    <span className={`px-2 py-0.5 rounded text-xs font-semibold ${
                                                        claimedPrizes > 0 ? 'bg-green-500/20 text-green-300 border border-green-500/30' : 'bg-slate-700 text-slate-400'
                                                    }`}>
                                                        🏆 {claimedPrizes} cobrados
                                                    </span>
                                                    <span className="text-xs text-slate-500">
                                                        de {totalPrizes}
                                                    </span>
                                                </div>
                                            </td>

                                            <td className="px-6 py-4">
                                                {(u.contactConsent || u.wantsContact) ? (
                                                    <span className="inline-flex items-center gap-1 text-xs text-emerald-400 font-medium bg-emerald-500/10 px-2.5 py-1 rounded-lg border border-emerald-500/20">
                                                        ✓ Sí (Autorizado)
                                                    </span>
                                                ) : (
                                                    <span className="inline-flex items-center gap-1 text-xs text-slate-500 bg-slate-900 px-2.5 py-1 rounded-lg border border-slate-700">
                                                        ✕ No
                                                    </span>
                                                )}
                                            </td>
                                        </tr>
                                    );
                                })
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}
