import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

const firebaseConfig = {
  apiKey: 'AIzaSyDB6JgulOU15cKe7V-oNcboWScX6_DbuZY',
  authDomain: 'roommateapp-fbb4f.firebaseapp.com',
  projectId: 'roommateapp-fbb4f',
  storageBucket: 'roommateapp-fbb4f.firebasestorage.app',
  messagingSenderId: '787375402089',
  appId: '1:787375402089:web:bb98d7aa19147eb09586f8',
  measurementId: 'G-GC4SG52RHP',
}

const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)
export const db = getFirestore(app)
