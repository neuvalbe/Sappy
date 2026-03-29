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
  const [countriesLists, setCountriesLists] = useState<{
    happy: CountryData[];
    sad: CountryData[];
  }>({ happy: [], sad: [] });

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
              const moodValue = snap.exists() ? snap.data().mood : null;
              if (moodValue === "happy" || moodValue === "sad") {
                setUserMood(moodValue);
              } else {
                setUserMood("none"); // Authenticated but no mood
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
                const countryArray = Object.keys(countriesObj).map((code) => ({
                  code,
                  happy: Math.max(0, countriesObj[code]?.happy || 0),
                  sad: Math.max(0, countriesObj[code]?.sad || 0),
                }));

                setCountriesLists({
                  happy: countryArray
                    .map((c) => ({ code: c.code, count: c.happy }))
                    .filter((c) => c.count > 0)
                    .sort((a, b) => b.count - a.count),
                  sad: countryArray
                    .map((c) => ({ code: c.code, count: c.sad }))
                    .filter((c) => c.count > 0)
                    .sort((a, b) => b.count - a.count),
                });
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

  const activeCount = userMood === "happy" ? globalCounts.happy : userMood === "sad" ? globalCounts.sad : 0;
  const activeCountries = userMood === "happy" ? countriesLists.happy : userMood === "sad" ? countriesLists.sad : [];

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
          globalCount={activeCount} 
          countries={activeCountries} 
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
