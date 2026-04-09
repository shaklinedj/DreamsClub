
import React, { useEffect, useState } from 'react';
import { collection, onSnapshot, doc, updateDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';

interface GameConfig {
    gameId: string;
    title: string;
    isActive: boolean;
    type?: string;
    requiresLocation: boolean;
}

export default function GameList() {
    const [games, setGames] = useState<GameConfig[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const unsubscribe = onSnapshot(collection(db, 'game_configs'), (snapshot) => {
            const gamesData = snapshot.docs.map(doc => ({
                gameId: doc.id,
                ...doc.data()
            })) as GameConfig[];
            setGames(gamesData);
            setLoading(false);
        });

        return () => unsubscribe();
    }, []);

    const toggleGame = async (gameId: string, currentStatus: boolean) => {
        try {
            await updateDoc(doc(db, 'game_configs', gameId), {
                isActive: !currentStatus
            });
        } catch (error) {
            console.error("Error updating game:", error);
            alert("Error al actualizar el juego");
        }
    };

    const toggleLocation = async (gameId: string, currentStatus: boolean) => {
        try {
            await updateDoc(doc(db, 'game_configs', gameId), {
                requiresLocation: !currentStatus
            });
        } catch (error) {
            console.error("Error updating game location requirement:", error);
            alert("Error al actualizar requisito de ubicación");
        }
    };

    if (loading) {
        return <div className="text-white text-center p-10">Cargando juegos...</div>;
    }

    if (games.length === 0) {
        return <div className="text-slate-400 text-center p-10">No hay configuraciones de juegos encontradas. (Abre la App móvil para generarlas automáticamente).</div>;
    }

    return (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {games.map((game) => (
                <div key={game.gameId} className={`bg-slate-800 rounded-2xl border ${game.isActive ? 'border-green-500/30' : 'border-slate-700'} overflow-hidden group hover:border-purple-500/50 transition-colors`}>
                    <div className="p-6">
                        <div className="flex justify-between items-start mb-4">
                            <div className="flex items-center gap-4">
                                <div className={`w-12 h-12 rounded-xl flex items-center justify-center text-2xl ${game.gameId === 'dreams_match' ? 'bg-blue-500/10 text-blue-400' :
                                    game.gameId === 'slots' ? 'bg-yellow-500/10 text-yellow-400' :
                                        'bg-purple-500/10 text-purple-400'
                                    }`}>
                                    {game.gameId === 'dreams_match' ? '💎' :
                                        game.gameId === 'slots' ? '🎰' :
                                            game.gameId === 'roulette' ? '🎡' : '🃏'}
                                </div>
                                <div>
                                    <h3 className="text-white font-bold text-lg">{game.title}</h3>
                                    <p className="text-xs text-slate-400 uppercase tracking-wide">{game.gameId}</p>
                                </div>
                            </div>
                            <div className={`px-3 py-1 rounded-full text-xs font-bold transition-colors ${game.isActive ? 'bg-green-500/10 text-green-400' : 'bg-red-500/10 text-red-400'
                                }`}>
                                {game.isActive ? 'ACTIVO' : 'INACTIVO'}
                            </div>
                        </div>

                        <div className="grid grid-cols-2 gap-4 mb-6">
                            <div
                                onClick={() => toggleLocation(game.gameId, game.requiresLocation)}
                                className={`p-3 rounded-lg cursor-pointer transition-all border ${game.requiresLocation
                                    ? 'bg-blue-500/10 border-blue-500/30 hover:bg-blue-500/20'
                                    : 'bg-slate-900/50 border-transparent hover:bg-slate-800'}`}>
                                <div className="flex justify-between items-start">
                                    <span className="text-xs text-slate-500 block mb-1">GPS Requerido</span>
                                    <span className={`text-xs px-1.5 py-0.5 rounded ${game.requiresLocation ? 'bg-blue-500 text-white' : 'bg-slate-700 text-slate-400'}`}>
                                        {game.requiresLocation ? 'ON' : 'OFF'}
                                    </span>
                                </div>
                                <span className={`font-medium ${game.requiresLocation ? 'text-blue-400' : 'text-slate-400'}`}>
                                    {game.requiresLocation ? 'Activado' : 'Desactivado'}
                                </span>
                            </div>
                            <div className="bg-slate-900/50 p-3 rounded-lg border border-transparent">
                                <span className="text-xs text-slate-500 block mb-1">Estado</span>
                                <span className={`font-medium ${game.isActive ? 'text-green-400' : 'text-red-400'}`}>
                                    {game.isActive ? 'Online' : 'Offline'}
                                </span>
                            </div>
                        </div>

                        <div className="flex gap-3">
                            <button
                                onClick={() => toggleGame(game.gameId, game.isActive)}
                                className={`flex-1 py-2 rounded-lg text-sm font-medium transition-colors ${game.isActive
                                    ? 'bg-red-500/10 text-red-400 hover:bg-red-500/20'
                                    : 'bg-green-500/10 text-green-400 hover:bg-green-500/20'
                                    }`}
                            >
                                {game.isActive ? 'Desactivar' : 'Activar'}
                            </button>
                            <button className="flex-1 bg-slate-700 hover:bg-slate-600 text-white py-2 rounded-lg text-sm font-medium transition-colors">
                                Editar Reglas
                            </button>
                        </div>
                    </div>
                </div>
            ))}
        </div>
    );
}
