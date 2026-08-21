import React, { useState } from 'react';
import { collection, query, where, getDocs, doc, updateDoc, Timestamp } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';

interface UserPrizeDoc {
    id: string;
    prizeName: string;
    prizeIcon: string;
    prizeType: string;
    prizeDescription?: string;
    redemptionCode: string;
    userName: string;
    userEmail: string;
    userRut?: string;
    wonAt: any;
    expiresAt: any;
    status: string; // 'disponible', 'cobrado', 'expirado'
    redeemedAt?: any;
    redeemedBy?: string;
    casinoId?: string;
}

export default function CashierRedemption() {
    const [searchCode, setSearchCode] = useState('');
    const [loading, setLoading] = useState(false);
    const [prizeResult, setPrizeResult] = useState<UserPrizeDoc | null>(null);
    const [errorMsg, setErrorMsg] = useState('');
    const [successMsg, setSuccessMsg] = useState('');
    const [burning, setBurning] = useState(false);
    const [showPrintModal, setShowPrintModal] = useState(false);

    const handleSearch = async (e?: React.FormEvent) => {
        if (e) e.preventDefault();
        const code = searchCode.trim().toUpperCase();
        if (!code) return;

        setLoading(true);
        setErrorMsg('');
        setSuccessMsg('');
        setPrizeResult(null);

        try {
            // 1. Try querying by redemptionCode (e.g. DRM-7K9A2X)
            const q = query(collection(db, 'user_prizes'), where('redemptionCode', '==', code));
            let snap = await getDocs(q);

            if (snap.empty) {
                // 2. Try prefix fallback or raw id
                const qId = query(collection(db, 'user_prizes'), where('qrCode', '==', code));
                snap = await getDocs(qId);
            }

            if (snap.empty) {
                setErrorMsg(`No se encontró ningún premio con el código "${code}". Verifica que esté bien escrito.`);
            } else {
                const docData = snap.docs[0];
                const prize = {
                    id: docData.id,
                    ...docData.data()
                } as UserPrizeDoc;
                setPrizeResult(prize);
            }
        } catch (err) {
            console.error("Error searching prize:", err);
            setErrorMsg("Error de conexión al buscar el código en el sistema.");
        } finally {
            setLoading(false);
        }
    };

    const handleBurnPrize = async () => {
        if (!prizeResult) return;
        if (prizeResult.status === 'cobrado') {
            alert("Este premio ya fue cobrado anteriormente.");
            return;
        }

        setBurning(true);
        setErrorMsg('');
        try {
            const cashierUser = auth.currentUser?.email || 'Atendedor Caja';
            const now = Timestamp.now();

            await updateDoc(doc(db, 'user_prizes', prizeResult.id), {
                status: 'cobrado',
                redeemed: true,
                redeemedAt: now,
                redeemedBy: cashierUser,
            });

            const updatedPrize: UserPrizeDoc = {
                ...prizeResult,
                status: 'cobrado',
                redeemedAt: now,
                redeemedBy: cashierUser,
            };

            setPrizeResult(updatedPrize);
            setSuccessMsg(`¡Premio ${prizeResult.redemptionCode} quemado y cobrado exitosamente!`);
            // Automatically prompt print dialog
            setShowPrintModal(true);
        } catch (err) {
            console.error("Error burning prize:", err);
            setErrorMsg("Error al quemar el premio en el sistema.");
        } finally {
            setBurning(false);
        }
    };

    const formatDate = (val: any) => {
        if (!val) return 'No especificada';
        if (typeof val === 'string') {
            const d = new Date(val);
            return isNaN(d.getTime()) ? val : d.toLocaleString('es-CL');
        }
        if (val?.toDate) {
            return val.toDate().toLocaleString('es-CL');
        }
        return String(val);
    };

    const triggerPrint = () => {
        window.print();
    };

    return (
        <div className="space-y-8 max-w-4xl mx-auto">
            {/* Header */}
            <div className="bg-slate-800/90 p-6 rounded-2xl border border-slate-700 shadow-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h2 className="text-2xl font-black text-white flex items-center gap-3">
                        <span>🎟️</span> Validación y Canje de Premios en Caja
                    </h2>
                    <p className="text-slate-400 text-sm mt-1">
                        Ingresa el código alfanumérico dictado o escaneado del cliente para quemar el premio e imprimir su ticket oficial.
                    </p>
                </div>
                <div className="flex items-center gap-2">
                    <span className="w-3 h-3 rounded-full bg-emerald-500 animate-pulse"></span>
                    <span className="text-xs font-bold text-emerald-400 uppercase tracking-wider">Caja Online</span>
                </div>
            </div>

            {/* Search Box */}
            <div className="bg-slate-800 p-8 rounded-2xl border border-purple-500/30 shadow-2xl">
                <form onSubmit={handleSearch} className="space-y-4">
                    <label className="block text-sm font-bold text-slate-300 uppercase tracking-wider">
                        Ingresa Código Alfanumérico del Cliente:
                    </label>
                    <div className="flex flex-col sm:flex-row gap-3">
                        <div className="relative flex-1">
                            <input
                                type="text"
                                value={searchCode}
                                onChange={(e) => setSearchCode(e.target.value.toUpperCase())}
                                placeholder="Ej: DRM-7K9A2X"
                                className="w-full bg-slate-900 border-2 border-purple-500/50 focus:border-amber-400 rounded-xl px-5 py-4 text-amber-300 font-mono font-black text-2xl tracking-widest uppercase focus:outline-none shadow-inner"
                            />
                            {searchCode && (
                                <button
                                    type="button"
                                    onClick={() => { setSearchCode(''); setPrizeResult(null); }}
                                    className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white font-bold text-lg cursor-pointer"
                                >
                                    ✕
                                </button>
                            )}
                        </div>
                        <button
                            type="submit"
                            disabled={loading || !searchCode.trim()}
                            className="bg-gradient-to-r from-amber-500 to-yellow-600 hover:from-amber-400 hover:to-yellow-500 disabled:opacity-50 text-black font-black px-8 py-4 rounded-xl text-lg flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20 transition-all cursor-pointer"
                        >
                            {loading ? (
                                <span>Buscando...</span>
                            ) : (
                                <>
                                    <span>🔍</span> Validar Código
                                </>
                            )}
                        </button>
                    </div>
                </form>

                {errorMsg && (
                    <div className="mt-4 p-4 rounded-xl bg-red-500/20 border border-red-500 text-red-300 text-sm font-semibold flex items-center gap-2">
                        <span>⚠️</span> {errorMsg}
                    </div>
                )}

                {successMsg && (
                    <div className="mt-4 p-4 rounded-xl bg-green-500/20 border border-green-500 text-green-300 text-sm font-bold flex items-center gap-2">
                        <span>✓</span> {successMsg}
                    </div>
                )}
            </div>

            {/* Prize Result Card */}
            {prizeResult && (
                <div className="bg-slate-800 rounded-2xl border-2 border-amber-500/50 p-8 shadow-2xl space-y-6">
                    <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 pb-6 border-b border-slate-700">
                        <div className="flex items-center gap-4">
                            <div className="w-20 h-20 rounded-2xl bg-slate-900 border-2 border-amber-500 flex items-center justify-center text-4xl shadow-lg shadow-amber-500/20">
                                {prizeResult.prizeIcon || '🎁'}
                            </div>
                            <div>
                                <span className="text-xs font-bold text-amber-400 uppercase tracking-widest block mb-1">
                                    CÓDIGO: {prizeResult.redemptionCode}
                                </span>
                                <h3 className="text-2xl font-black text-white">{prizeResult.prizeName}</h3>
                                <p className="text-sm text-slate-400">{prizeResult.prizeDescription || 'Beneficio exclusivo Dreams Club'}</p>
                            </div>
                        </div>

                        {/* Status Badge */}
                        <div>
                            {prizeResult.status === 'disponible' ? (
                                <span className="px-4 py-2 rounded-xl bg-green-500/20 border border-green-500 text-green-400 font-black text-sm uppercase flex items-center gap-1.5 shadow-lg shadow-green-500/10">
                                    <span className="w-2 h-2 rounded-full bg-green-400 animate-ping"></span>
                                    DISPONIBLE PARA CANJE
                                </span>
                            ) : prizeResult.status === 'cobrado' ? (
                                <span className="px-4 py-2 rounded-xl bg-purple-500/20 border border-purple-500 text-purple-300 font-black text-sm uppercase flex items-center gap-1.5">
                                    ✓ YA COBRADO EN CAJA
                                </span>
                            ) : (
                                <span className="px-4 py-2 rounded-xl bg-red-500/20 border border-red-500 text-red-400 font-black text-sm uppercase">
                                    ✕ EXPIRADO
                                </span>
                            )}
                        </div>
                    </div>

                    {/* Customer & Prize Details Grid */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
                        <div className="bg-slate-900/70 p-4 rounded-xl border border-slate-700/60">
                            <span className="text-xs text-slate-500 font-bold block uppercase tracking-wider mb-1">Cliente / Ganador</span>
                            <span className="text-white font-bold text-base block">{prizeResult.userName || 'Cliente Dreams'}</span>
                            <span className="text-slate-400 text-xs">{prizeResult.userEmail || 'Sin email'}</span>
                            {prizeResult.userRut && (
                                <span className="text-amber-400 text-xs block font-mono font-bold mt-1">RUT: {prizeResult.userRut}</span>
                            )}
                        </div>

                        <div className="bg-slate-900/70 p-4 rounded-xl border border-slate-700/60">
                            <span className="text-xs text-slate-500 font-bold block uppercase tracking-wider mb-1">Fechas y Validez</span>
                            <div className="text-slate-300 text-xs space-y-1">
                                <p><span className="text-slate-500">Ganado:</span> {formatDate(prizeResult.wonAt)}</p>
                                <p><span className="text-slate-500">Vence:</span> <strong className="text-amber-400">{formatDate(prizeResult.expiresAt)}</strong></p>
                                {prizeResult.redeemedAt && (
                                    <p><span className="text-slate-500">Cobrado el:</span> <strong className="text-green-400">{formatDate(prizeResult.redeemedAt)}</strong> por {prizeResult.redeemedBy || 'Caja'}</p>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* Actions Bar */}
                    <div className="flex flex-col sm:flex-row gap-4 pt-4 border-t border-slate-700">
                        {prizeResult.status === 'disponible' && (
                            <button
                                onClick={handleBurnPrize}
                                disabled={burning}
                                className="flex-1 bg-gradient-to-r from-red-600 to-rose-700 hover:from-red-500 hover:to-rose-600 disabled:opacity-50 text-white font-black py-4 px-6 rounded-xl text-lg flex items-center justify-center gap-2 shadow-xl shadow-red-600/30 transition-all cursor-pointer"
                            >
                                {burning ? 'Quemando Premio...' : '🔥 VALIDAR Y QUEMAR PREMIO'}
                            </button>
                        )}

                        <button
                            onClick={() => setShowPrintModal(true)}
                            className="bg-slate-700 hover:bg-slate-600 text-white font-bold py-4 px-6 rounded-xl flex items-center justify-center gap-2 transition-all cursor-pointer"
                        >
                            <span>🖨️</span> Imprimir Ticket de Caja
                        </button>
                    </div>
                </div>
            )}

            {/* Printable Ticket Voucher Modal */}
            {showPrintModal && prizeResult && (
                <div className="fixed inset-0 bg-black/85 backdrop-blur-sm z-50 flex items-center justify-center p-4 overflow-y-auto">
                    <div className="bg-slate-900 border border-slate-700 rounded-2xl w-full max-w-md p-6 shadow-2xl space-y-6">
                        <div className="flex items-center justify-between border-b border-slate-800 pb-3 no-print">
                            <h3 className="text-lg font-bold text-white flex items-center gap-2">
                                <span>🖨️</span> Vista Previa del Ticket
                            </h3>
                            <button
                                onClick={() => setShowPrintModal(false)}
                                className="text-slate-400 hover:text-white font-bold text-xl cursor-pointer"
                            >
                                ✕
                            </button>
                        </div>

                        {/* Physical Ticket Voucher Format (Optimized for 80mm receipt & thermal printers) */}
                        <div id="casino-ticket" className="bg-white text-black p-6 rounded-xl shadow-inner font-mono text-center space-y-4 border border-dashed border-gray-400">
                            <div className="border-b-2 border-black pb-3">
                                <h2 className="text-xl font-black tracking-widest uppercase">CASINO DREAMS</h2>
                                <p className="text-xs font-bold tracking-wider">DREAMS CLUB - VOUCHER DE CANJE</p>
                                <p className="text-[10px] text-gray-600">Sede Coyhaique / Sistema Central</p>
                            </div>

                            <div className="py-2">
                                <span className="text-2xl">{prizeResult.prizeIcon || '🎁'}</span>
                                <h3 className="text-lg font-black uppercase mt-1">{prizeResult.prizeName}</h3>
                                <p className="text-xs text-gray-700">{prizeResult.prizeDescription || 'Beneficio al portador'}</p>
                            </div>

                            {/* Alphanumeric Validation Code Box */}
                            <div className="bg-gray-100 p-3 rounded border-2 border-black">
                                <span className="text-[10px] font-bold block uppercase text-gray-600">CÓDIGO DE VALIDACIÓN</span>
                                <span className="text-2xl font-black tracking-widest">{prizeResult.redemptionCode}</span>
                            </div>

                            <div className="text-left text-xs space-y-1 border-y border-dashed border-gray-400 py-3">
                                <p><strong>CLIENTE:</strong> {prizeResult.userName || 'No informado'}</p>
                                {prizeResult.userRut && <p><strong>RUT:</strong> {prizeResult.userRut}</p>}
                                <p><strong>ESTADO:</strong> {prizeResult.status === 'cobrado' ? 'COBRADO EN CAJA' : 'EMITIDO'}</p>
                                <p><strong>FECHA COBRO:</strong> {formatDate(prizeResult.redeemedAt || new Date())}</p>
                                <p><strong>ATENDEDOR:</strong> {prizeResult.redeemedBy || auth.currentUser?.email || 'Cajero'}</p>
                            </div>

                            <div className="pt-4 text-center">
                                <div className="w-48 h-10 mx-auto border-b border-black mb-1"></div>
                                <span className="text-[10px] text-gray-500 uppercase block">Firma y Timbre de Conformidad</span>
                                <p className="text-[9px] text-gray-400 mt-2 font-sans">Válido exclusivamente en dependencias del Casino Dreams</p>
                            </div>
                        </div>

                        {/* Print Action Buttons */}
                        <div className="flex gap-3 no-print">
                            <button
                                onClick={() => setShowPrintModal(false)}
                                className="flex-1 py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold text-sm cursor-pointer"
                            >
                                Cerrar
                            </button>
                            <button
                                onClick={triggerPrint}
                                className="flex-1 py-3 rounded-xl bg-amber-500 hover:bg-amber-400 text-black font-black text-sm flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20 cursor-pointer"
                            >
                                <span>🖨️</span> Imprimir Ahora
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Print Styles */}
            <style>{`
                @media print {
                    body * {
                        visibility: hidden !important;
                    }
                    #casino-ticket, #casino-ticket * {
                        visibility: visible !important;
                    }
                    #casino-ticket {
                        position: absolute !important;
                        left: 0 !important;
                        top: 0 !important;
                        width: 80mm !important;
                        padding: 10px !important;
                        margin: 0 !important;
                        border: none !important;
                        box-shadow: none !important;
                    }
                    .no-print {
                        display: none !important;
                    }
                }
            `}</style>
        </div>
    );
}
