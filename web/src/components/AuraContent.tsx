"use client";

import { motion, AnimatePresence } from "framer-motion";
import { MoodType } from "./AuraBackground";

interface CountryCount {
  code: string;
  count: number;
}

interface AuraContentProps {
  mood: MoodType | null; 
  globalCount: number;
  countries: CountryCount[];
}

export default function AuraContent({ mood, globalCount, countries }: AuraContentProps) {
  // If no auth state yet, show nothing
  if (mood === null) return null;

  const isDarkBg = mood === "sad" || mood === "none";
  const textColor = isDarkBg ? "text-white" : "text-black";
  const accentColor =
    mood === "happy"
      ? "text-[var(--color-accent-happy)]"
      : "text-[var(--color-accent-sad)]"; // Though we just use tailwind hex classes now if we want, or inline.
      
  const accentClass = mood === "happy" ? "text-[#FDDE08]" : "text-[#668CC7]";

  const getFlagEmoji = (countryCode: string) => {
    if (!countryCode) return "";
    return String.fromCodePoint(
      ...countryCode
        .toUpperCase()
        .split("")
        .map((c) => 127397 + c.charCodeAt(0))
    );
  };

  const displayCount = Math.max(1, globalCount);

  // Staggered cinematic reveal
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: { 
        staggerChildren: 0.15, 
        delayChildren: 0.4,
        duration: 1
      },
    },
    exit: { opacity: 0, transition: { duration: 0.4 } },
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 30, filter: "blur(4px)" },
    visible: {
      opacity: 1,
      y: 0,
      filter: "blur(0px)",
      transition: { duration: 1.2, ease: [0.16, 1, 0.3, 1] as [number, number, number, number] }, 
    },
  };

  return (
    <div className="absolute inset-0 z-20 flex flex-col items-center justify-center pointer-events-none">
      <AnimatePresence mode="wait">
        {/* HAS MOOD STATE */}
        {(mood === "happy" || mood === "sad") && (
          <motion.div
            key="has-mood"
            className={`w-full flex-col flex items-center justify-center ${textColor}`}
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            exit="exit"
          >
            {/* The Monolith Typography */}
            <motion.h1 
              variants={itemVariants}
              className="text-[56px] sm:text-[80px] md:text-[140px] lg:text-[200px] xl:text-[240px] leading-none tracking-tight"
            >
              {mood}.
            </motion.h1>

            {/* Global Stats Footer */}
            <motion.div 
              variants={itemVariants}
              className="absolute bottom-8 sm:bottom-12 left-0 right-0 flex flex-col items-center gap-2 pointer-events-auto px-4"
            >
              <p className="text-[13px] sm:text-[16px] md:text-[20px] opacity-60 font-light tracking-wide text-center">
                <span className={`font-bold opacity-100 ${accentClass}`}>
                  {displayCount.toLocaleString()}
                </span>{" "}
                others feel this right now
              </p>

              {/* Country breakdown pills */}
              {countries.length > 0 && (
                <div className="flex gap-1.5 sm:gap-2 mt-2 sm:mt-4 flex-wrap max-w-lg justify-center">
                  {countries.slice(0, 5).map((c) => (
                    <div
                      key={c.code}
                      className="flex items-center gap-1.5 px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-full border border-current opacity-40 hover:opacity-100 transition-opacity backdrop-blur-sm"
                    >
                      <span className="text-[12px] sm:text-[14px]">{getFlagEmoji(c.code)}</span>
                      <span className="text-[10px] sm:text-[12px]">{c.count.toLocaleString()}</span>
                    </div>
                  ))}
                </div>
              )}
            </motion.div>
          </motion.div>
        )}

        {/* NOT VOTED STATE */}
        {mood === "none" && (
          <motion.div
            key="no-mood"
            className={`w-full max-w-[800px] px-6 flex-col flex items-center justify-center text-center ${textColor}`}
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            exit="exit"
          >
            <motion.h2
              variants={itemVariants}
              className="text-[28px] sm:text-[40px] md:text-[56px] lg:text-[72px] leading-[1.1] tracking-tight mb-6 sm:mb-8"
            >
              TELL THE WORLD<br />HOW YOU FEEL
            </motion.h2>

            <motion.div variants={itemVariants} className="pointer-events-auto">
              {/* Very sleek premium download button */}
              <a 
                href="https://apps.apple.com/app/sappy" 
                target="_blank" 
                rel="noopener noreferrer"
                className="group relative flex items-center justify-center gap-3 px-8 py-5 bg-white text-black rounded-full overflow-hidden transition-transform active:scale-95"
              >
                <div className="absolute inset-0 bg-[#FDDE08] translate-y-[100%] group-hover:translate-y-0 transition-transform duration-500 ease-[0.16,1,0.3,1]"></div>
                <span className="relative z-10 text-[18px] font-bold tracking-wide uppercase">
                  Download Sappy
                </span>
                <svg className="relative z-10 w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                </svg>
              </a>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
