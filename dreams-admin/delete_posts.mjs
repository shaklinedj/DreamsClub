import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, deleteDoc, doc } from 'firebase/firestore';

const firebaseConfig = {
    apiKey: 'AIzaSyDXOo7MAZTLSJ3gXZjNOE0od4-7-1HfScs',
    projectId: 'dreams-casino-app',
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function run() {
    const querySnapshot = await getDocs(collection(db, "posts"));
    for (const d of querySnapshot.docs) {
        const data = d.data();
        if (["bhhh", "hahahah", "Test Post to Delete"].includes(data.title)) {
            await deleteDoc(doc(db, "posts", d.id));
            console.log("Deleted:", data.title);
        }
    }
    console.log("Done deleting old posts.");
    process.exit(0);
}
run();
