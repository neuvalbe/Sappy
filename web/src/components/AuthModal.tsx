"use client";

import { useState } from "react";
import { auth } from "../lib/firebase";
import {
  signInWithEmailAndPassword,
  sendPasswordResetEmail,
} from "firebase/auth";

interface AuthModalProps {
  onSuccess: () => void;
}

/**
 * Sign-in only auth modal for the web companion.
 * No sign-up — users create accounts via the iOS app.
 */
export default function AuthModal({ onSuccess }: AuthModalProps) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isForgotPassword, setIsForgotPassword] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccessMessage(null);

    try {
      if (isForgotPassword) {
        await sendPasswordResetEmail(auth, email);
        setSuccessMessage("Reset link sent! Please check your inbox.");
        setTimeout(() => setIsForgotPassword(false), 3000);
      } else {
        await signInWithEmailAndPassword(auth, email, password);
        onSuccess();
      }
    } catch (err: any) {
      let msg = "An unexpected error occurred.";
      const code = err.code;
      if (code === "auth/invalid-email")
        msg = "Please enter a valid email address.";
      else if (
        code === "auth/wrong-password" ||
        code === "auth/invalid-credential"
      )
        msg = "Incorrect email or password.";
      else if (code === "auth/user-not-found")
        msg = "No account found with this email.";
      else if (code === "auth/network-request-failed")
        msg = "Network error. Check your connection.";
      else if (code === "auth/too-many-requests")
        msg = "Too many attempts. Try again later.";
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-[20px] p-4 text-[#33322E]">
      <div className="relative w-full max-w-[420px] rounded-[24px] bg-white p-[40px] shadow-xl">
        <div className="mb-8 text-center mt-2">
          <h2 className="text-[28px] leading-tight">
            {isForgotPassword ? "Reset Password" : "Welcome Back"}
          </h2>
          <p className="mt-2 text-[14px] opacity-50">
            {isForgotPassword 
              ? "Enter your email to receive a reset link." 
              : "Sign in to see how the world feels."}
          </p>
        </div>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="h-[56px] w-full rounded-[16px] border border-black/10 bg-black/5 px-4 outline-none focus:border-black/30 transition-colors"
            required
          />
          {!isForgotPassword && (
            <input
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="h-[56px] w-full rounded-[16px] border border-black/10 bg-black/5 px-4 outline-none focus:border-black/30 transition-colors"
              required
              minLength={6}
            />
          )}

          {!isForgotPassword && (
            <div className="flex justify-end mt-[-8px]">
              <button
                type="button"
                onClick={() => { setIsForgotPassword(true); setError(null); setSuccessMessage(null); }}
                className="text-[13px] text-[#33322E] opacity-60 hover:opacity-100 transition-opacity"
              >
                Forgot password?
              </button>
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="mt-2 relative flex h-[56px] w-full items-center justify-center rounded-[16px] bg-[#33322E] text-white transition-opacity disabled:opacity-50 hover:bg-[#1a1917]"
          >
            <span
              className={`transition-opacity ${loading ? "opacity-0" : "opacity-100"}`}
            >
              {isForgotPassword ? "Send Reset Link" : "Sign In"}
            </span>
            {loading && (
              <div className="absolute inset-0 flex items-center justify-center">
                <span className="h-5 w-5 animate-spin rounded-full border-2 border-white/20 border-t-white"></span>
              </div>
            )}
          </button>
        </form>

        {error && (
          <p className="mt-4 text-center text-[14px] text-red-500 opacity-80">
            {error}
          </p>
        )}

        {successMessage && (
          <p className="mt-4 text-center text-[14px] text-green-600 opacity-90">
            {successMessage}
          </p>
        )}

        <div className="mt-6 flex flex-col items-center justify-center gap-2 text-center text-[14px] opacity-40">
          {isForgotPassword ? (
            <button
              onClick={() => { setIsForgotPassword(false); setError(null); setSuccessMessage(null); }}
              className="font-bold hover:underline opacity-100 text-[#33322E]"
            >
              Wait, I remember my password
            </button>
          ) : (
            <div>
              Don&apos;t have an account?{" "}
              <a
                href="https://apps.apple.com/app/sappy"
                target="_blank"
                rel="noopener noreferrer"
                className="font-bold hover:underline opacity-100 text-[#33322E]"
              >
                Download the app
              </a>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
