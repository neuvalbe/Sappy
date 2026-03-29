"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { signOut, deleteUser, User } from "firebase/auth";
import { doc, deleteDoc, getDoc, writeBatch, increment, serverTimestamp } from "firebase/firestore";
import { auth, db } from "../lib/firebase";
import { MoodType } from "./AuraBackground";

interface ProfileDrawerProps {
  user: User;
  mood: MoodType;
}

type LegalSection = "none" | "terms" | "privacy";

export default function ProfileDrawer({ user, mood }: ProfileDrawerProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [legalView, setLegalView] = useState<LegalSection>("none");
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Derive user info
  const isDarkBg = mood === "sad" || mood === "none" || mood === null;
  const buttonColor = isDarkBg ? "text-white" : "text-black";

  const userInitial = (() => {
    if (user.displayName) return user.displayName[0].toUpperCase();
    if (user.email) return user.email[0].toUpperCase();
    return "?";
  })();

  const displayName = user.displayName || "Sappy User";
  const displayEmail = (() => {
    if (user.email) return user.email;
    const providers = user.providerData.map((p) => p.providerId);
    if (providers.includes("apple.com")) return "Signed in with Apple";
    return "Signed in";
  })();

  const moodLabel =
    mood === "happy" ? "Happy" : mood === "sad" ? "Sad" : null;

  // Actions
  const handleSignOut = async () => {
    try {
      await signOut(auth);
    } catch (err) {
      console.error("[Sappy] Sign out error:", err);
    }
  };

  const handleDeleteAccount = async () => {
    if (!user) return;
    setIsDeleting(true);
    setError(null);

    try {
      const userDocRef = doc(db, "users", user.uid);
      const metricsRef = doc(db, "metrics", "global_counts");

      // Step 1: Read current mood + country to know what to retract
      const userSnap = await getDoc(userDocRef);
      const userData = userSnap.exists() ? userSnap.data() : null;
      const activeMood = userData?.mood;
      const userCountry = userData?.country;

      // Step 2: Retract active vote via atomic WriteBatch (mirrors iOS retractVote)
      if (activeMood === "happy" || activeMood === "sad") {
        const batch = writeBatch(db);

        // Decrement global counts
        batch.update(metricsRef, {
          [`total_${activeMood}`]: increment(-1),
          ...(userCountry
            ? { [`countries.${userCountry}.${activeMood}`]: increment(-1) }
            : {}),
        });

        // Clear mood in user doc
        batch.update(userDocRef, {
          mood: "",
          updatedAt: serverTimestamp(),
        });

        await batch.commit();
      }

      // Step 3: Delete Firestore user document
      await deleteDoc(userDocRef);

      // Step 4: Delete Firebase Auth account (LAST — invalidates token)
      await deleteUser(user);
    } catch (err: any) {
      setIsDeleting(false);
      if (err.code === "auth/requires-recent-login") {
        setError(
          "For security, please sign out, sign back in, then try again."
        );
      } else {
        setError("Failed to delete account. Please try again.");
      }
      console.error("[Sappy] Delete account error:", err);
    }
  };

  // Overlay variants
  const overlayVariants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1 },
  };

  const drawerVariants = {
    hidden: { x: "100%" },
    visible: {
      x: 0,
      transition: { type: "spring" as const, damping: 30, stiffness: 300 },
    },
    exit: {
      x: "100%",
      transition: { type: "spring" as const, damping: 30, stiffness: 300 },
    },
  };

  return (
    <>
      {/* Profile Trigger Button — top right corner */}
      <button
        onClick={() => setIsOpen(true)}
        className={`fixed top-4 right-4 sm:top-6 sm:right-6 z-30 flex items-center justify-center w-11 h-11 rounded-full backdrop-blur-xl transition-all hover:scale-110 active:scale-95 ${buttonColor}`}
        style={{
          backgroundColor: isDarkBg ? "rgba(255,255,255,0.12)" : "rgba(0,0,0,0.08)",
          border: isDarkBg ? "1px solid rgba(255,255,255,0.15)" : "1px solid rgba(0,0,0,0.1)",
          boxShadow: isDarkBg
            ? "0 2px 12px rgba(0,0,0,0.3)"
            : "0 2px 12px rgba(0,0,0,0.08)",
        }}
        aria-label="Open profile"
      >
        <span className="text-[14px] font-bold">{userInitial}</span>
      </button>

      {/* Drawer */}
      <AnimatePresence>
        {isOpen && (
          <>
            {/* Backdrop */}
            <motion.div
              className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm"
              variants={overlayVariants}
              initial="hidden"
              animate="visible"
              exit="hidden"
              onClick={() => {
                if (legalView !== "none") {
                  setLegalView("none");
                } else {
                  setIsOpen(false);
                }
              }}
            />

            {/* Panel */}
            <motion.div
              className="fixed top-0 right-0 bottom-0 z-50 w-full max-w-[440px] bg-white text-[#33322E] flex flex-col overflow-hidden"
              variants={drawerVariants}
              initial="hidden"
              animate="visible"
              exit="exit"
            >
              {/* Legal Detail View */}
              <AnimatePresence mode="wait">
                {legalView !== "none" ? (
                  <motion.div
                    key="legal-detail"
                    className="flex flex-col h-full"
                    initial={{ opacity: 0, x: 40 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: 40 }}
                    transition={{ duration: 0.25, ease: [0.16, 1, 0.3, 1] as [number, number, number, number] }}
                  >
                    {/* Legal Header */}
                    <div className="flex items-center gap-3 px-6 pt-6 pb-4 border-b border-black/5">
                      <button
                        onClick={() => setLegalView("none")}
                        className="flex items-center justify-center w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 transition-colors"
                        aria-label="Back"
                      >
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
                        </svg>
                      </button>
                      <h2 className="text-[18px] font-bold">
                        {legalView === "terms"
                          ? "Terms of Service"
                          : "Privacy Policy"}
                      </h2>
                    </div>

                    {/* Legal Content */}
                    <div className="flex-1 overflow-y-auto px-6 py-6">
                      {legalView === "terms" && <TermsContent />}
                      {legalView === "privacy" && <PrivacyContent />}
                    </div>
                  </motion.div>
                ) : (
                  <motion.div
                    key="profile-main"
                    className="flex flex-col h-full"
                    initial={{ opacity: 0, x: -40 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -40 }}
                    transition={{ duration: 0.25, ease: [0.16, 1, 0.3, 1] as [number, number, number, number] }}
                  >
                    {/* Header */}
                    <div className="flex items-center justify-between px-6 pt-6 pb-2">
                      <h2 className="text-[18px] font-bold">Profile</h2>
                      <button
                        onClick={() => setIsOpen(false)}
                        className="flex items-center justify-center w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 transition-colors"
                        aria-label="Close profile"
                      >
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </button>
                    </div>

                    {/* Content */}
                    <div className="flex-1 overflow-y-auto px-6 py-4">
                      {/* User Card */}
                      <div className="flex flex-col items-center pt-4 pb-8">
                        <div className="flex items-center justify-center w-[72px] h-[72px] rounded-full bg-black/[0.06] mb-3">
                          <span className="text-[28px] font-bold">{userInitial}</span>
                        </div>
                        <p className="text-[18px] font-bold">{displayName}</p>
                        <p className="text-[14px] opacity-40 mt-1">{displayEmail}</p>
                      </div>

                      {/* Current Mood */}
                      {moodLabel && (
                        <div className="flex items-center justify-between px-5 py-4 rounded-2xl bg-black/[0.03] mb-6">
                          <span className="text-[14px] opacity-50">Current mood</span>
                          <div className="flex items-center gap-2">
                            <span
                              className="w-2.5 h-2.5 rounded-full"
                              style={{
                                backgroundColor:
                                  mood === "happy" ? "#FDDE08" : "#668CC7",
                              }}
                            />
                            <span className="text-[14px] font-bold">
                              {moodLabel}
                            </span>
                          </div>
                        </div>
                      )}

                      {/* Legal Links */}
                      <div className="mb-6">
                        <p className="text-[12px] uppercase tracking-[0.1em] opacity-30 mb-3 px-1">
                          Legal
                        </p>
                        <button
                          onClick={() => setLegalView("terms")}
                          className="flex items-center justify-between w-full px-5 py-4 rounded-2xl bg-black/[0.03] hover:bg-black/[0.06] transition-colors mb-2 text-left"
                        >
                          <span className="text-[14px]">Terms of Service</span>
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="opacity-30">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                          </svg>
                        </button>
                        <button
                          onClick={() => setLegalView("privacy")}
                          className="flex items-center justify-between w-full px-5 py-4 rounded-2xl bg-black/[0.03] hover:bg-black/[0.06] transition-colors text-left"
                        >
                          <span className="text-[14px]">Privacy Policy</span>
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="opacity-30">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                          </svg>
                        </button>
                      </div>

                      {/* Support */}
                      <div className="mb-8">
                        <p className="text-[12px] uppercase tracking-[0.1em] opacity-30 mb-3 px-1">
                          Support
                        </p>
                        <a
                          href="mailto:info@neuval.be"
                          className="flex items-center justify-between w-full px-5 py-4 rounded-2xl bg-black/[0.03] hover:bg-black/[0.06] transition-colors"
                        >
                          <span className="text-[14px]">Contact Support</span>
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="opacity-30">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                            <polyline points="22,6 12,13 2,6" strokeLinecap="round" strokeLinejoin="round" />
                          </svg>
                        </a>
                      </div>

                      {/* Error */}
                      {error && (
                        <p className="text-[13px] text-red-500 text-center mb-4 opacity-80">
                          {error}
                        </p>
                      )}
                    </div>

                    {/* Actions — pinned to bottom */}
                    <div className="px-6 pb-8 pt-4 border-t border-black/5 flex flex-col gap-3">
                      <button
                        onClick={handleSignOut}
                        className="flex items-center justify-center h-[52px] w-full rounded-2xl border border-black/10 bg-black/[0.03] text-[15px] font-bold hover:bg-black/[0.06] transition-colors"
                      >
                        Sign Out
                      </button>

                      <button
                        onClick={() => setShowDeleteConfirm(true)}
                        disabled={isDeleting}
                        className="flex items-center justify-center h-[52px] w-full rounded-2xl bg-red-500/10 text-red-500 text-[15px] font-bold hover:bg-red-500/20 transition-colors disabled:opacity-40"
                      >
                        {isDeleting ? (
                          <span className="h-5 w-5 animate-spin rounded-full border-2 border-red-500/20 border-t-red-500" />
                        ) : (
                          "Delete Account"
                        )}
                      </button>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Delete Confirmation Dialog */}
      <AnimatePresence>
        {showDeleteConfirm && (
          <motion.div
            className="fixed inset-0 z-[60] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <motion.div
              className="w-full max-w-[360px] bg-white rounded-3xl p-8 text-center"
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              transition={{ type: "spring", damping: 25, stiffness: 300 }}
            >
              <h3 className="text-[20px] font-bold text-[#33322E] mb-2">
                Delete Account?
              </h3>
              <p className="text-[14px] text-[#33322E] opacity-50 mb-6 leading-relaxed">
                This will permanently delete your account and all associated
                data. This cannot be undone.
              </p>
              <div className="flex flex-col gap-3">
                <button
                  onClick={() => {
                    setShowDeleteConfirm(false);
                    handleDeleteAccount();
                  }}
                  className="h-[48px] w-full rounded-2xl bg-red-500 text-white text-[15px] font-bold hover:bg-red-600 transition-colors"
                >
                  Delete Permanently
                </button>
                <button
                  onClick={() => setShowDeleteConfirm(false)}
                  className="h-[48px] w-full rounded-2xl bg-black/[0.04] text-[#33322E] text-[15px] font-bold hover:bg-black/[0.08] transition-colors"
                >
                  Cancel
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}

// ─── Legal Content Components ────────────────────────────────────────────────

function SectionTitle({ children }: { children: React.ReactNode }) {
  return (
    <h3 className="text-[15px] font-bold mt-6 mb-2">{children}</h3>
  );
}

function SectionText({ children }: { children: React.ReactNode }) {
  return (
    <p className="text-[14px] leading-[1.7] opacity-60">{children}</p>
  );
}

function TermsContent() {
  return (
    <div>
      <p className="text-[12px] opacity-30 mb-4">Last Updated: March 2026</p>
      <SectionText>
        Welcome to Sappy. By accessing or using our application, you agree to be
        bound by these Terms of Service and our Privacy Policy. If you do not
        agree to these terms, please do not use Sappy.
      </SectionText>

      <SectionTitle>1. Use of the App</SectionTitle>
      <SectionText>
        Sappy is a digital mood-tracking application. You agree to use the app
        only for your personal, non-commercial use. You must be at least 13
        years old to use this service.
      </SectionText>

      <SectionTitle>2. User Accounts</SectionTitle>
      <SectionText>
        When you create an account, you must provide accurate information. You
        are solely responsible for safeguarding your password and for all
        activities that occur under your account.
      </SectionText>

      <SectionTitle>3. User Data &amp; Content</SectionTitle>
      <SectionText>
        All mood data you log belongs to you. We do not claim ownership of your
        emotional states. However, you grant us a license to securely store and
        process this data to provide the service.
      </SectionText>

      <SectionTitle>4. Disclaimers</SectionTitle>
      <SectionText>
        Sappy is not a medical device. It does not provide medical advice,
        diagnosis, or treatment. If you are experiencing a mental health crisis,
        please contact professional medical services or emergency responders
        immediately.
      </SectionText>
    </div>
  );
}

function PrivacyContent() {
  return (
    <div>
      <SectionText>
        Your privacy is immensely important to us. Because we deal with your
        emotions, we handle your data with the highest level of care and
        security.
      </SectionText>

      <SectionTitle>1. Information We Collect</SectionTitle>
      <SectionText>
        We collect the information you provide directly to us (such as your name
        and email address when creating an account) and the mood states
        (&quot;happy&quot; or &quot;sad&quot;) that you log within the app.
      </SectionText>

      <SectionTitle>2. How We Use Information</SectionTitle>
      <SectionText>
        We use the information we collect strictly to provide, maintain, and
        improve the Sappy application. We do not sell your personal data or
        emotional logs to any third-party advertisers.
      </SectionText>

      <SectionTitle>3. Data Security</SectionTitle>
      <SectionText>
        We implement robust structural security measures to protect your data
        from unauthorized access, alteration, disclosure, or destruction.
        However, no internet transmission is entirely secure.
      </SectionText>

      <SectionTitle>4. Your Rights</SectionTitle>
      <SectionText>
        You have the right to access, update, or delete your information at any
        time. You may request the total deletion of your account and all
        associated mood history by contacting our support team.
      </SectionText>
    </div>
  );
}
