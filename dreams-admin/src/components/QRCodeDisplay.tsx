import React, { useEffect, useState } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { doc, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';

interface QRCodeDisplayProps {
    initialCasinoId?: string;
}

export default function QRCodeDisplay({ initialCasinoId }: QRCodeDisplayProps) {
    const [casinoId, setCasinoId] = useState<string>(initialCasinoId || 'casino-1'); // Default to a valid ID or let user select
    const [qrData, setQrData] = useState<string>('');
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null);

    const [status, setStatus] = useState<string>('Initializing...');

    useEffect(() => {
        if (!casinoId) {
            setStatus('No Casino ID provided');
            return;
        }

        setLoading(true);
        setStatus(`Connecting to Firestore (casinos/${casinoId})...`);

        const unsub = onSnapshot(
            doc(db, 'casinos', casinoId),
            (docSnapshot) => { // Changed parameter name from 'doc' to 'docSnapshot'
                setLoading(false);
                if (docSnapshot.exists()) {
                    const data = docSnapshot.data();
                    setStatus('Connected. Data received.');
                    setQrData(data.dynamic_qr || data.id || 'no-data');
                    setError(null);
                } else {
                    setStatus('Document does not exist.');
                    setError('Casino not found in database.');
                }
            },
            (err) => {
                console.error("Firestore Error:", err);
                setLoading(false);
                setStatus(`Connection Error: ${err.message}`);
                setError(`Error: ${err.message}. Check console/permissions.`);
            }
        );

        return () => unsub();
    }, [casinoId]);

    // Dummy function to simulate a backend update (requires write permission)
    /*
    const simulateUpdate = async () => {
       try {
         await setDoc(doc(db, 'casinos', casinoId), { 
           dynamic_qr: 'QR-' + Date.now(),
           name: 'Test Casino ' + casinoId
         }, { merge: true });
       } catch(e: any) {
         alert('Write failed: ' + e.message);
       }
    };
    */

    return (
        <div className="flex flex-col items-center justify-center min-h-screen bg-neutral-900 text-white p-8">
            <div className="max-w-md w-full bg-neutral-800 rounded-2xl p-8 shadow-2xl border border-neutral-700 text-center">
                <h1 className="text-3xl font-bold mb-2 text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-600">
                    Casino Check-In
                </h1>

                {/* Debug Status */}
                <div className="bg-black/30 p-2 rounded text-xs font-mono text-neutral-500 mb-4 break-words">
                    Status: {status}
                </div>

                <p className="text-neutral-400 mb-8">Escanea este código para registrar tu visita</p>

                <div className="bg-white p-4 rounded-xl mx-auto mb-8 shadow-inner inline-block">
                    {loading ? (
                        <div className="w-64 h-64 flex items-center justify-center text-neutral-500">
                            <span className="animate-pulse">Cargando...</span>
                        </div>
                    ) : error ? (
                        <div className="w-64 h-64 flex flex-col items-center justify-center text-red-500 p-4">
                            <span className="text-4xl mb-2">⚠️</span>
                            <p className="text-sm font-bold">{error}</p>
                        </div>
                    ) : (
                        <QRCodeSVG
                            value={qrData}
                            size={256}
                            level={"H"}
                            includeMargin={true}
                        />
                    )}
                </div>

                <div className="text-sm text-neutral-500 font-mono mb-4">
                    Watching: casinos/{casinoId} <br />
                    Data: {qrData.substring(0, 20)}...
                </div>

                {!initialCasinoId && (
                    <div className="flex gap-2 justify-center">
                        <input
                            type="text"
                            value={casinoId}
                            onChange={(e) => setCasinoId(e.target.value)}
                            className="bg-neutral-900 border border-neutral-700 rounded px-3 py-1 text-white text-center w-40"
                            placeholder="Casino ID"
                        />
                    </div>
                )}
            </div>

            <div className="mt-8 text-neutral-600 text-sm">
                Dreams Club Admin System v1.1
            </div>
        </div>
    );
}

