"use client";

import { useEffect, useState, useRef } from "react";
import { onAuthStateChanged, User } from "firebase/auth";
import { doc, onSnapshot, getDoc } from "firebase/firestore";
import { AnimatePresence } from "framer-motion";
import { auth, db } from "../lib/firebase";

import AuthModal from "../components/AuthModal";
import AuraBackground, { MoodType } from "../components/AuraBackground";
import AuraContent from "../components/AuraContent";
import ProfileDrawer from "../components/ProfileDrawer";

interface CountryData {
  code: string;
  count: number;
}

export default function SappyPage() {
  const [user, setUser] = useState<User | null>(null);
  const [authChecked, setAuthChecked] = useState(false);
  const [userMood, setUserMood] = useState<MoodType>(null);
  const [globalCounts, setGlobalCounts] = useState({ happy: 0, sad: 0 });
  const [userCountry, setUserCountry] = useState<string>("US");
  const [countriesData, setCountriesData] = useState<Record<string, {happy: number, sad: number}>>({});

  const unsubRealtimeRef = useRef<(() => void) | null>(null);
  const unsubUserRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    const unsubAuth = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);
      setAuthChecked(true);

      if (unsubRealtimeRef.current) {
        unsubRealtimeRef.current();
        unsubRealtimeRef.current = null;
      }
      if (unsubUserRef.current) {
        unsubUserRef.current();
        unsubUserRef.current = null;
      }

      if (currentUser) {
        try {
          // 1. Listen to User's own mood document in realtime
          unsubUserRef.current = onSnapshot(
            doc(db, "users", currentUser.uid),
            (snap) => {
              if (snap.exists()) {
                const data = snap.data();
                if (data.country) setUserCountry(data.country);
                
                const moodValue = data.mood;
                if (moodValue === "happy" || moodValue === "sad") {
                  setUserMood(moodValue);
                } else {
                  setUserMood("none"); // Authenticated but no mood
                }
              } else {
                setUserMood("none");
              }
            },
            (err) => {
              console.error("[Sappy] Error listening to user data:", err);
              setUserMood("none");
            }
          );

          // 2. Listen to Global Metrics in realtime
          unsubRealtimeRef.current = onSnapshot(
            doc(db, "metrics", "global_counts"),
            (docSnap) => {
              if (docSnap.exists()) {
                const data = docSnap.data();
                setGlobalCounts({
                  happy: Math.max(0, data.total_happy || 0),
                  sad: Math.max(0, data.total_sad || 0),
                });

                const countriesObj = data.countries || {};
                setCountriesData(countriesObj);
              }
            }
          );
        } catch (err) {
          console.error("[Sappy] Setup error:", err);
        }
      } else {
        setUserMood(null);
      }
    });

    return () => {
      unsubAuth();
      if (unsubRealtimeRef.current) unsubRealtimeRef.current();
      if (unsubUserRef.current) unsubUserRef.current();
    };
  }, []);

  if (!authChecked) {
    return <div className="h-[100dvh] w-full bg-black" />; // Loading block
  }

  let globalPercentage = 100;
  let localPercentage = 100;

  if (userMood === "happy" || userMood === "sad") {
    // 1. Global Percentage
    const globalTotal = globalCounts.happy + globalCounts.sad;
    const myGlobal = userMood === "happy" ? globalCounts.happy : globalCounts.sad;
    if (globalTotal > 0) {
      globalPercentage = Math.round((myGlobal / globalTotal) * 100);
    }
    
    // 2. Local Percentage
    const stats = countriesData[userCountry] || { happy: 0, sad: 0 };
    const localTotal = (stats.happy || 0) + (stats.sad || 0);
    const myLocal = userMood === "happy" ? (stats.happy || 0) : (stats.sad || 0);
    if (localTotal > 0) {
      localPercentage = Math.round((myLocal / localTotal) * 100);
    }
  }

  return (
    <main className="relative h-[100dvh] w-full overflow-hidden font-dela bg-black">
      {/* 1. Underlying Cinematic Flow */}
      {user && (
        <AuraBackground mood={userMood} />
      )}

      {/* 2. Typographic Foreground Layer */}
      {user && (
        <AuraContent 
          mood={userMood} 
          globalPercentage={globalPercentage}
          localPercentage={localPercentage}
          countryCode={userCountry}
        />
      )}

      {/* 3. Profile Drawer */}
      {user && (
        <ProfileDrawer user={user} mood={userMood} />
      )}

      {/* 4. Auth Overlay Layer */}
      <AnimatePresence>
        {!user && <AuthModal onSuccess={() => {}} />}
      </AnimatePresence>
    </main>
  );
}
