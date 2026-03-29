import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms of Service — Sappy",
  description: "Terms of Service for Sappy, the minimalist mood tracker.",
};

export default function TermsPage() {
  return (
    <main className="min-h-screen bg-white text-black">
      <div className="max-w-2xl mx-auto px-6 py-16">
        <h1
          className="text-3xl mb-2"
          style={{ fontFamily: "var(--font-dela)" }}
        >
          Terms of Service
        </h1>
        <p className="text-sm text-black/50 mb-8 font-medium">
          Last Updated: March 2026
        </p>

        <p className="text-[15px] leading-relaxed text-black/70 mb-8">
          Welcome to Sappy. By accessing or using our application, you agree to
          be bound by these Terms of Service and our Privacy Policy. If you do
          not agree to these terms, please do not use Sappy.
        </p>

        <section className="mb-8">
          <h2
            className="text-base mb-2"
            style={{ fontFamily: "var(--font-dela)" }}
          >
            1. Use of the App
          </h2>
          <p className="text-[15px] leading-relaxed text-black/70">
            Sappy is a digital mood-tracking application. You agree to use the
            app only for your personal, non-commercial use. You must be at least
            13 years old to use this service.
          </p>
        </section>

        <section className="mb-8">
          <h2
            className="text-base mb-2"
            style={{ fontFamily: "var(--font-dela)" }}
          >
            2. User Accounts
          </h2>
          <p className="text-[15px] leading-relaxed text-black/70">
            When you create an account, you must provide accurate information.
            You are solely responsible for safeguarding your password and for all
            activities that occur under your account.
          </p>
        </section>

        <section className="mb-8">
          <h2
            className="text-base mb-2"
            style={{ fontFamily: "var(--font-dela)" }}
          >
            3. User Data &amp; Content
          </h2>
          <p className="text-[15px] leading-relaxed text-black/70">
            All mood data you log belongs to you. We do not claim ownership of
            your emotional states. However, you grant us a license to securely
            store and process this data to provide the service.
          </p>
        </section>

        <section className="mb-8">
          <h2
            className="text-base mb-2"
            style={{ fontFamily: "var(--font-dela)" }}
          >
            4. Disclaimers
          </h2>
          <p className="text-[15px] leading-relaxed text-black/70">
            Sappy is not a medical device. It does not provide medical advice,
            diagnosis, or treatment. If you are experiencing a mental health
            crisis, please contact professional medical services or emergency
            responders immediately.
          </p>
        </section>

        <div className="pt-8 border-t border-black/10">
          <p className="text-sm text-black/40">
            © {new Date().getFullYear()} Neuval Studio. All rights reserved.
          </p>
        </div>
      </div>
    </main>
  );
}
