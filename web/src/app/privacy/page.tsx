import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy — Sappy",
  description: "Privacy Policy for Sappy, the minimalist mood tracker.",
};

export default function PrivacyPage() {
  return (
    <main className="min-h-screen bg-white text-black">
      <div className="max-w-2xl mx-auto px-6 py-16">
        <h1
          className="text-3xl mb-2"
          style={{ fontFamily: "var(--font-dela)" }}
        >
          Privacy Policy
        </h1>
        <p className="text-sm text-black/50 mb-8 font-medium">
          Last Updated: March 2026
        </p>

        <p className="text-[15px] leading-relaxed text-black/70 mb-8">
          Your privacy is immensely important to us. Because we deal with your
          emotions, we handle your data with the highest level of care and
          security.
        </p>

        <section className="mb-8">
          <h2
            className="text-base mb-2"
            style={{ fontFamily: "var(--font-dela)" }}
          >
            1. Information We Collect
          </h2>
          <p className="text-[15px] leading-relaxed text-black/70">
            We collect the information you provide directly to us (such as your
            name and email address when creating an account) and the mood states
            (&apos;happy&apos; or &apos;sad&apos;) that you log within the app.
          </p>
        </section>

        <section className="mb-8">
          <h2
            className="text-base mb-2"
            style={{ fontFamily: "var(--font-dela)" }}
          >
            2. How We Use Information
          </h2>
          <p className="text-[15px] leading-relaxed text-black/70">
            We use the information we collect strictly to provide, maintain, and
            improve the Sappy application. We do not sell your personal data or
            emotional logs to any third-party advertisers.
          </p>
        </section>

        <section className="mb-8">
          <h2
            className="text-base mb-2"
            style={{ fontFamily: "var(--font-dela)" }}
          >
            3. Data Security
          </h2>
          <p className="text-[15px] leading-relaxed text-black/70">
            We implement robust structural security measures to protect your
            data from unauthorized access, alteration, disclosure, or
            destruction. However, no internet transmission is entirely secure.
          </p>
        </section>

        <section className="mb-8">
          <h2
            className="text-base mb-2"
            style={{ fontFamily: "var(--font-dela)" }}
          >
            4. Your Rights
          </h2>
          <p className="text-[15px] leading-relaxed text-black/70">
            You have the right to access, update, or delete your information at
            any time. You may request the total deletion of your account and all
            associated mood history by contacting our support team.
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
