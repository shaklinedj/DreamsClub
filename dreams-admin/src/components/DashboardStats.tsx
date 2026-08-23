
import React, { useEffect, useState } from 'react';
import { collection, getCountFromServer, query, where } from 'firebase/firestore';
import { db } from '../lib/firebase';

export default function DashboardStats() {
    const [stats, setStats] = useState({
        users: 0,
        games: 0,
        posts: 0,
        claimedPrizes: 0
    });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStats = async () => {
            try {
                // Users Count
                const usersColl = collection(db, 'users');
                const usersSnapshot = await getCountFromServer(usersColl);

                // Active Games Count
                const gamesColl = collection(db, 'game_configs');
                const qGames = query(gamesColl, where("isActive", "==", true));
                const gamesSnapshot = await getCountFromServer(qGames);

                // Posts Count
                const postsColl = collection(db, 'posts');
                const postsSnapshot = await getCountFromServer(postsColl);

                // Claimed Prizes Count
                const prizesColl = collection(db, 'user_prizes');
                const qPrizes = query(prizesColl, where("status", "==", "cobrado"));
                const prizesSnapshot = await getCountFromServer(qPrizes);

                setStats({
                    users: usersSnapshot.data().count,
                    games: gamesSnapshot.data().count,
                    posts: postsSnapshot.data().count,
                    claimedPrizes: prizesSnapshot.data().count
                });
            } catch (error) {
                console.error("Error fetching stats:", error);
            } finally {
                setLoading(false);
            }
        };

        fetchStats();
    }, []);

    if (loading) {
        return <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 animate-pulse">
            {[1, 2, 3, 4].map(i => <div key={i} className="bg-slate-800 h-32 rounded-2xl"></div>)}
        </div>;
    }

    return (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700">
                <h3 className="text-slate-400 text-sm font-medium mb-1">Usuarios Totales</h3>
                <p className="text-3xl font-bold text-white">{stats.users}</p>
                <div className="mt-2 text-xs text-green-400 font-medium">
                    En base de datos
                </div>
            </div>

            <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700">
                <h3 className="text-slate-400 text-sm font-medium mb-1">Juegos Activos</h3>
                <p className="text-3xl font-bold text-white">{stats.games}</p>
                <div className="mt-2 text-xs text-purple-400 font-medium">
                    Configuración live
                </div>
            </div>

            <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700">
                <h3 className="text-slate-400 text-sm font-medium mb-1">Premios Cobrados</h3>
                <p className="text-3xl font-bold text-white">{stats.claimedPrizes}</p>
                <div className="mt-2 text-xs text-green-400 font-medium">
                    Canjes verificados
                </div>
            </div>

            <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700">
                <h3 className="text-slate-400 text-sm font-medium mb-1">Posts del Feed</h3>
                <p className="text-3xl font-bold text-white">{stats.posts}</p>
                <div className="mt-2 text-xs text-blue-400 font-medium">
                    Actividad social
                </div>
            </div>
        </div>
    );
}
