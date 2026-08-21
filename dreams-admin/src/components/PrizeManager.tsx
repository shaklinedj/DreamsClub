import React, { useEffect, useState } from 'react';
import { collection, onSnapshot, doc, setDoc, updateDoc, deleteDoc, getDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';

interface PrizeItem {
    id: string;
    name: string;
    type: string;
    description: string;
    icon: string;
    probability: number;
    daysValid: number;
    isActive: boolean;
}

interface GameRules {
    cooldownHours: number;
    allowedDays: number[]; // 0=Dom, 1=Lun, 2=Mar, 3=Mie, 4=Jue, 5=Vie, 6=Sab
    timeWindowEnabled: boolean;
    startHour: number;
    endHour: number;
    minStreakRequired: number;
    maxDailyGamesAllowed: number;
}

const defaultRules: GameRules = {
    cooldownHours: 48,
    allowedDays: [0, 1, 2, 3, 4, 5, 6],
    timeWindowEnabled: false,
    startHour: 18,
    endHour: 2,
    minStreakRequired: 0,
    maxDailyGamesAllowed: 1,
};

const daysOfWeek = [
    { id: 1, label: 'Lunes' },
    { id: 2, label: 'Martes' },
    { id: 3, label: 'Miércoles' },
    { id: 4, label: 'Jueves' },
    { id: 5, label: 'Viernes' },
    { id: 6, label: 'Sábado' },
    { id: 0, label: 'Domingo' },
];

const categoryLabels: Record<string, string> = {
    drink: '🍸 Tragos / Bebidas',
    food: '🍔 Comida / Gastronomía',
    promotional_credits: '🎰 Créditos Promocionales',
    tickets: '🎟️ Entradas al Casino',
    points: '💎 Puntos Dreams',
    hotel: '🏨 Hotel / Estadía',
};

const quickEmojis = ['🍸', '🎰', '🎟️', '🍔', '🍺', '🍹', '💎', '🏨', '🎁', '🍕', '☕', '🍰'];

export default function PrizeManager() {
    const [prizes, setPrizes] = useState<PrizeItem[]>([]);
    const [rules, setRules] = useState<GameRules>(defaultRules);
    const [loading, setLoading] = useState(true);
    const [savingRules, setSavingRules] = useState(false);
    const [rulesSavedMsg, setRulesSavedMsg] = useState(false);

    // Modal Form State
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingPrizeId, setEditingPrizeId] = useState<string | null>(null);
    const [formData, setFormData] = useState({
        name: '',
        type: 'drink',
        description: '',
        icon: '🍸',
        probability: 20,
        daysValid: 7,
        isActive: true,
    });

    useEffect(() => {
        // 1. Listen to Prizes Catalog
        const unsubPrizes = onSnapshot(collection(db, 'mini_game_prizes'), (snapshot) => {
            const data = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            })) as PrizeItem[];
            setPrizes(data);
            setLoading(false);
        });

        // 2. Load Global Rules
        const loadRules = async () => {
            try {
                const docRef = doc(db, 'game_rules_config', 'global');
                const snap = await getDoc(docRef);
                if (snap.exists()) {
                    setRules({ ...defaultRules, ...snap.data() });
                } else {
                    await setDoc(docRef, defaultRules);
                }
            } catch (err) {
                console.error("Error loading rules:", err);
            }
        };
        loadRules();

        return () => unsubPrizes();
    }, []);

    const handleSaveRules = async () => {
        setSavingRules(true);
        try {
            await setDoc(doc(db, 'game_rules_config', 'global'), rules);
            setRulesSavedMsg(true);
            setTimeout(() => setRulesSavedMsg(false), 3000);
        } catch (err) {
            console.error("Error saving rules:", err);
            alert("Error al guardar las reglas");
        } finally {
            setSavingRules(false);
        }
    };

    const toggleDay = (dayId: number) => {
        if (rules.allowedDays.includes(dayId)) {
            setRules({
                ...rules,
                allowedDays: rules.allowedDays.filter(d => d !== dayId)
            });
        } else {
            setRules({
                ...rules,
                allowedDays: [...rules.allowedDays, dayId]
            });
        }
    };

    const togglePrizeActive = async (prize: PrizeItem) => {
        try {
            await updateDoc(doc(db, 'mini_game_prizes', prize.id), {
                isActive: !prize.isActive
            });
        } catch (err) {
            console.error("Error toggling prize:", err);
        }
    };

    const openCreateModal = () => {
        setEditingPrizeId(null);
        setFormData({
            name: '',
            type: 'drink',
            description: '',
            icon: '🍸',
            probability: 20,
            daysValid: 7,
            isActive: true,
        });
        setIsModalOpen(true);
    };

    const openEditModal = (prize: PrizeItem) => {
        setEditingPrizeId(prize.id);
        setFormData({
            name: prize.name,
            type: prize.type || 'drink',
            description: prize.description || '',
            icon: prize.icon || '🎁',
            probability: prize.probability || 20,
            daysValid: prize.daysValid || 7,
            isActive: prize.isActive !== false,
        });
        setIsModalOpen(true);
    };

    const handleDeletePrize = async (prizeId: string) => {
        if (!confirm('¿Estás seguro de eliminar este premio del catálogo?')) return;
        try {
            await deleteDoc(doc(db, 'mini_game_prizes', prizeId));
        } catch (err) {
            console.error("Error deleting prize:", err);
        }
    };

    const handleSavePrizeForm = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!formData.name.trim()) return;

        try {
            const id = editingPrizeId || `prize_${Date.now()}`;
            await setDoc(doc(db, 'mini_game_prizes', id), {
                name: formData.name.trim(),
                type: formData.type,
                description: formData.description.trim(),
                icon: formData.icon.trim(),
                probability: Number(formData.probability),
                daysValid: Number(formData.daysValid),
                isActive: formData.isActive,
            });
            setIsModalOpen(false);
        } catch (err) {
            console.error("Error saving prize:", err);
            alert("Error al guardar premio");
        }
    };

    if (loading) {
        return <div className="text-white text-center p-12 text-lg">Cargando catálogo de premios y reglas...</div>;
    }

    return (
        <div className="space-y-10">
            {/* Header */}
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-slate-800/80 p-6 rounded-2xl border border-slate-700">
                <div>
                    <h2 className="text-2xl font-black text-white flex items-center gap-3">
                        <span>🎁</span> Catálogo de Premios y Reglas de Minijuegos
                    </h2>
                    <p className="text-slate-400 text-sm mt-1">
                        Configura los premios disponibles en Ruleta, Slots y Dreams Match, junto con sus reglas de disponibilidad (48h, días y horarios).
                    </p>
                </div>
                <button
                    onClick={openCreateModal}
                    className="bg-gradient-to-r from-amber-500 to-yellow-600 hover:from-amber-400 hover:to-yellow-500 text-black font-black px-6 py-3 rounded-xl flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20 transition-all cursor-pointer"
                >
                    <span className="text-xl">➕</span> Crear Nuevo Premio
                </button>
            </div>

            {/* Global Rules Panel */}
            <div className="bg-slate-800/90 rounded-2xl border border-amber-500/30 p-6 shadow-xl">
                <div className="flex items-center justify-between mb-6 pb-4 border-b border-slate-700">
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-amber-500/10 text-amber-400 flex items-center justify-center text-xl">
                            ⚙️
                        </div>
                        <div>
                            <h3 className="text-lg font-bold text-white">Reglas de Disponibilidad Global</h3>
                            <p className="text-xs text-slate-400">Aplican automáticamente a todos los minijuegos de la aplicación.</p>
                        </div>
                    </div>
                    <button
                        onClick={handleSaveRules}
                        disabled={savingRules}
                        className="bg-purple-600 hover:bg-purple-500 disabled:opacity-50 text-white font-bold px-5 py-2.5 rounded-xl flex items-center gap-2 transition-all cursor-pointer shadow-lg shadow-purple-600/30"
                    >
                        {savingRules ? 'Guardando...' : '💾 Guardar Reglas'}
                    </button>
                </div>

                {rulesSavedMsg && (
                    <div className="mb-6 p-4 rounded-xl bg-green-500/20 border border-green-500 text-green-300 text-sm font-semibold flex items-center gap-2">
                        <span>✓</span> Reglas de minijuegos actualizadas con éxito en Firestore.
                    </div>
                )}

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                    {/* Cooldown 48h */}
                    <div className="bg-slate-900/60 p-5 rounded-xl border border-slate-700">
                        <label className="text-xs font-bold text-slate-300 uppercase tracking-wider block mb-2">
                            ⏱️ Cooldown entre victorias
                        </label>
                        <div className="flex items-center gap-3">
                            <input
                                type="number"
                                min="1"
                                max="168"
                                value={rules.cooldownHours}
                                onChange={(e) => setRules({ ...rules, cooldownHours: Number(e.target.value) })}
                                className="w-24 bg-slate-800 border border-slate-600 rounded-lg px-3 py-2 text-white font-bold text-lg text-center"
                            />
                            <span className="text-slate-300 font-medium">Horas (ej: 48)</span>
                        </div>
                        <p className="text-xs text-slate-400 mt-2">
                            El usuario podrá ganar 1 premio cada {rules.cooldownHours} horas.
                        </p>
                    </div>

                    {/* Racha Mínima Requerida */}
                    <div className="bg-slate-900/60 p-5 rounded-xl border border-slate-700">
                        <label className="text-xs font-bold text-slate-300 uppercase tracking-wider block mb-2">
                            🔥 Racha Mínima Requerida
                        </label>
                        <select
                            value={rules.minStreakRequired}
                            onChange={(e) => setRules({ ...rules, minStreakRequired: Number(e.target.value) })}
                            className="w-full bg-slate-800 border border-slate-600 rounded-lg px-3 py-2 text-white font-bold"
                        >
                            <option value={0}>Todos los usuarios (0 días)</option>
                            <option value={1}>Racha de 1 día (Aventurero)</option>
                            <option value={3}>Racha de 3 días (Guerrero)</option>
                            <option value={7}>Racha de 7 días (Maestro VIP)</option>
                            <option value={14}>Racha de 14 días (Gran Brujo)</option>
                            <option value={30}>Racha de 30 días (Leyenda)</option>
                        </select>
                        <p className="text-xs text-slate-400 mt-2">
                            Segmenta qué nivel de racha puede desbloquear premios.
                        </p>
                    </div>

                    {/* Límite de Juegos Diarios */}
                    <div className="bg-slate-900/60 p-5 rounded-xl border border-slate-700">
                        <label className="text-xs font-bold text-slate-300 uppercase tracking-wider block mb-2">
                            🎮 Límite de Juegos Diarios
                        </label>
                        <select
                            value={rules.maxDailyGamesAllowed ?? 1}
                            onChange={(e) => setRules({ ...rules, maxDailyGamesAllowed: Number(e.target.value) })}
                            className="w-full bg-slate-800 border border-slate-600 rounded-lg px-3 py-2 text-white font-bold"
                        >
                            <option value={1}>Permitir solo 1 juego al día</option>
                            <option value={2}>Permitir hasta 2 juegos al día</option>
                            <option value={3}>Permitir hasta 3 juegos al día</option>
                            <option value={4}>Permitir los 4 juegos (Sin límite)</option>
                        </select>
                        <p className="text-xs text-slate-400 mt-2">
                            Cuántos juegos distintos puede seleccionar el usuario por día.
                        </p>
                    </div>

                    {/* Ventana Horaria */}
                    <div className="bg-slate-900/60 p-5 rounded-xl border border-slate-700">
                        <div className="flex items-center justify-between mb-2">
                            <label className="text-xs font-bold text-slate-300 uppercase tracking-wider">
                                🌙 Ventana de Horario Activo
                            </label>
                            <label className="flex items-center gap-2 cursor-pointer">
                                <input
                                    type="checkbox"
                                    checked={rules.timeWindowEnabled}
                                    onChange={(e) => setRules({ ...rules, timeWindowEnabled: e.target.checked })}
                                    className="w-4 h-4 rounded text-purple-600 bg-slate-800 border-slate-600"
                                />
                                <span className="text-xs font-semibold text-slate-300">Restringir Horario</span>
                            </label>
                        </div>

                        {rules.timeWindowEnabled ? (
                            <div className="grid grid-cols-2 gap-4 mt-3">
                                <div>
                                    <span className="text-xs text-slate-400 block mb-1">Hora Inicio (0-23 hrs):</span>
                                    <input
                                        type="number"
                                        min="0"
                                        max="23"
                                        value={rules.startHour}
                                        onChange={(e) => setRules({ ...rules, startHour: Number(e.target.value) })}
                                        className="w-full bg-slate-800 border border-slate-600 rounded-lg px-3 py-2 text-white font-bold"
                                    />
                                </div>
                                <div>
                                    <span className="text-xs text-slate-400 block mb-1">Hora Fin (0-23 hrs):</span>
                                    <input
                                        type="number"
                                        min="0"
                                        max="23"
                                        value={rules.endHour}
                                        onChange={(e) => setRules({ ...rules, endHour: Number(e.target.value) })}
                                        className="w-full bg-slate-800 border border-slate-600 rounded-lg px-3 py-2 text-white font-bold"
                                    />
                                </div>
                            </div>
                        ) : (
                            <p className="text-xs text-emerald-400 mt-2 font-medium">
                                ✓ Disponible las 24 horas del día sin restricción horaria.
                            </p>
                        )}
                    </div>
                </div>

                {/* Días de la Semana Permitidos */}
                <div className="mt-6 pt-5 border-t border-slate-700">
                    <label className="text-xs font-bold text-slate-300 uppercase tracking-wider block mb-3">
                        📅 Días de la Semana con Premios Habilitados:
                    </label>
                    <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-3">
                        {daysOfWeek.map((day) => {
                            const isChecked = rules.allowedDays.includes(day.id);
                            return (
                                <button
                                    key={day.id}
                                    type="button"
                                    onClick={() => toggleDay(day.id)}
                                    className={`py-2.5 px-3 rounded-xl border text-sm font-bold transition-all cursor-pointer flex items-center justify-center gap-2 ${
                                        isChecked
                                            ? 'bg-amber-500/20 border-amber-500 text-amber-300 shadow-md shadow-amber-500/10'
                                            : 'bg-slate-900/40 border-slate-700 text-slate-500 hover:border-slate-600'
                                    }`}
                                >
                                    <span>{isChecked ? '✓' : '✗'}</span>
                                    <span>{day.label}</span>
                                </button>
                            );
                        })}
                    </div>
                </div>
            </div>

            {/* Prizes Grid */}
            <div>
                <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                    <span>🎰</span> Premios Configurados en el Catálogo ({prizes.length})
                </h3>

                {prizes.length === 0 ? (
                    <div className="bg-slate-800/50 rounded-2xl border border-slate-700 p-12 text-center text-slate-400">
                        No hay premios creados aún. Haz clic en "Crear Nuevo Premio" para agregar tragos, promocionales, entradas, sandwiches, etc.
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {prizes.map((prize) => (
                            <div
                                key={prize.id}
                                className={`bg-slate-800 rounded-2xl border ${
                                    prize.isActive ? 'border-amber-500/40' : 'border-slate-700 opacity-60'
                                } p-6 flex flex-col justify-between transition-all hover:border-amber-500`}
                            >
                                <div>
                                    <div className="flex items-start justify-between gap-4 mb-4">
                                        <div className="w-14 h-14 rounded-2xl bg-slate-900 border border-slate-700 flex items-center justify-center text-3xl shadow-inner">
                                            {prize.icon || '🎁'}
                                        </div>
                                        <div className="flex flex-col items-end gap-1.5">
                                            <span
                                                className={`px-3 py-1 rounded-full text-xs font-black uppercase ${
                                                    prize.isActive
                                                        ? 'bg-green-500/20 text-green-400 border border-green-500/30'
                                                        : 'bg-red-500/20 text-red-400 border border-red-500/30'
                                                }`}
                                            >
                                                {prize.isActive ? 'Activo' : 'Pausado'}
                                            </span>
                                            <span className="text-xs text-slate-400 font-medium">
                                                {categoryLabels[prize.type] || prize.type}
                                            </span>
                                        </div>
                                    </div>

                                    <h4 className="text-lg font-bold text-white mb-1.5">{prize.name}</h4>
                                    <p className="text-xs text-slate-400 line-clamp-2 mb-4">{prize.description}</p>

                                    <div className="grid grid-cols-2 gap-3 py-3 border-y border-slate-700/60 text-xs">
                                        <div>
                                            <span className="text-slate-500 block">Probabilidad</span>
                                            <span className="text-amber-400 font-bold">{prize.probability}% peso</span>
                                        </div>
                                        <div>
                                            <span className="text-slate-500 block">Validez</span>
                                            <span className="text-white font-bold">{prize.daysValid} días</span>
                                        </div>
                                    </div>
                                </div>

                                <div className="flex items-center gap-2 mt-6">
                                    <button
                                        onClick={() => togglePrizeActive(prize)}
                                        className={`flex-1 py-2 px-3 rounded-lg text-xs font-bold transition-colors cursor-pointer ${
                                            prize.isActive
                                                ? 'bg-slate-700 hover:bg-slate-600 text-slate-300'
                                                : 'bg-green-600/20 hover:bg-green-600/30 text-green-400'
                                        }`}
                                    >
                                        {prize.isActive ? 'Pausar' : 'Activar'}
                                    </button>
                                    <button
                                        onClick={() => openEditModal(prize)}
                                        className="py-2 px-4 rounded-lg text-xs font-bold bg-amber-500/20 hover:bg-amber-500/30 text-amber-300 border border-amber-500/30 transition-colors cursor-pointer"
                                    >
                                        ✏️ Editar
                                    </button>
                                    <button
                                        onClick={() => handleDeletePrize(prize.id)}
                                        className="py-2 px-3 rounded-lg text-xs font-bold bg-red-500/10 hover:bg-red-500/20 text-red-400 transition-colors cursor-pointer"
                                    >
                                        🗑️
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* Create/Edit Prize Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4 overflow-y-auto">
                    <div className="bg-slate-800 border border-slate-700 rounded-2xl w-full max-w-lg p-6 shadow-2xl space-y-6">
                        <div className="flex items-center justify-between border-b border-slate-700 pb-4">
                            <h3 className="text-xl font-bold text-white flex items-center gap-2">
                                <span>{editingPrizeId ? '✏️' : '➕'}</span>
                                {editingPrizeId ? 'Editar Premio' : 'Nuevo Premio'}
                            </h3>
                            <button
                                onClick={() => setIsModalOpen(false)}
                                className="text-slate-400 hover:text-white text-2xl font-bold cursor-pointer"
                            >
                                ✕
                            </button>
                        </div>

                        <form onSubmit={handleSavePrizeForm} className="space-y-4">
                            <div>
                                <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1">
                                    Nombre del Premio (Ej: 1 Trago, $3.000 Promocionales, 1 Entrada)
                                </label>
                                <input
                                    type="text"
                                    required
                                    value={formData.name}
                                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                    placeholder="Ej: 1 Trago de Cortesía"
                                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-white font-medium focus:border-amber-500 focus:outline-none"
                                />
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1">
                                        Categoría
                                    </label>
                                    <select
                                        value={formData.type}
                                        onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                                        className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-white font-medium focus:border-amber-500 focus:outline-none"
                                    >
                                        <option value="drink">🍸 Trago / Bebida</option>
                                        <option value="food">🍔 Comida / Sandwich</option>
                                        <option value="promotional_credits">🎰 Créditos Promocionales</option>
                                        <option value="tickets">🎟️ Entrada al Casino</option>
                                        <option value="points">💎 Puntos Dreams</option>
                                        <option value="hotel">🏨 Hotel / Estadía</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1">
                                        Icono / Emoji
                                    </label>
                                    <input
                                        type="text"
                                        required
                                        value={formData.icon}
                                        onChange={(e) => setFormData({ ...formData, icon: e.target.value })}
                                        className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-white font-medium text-center text-xl focus:border-amber-500 focus:outline-none"
                                    />
                                </div>
                            </div>

                            {/* Quick Emojis Selection */}
                            <div className="flex flex-wrap gap-2">
                                {quickEmojis.map((emoji) => (
                                    <button
                                        key={emoji}
                                        type="button"
                                        onClick={() => setFormData({ ...formData, icon: emoji })}
                                        className="w-8 h-8 rounded-lg bg-slate-900 border border-slate-700 hover:border-amber-500 flex items-center justify-center text-lg cursor-pointer"
                                    >
                                        {emoji}
                                    </button>
                                ))}
                            </div>

                            <div>
                                <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1">
                                    Descripción del Beneficio
                                </label>
                                <textarea
                                    rows={2}
                                    value={formData.description}
                                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                    placeholder="Detalle para el atendedor o cliente..."
                                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm focus:border-amber-500 focus:outline-none"
                                />
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1">
                                        Probabilidad (Peso 1-100)
                                    </label>
                                    <input
                                        type="number"
                                        min="1"
                                        max="100"
                                        required
                                        value={formData.probability}
                                        onChange={(e) => setFormData({ ...formData, probability: Number(e.target.value) })}
                                        className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-white font-bold"
                                    />
                                </div>
                                <div>
                                    <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1">
                                        Días de Validez
                                    </label>
                                    <input
                                        type="number"
                                        min="1"
                                        max="365"
                                        required
                                        value={formData.daysValid}
                                        onChange={(e) => setFormData({ ...formData, daysValid: Number(e.target.value) })}
                                        className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-white font-bold"
                                    />
                                </div>
                            </div>

                            <div className="flex items-center gap-3 pt-2">
                                <label className="flex items-center gap-2 cursor-pointer">
                                    <input
                                        type="checkbox"
                                        checked={formData.isActive}
                                        onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                                        className="w-5 h-5 rounded text-amber-500 bg-slate-900 border-slate-700"
                                    />
                                    <span className="text-sm font-bold text-white">Activar inmediatamente en la App</span>
                                </label>
                            </div>

                            <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-700">
                                <button
                                    type="button"
                                    onClick={() => setIsModalOpen(false)}
                                    className="px-5 py-2.5 rounded-xl text-slate-300 hover:text-white font-bold text-sm cursor-pointer"
                                >
                                    Cancelar
                                </button>
                                <button
                                    type="submit"
                                    className="bg-amber-500 hover:bg-amber-400 text-black font-black px-6 py-2.5 rounded-xl shadow-lg shadow-amber-500/20 text-sm cursor-pointer"
                                >
                                    {editingPrizeId ? 'Guardar Cambios' : 'Crear Premio'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
