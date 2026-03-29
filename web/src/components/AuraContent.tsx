"use client";

import { motion, AnimatePresence } from "framer-motion";
import { MoodType } from "./AuraBackground";

interface AuraContentProps {
  mood: MoodType | null; 
  globalPercentage: number;
  localPercentage: number;
  countryCode: string;
}

export default function AuraContent({ mood, globalPercentage, localPercentage, countryCode }: AuraContentProps) {
  // If no auth state yet, show nothing
  if (mood === null) return null;

  const isDarkBg = mood === "sad" || mood === "none";
  const textColor = isDarkBg ? "text-white" : "text-black";
  const accentColor =
    mood === "happy"
      ? "text-[var(--color-accent-happy)]"
      : "text-[var(--color-accent-sad)]"; // Though we just use tailwind hex classes now if we want, or inline.
      
  const accentClass = mood === "happy" ? "text-[#FDDE08]" : "text-[#668CC7]";

  let countryName = countryCode;
  try {
    if (countryCode) {
      const regionNames = new Intl.DisplayNames(['en'], { type: 'region' });
      countryName = regionNames.of(countryCode) || countryCode;
    }
  } catch (e) {
    // fallback
  }

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

            {/* Percentage Stats Footer */}
            <motion.div 
              variants={itemVariants}
              className="absolute bottom-8 sm:bottom-12 left-0 right-0 flex flex-col items-center gap-6 pointer-events-auto px-4"
            >
              {/* Primary Metric: Global Percentage */}
              <div className="flex flex-col items-center gap-2">
                <p className={`text-[20px] sm:text-[24px] tracking-wide ${textColor} ${mood === "happy" ? "opacity-85" : "opacity-100"}`}>
                  {globalPercentage}% of the world
                </p>
                <p className={`text-[14px] sm:text-[16px] tracking-wide ${accentClass} drop-shadow-md`}>
                  feels {mood} right now
                </p>
              </div>

              {/* Secondary Metric: Local Percentage */}
              <p className={`text-[12px] sm:text-[14px] text-center tracking-wide ${textColor} ${mood === "happy" ? "opacity-60" : "opacity-70"}`}>
                {localPercentage}% of people in {countryName} also feel {mood}
              </p>
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
