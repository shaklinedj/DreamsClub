import { initializeApp } from "firebase/app";
import { getFirestore, collection, getDocs } from "firebase/firestore";

const firebaseConfig = {
    apiKey: 'AIzaSyDXOo7MAZTLSJ3gXZjNOE0od4-7-1HfScs',
    appId: '1:326453914816:web:7dff6793ffc873fb291125',
    messagingSenderId: '326453914816',
    projectId: 'dreams-casino-app',
    authDomain: 'dreams-casino-app.firebaseapp.com',
    storageBucket: 'dreams-casino-app.firebasestorage.app',
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function check() {
    console.log("--- STICKERS ---");
    const stickersSnap = await getDocs(collection(db, 'stickers'));
    stickersSnap.forEach((doc) => {
        console.log(doc.id, doc.data());
    });

    console.log("--- USERS ---");
    const usersSnap = await getDocs(collection(db, 'users'));
    usersSnap.forEach((doc) => {
        const data = doc.data();
        console.log(doc.id, {
            name: data.name,
            email: data.email,
            streak: data.streak,
            currentStreak: data.currentStreak,
        });
    });
}

check().catch(console.error);
