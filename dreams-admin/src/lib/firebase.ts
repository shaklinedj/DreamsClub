
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
    apiKey: 'AIzaSyDXOo7MAZTLSJ3gXZjNOE0od4-7-1HfScs',
    appId: '1:326453914816:web:7dff6793ffc873fb291125',
    messagingSenderId: '326453914816',
    projectId: 'dreams-casino-app',
    authDomain: 'dreams-casino-app.firebaseapp.com',
    storageBucket: 'dreams-casino-app.firebasestorage.app',
};

export const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const storage = getStorage(app);
export const auth = getAuth(app);
