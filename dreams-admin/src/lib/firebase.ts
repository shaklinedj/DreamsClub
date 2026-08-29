
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
    apiKey: import.meta.env.PUBLIC_FIREBASE_API_KEY || 'AIzaSyDXOo7MAZTLSJ3gXZjNOE0od4-7-1HfScs',
    appId: import.meta.env.PUBLIC_FIREBASE_APP_ID || '1:326453914816:web:7dff6793ffc873fb291125',
    messagingSenderId: import.meta.env.PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '326453914816',
    projectId: import.meta.env.PUBLIC_FIREBASE_PROJECT_ID || 'dreams-casino-app',
    authDomain: import.meta.env.PUBLIC_FIREBASE_AUTH_DOMAIN || 'dreams-casino-app.firebaseapp.com',
    storageBucket: import.meta.env.PUBLIC_FIREBASE_STORAGE_BUCKET || 'dreams-casino-app.firebasestorage.app',
};

export const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const storage = getStorage(app);
export const auth = getAuth(app);
