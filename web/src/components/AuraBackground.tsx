"use client";

import { motion } from "framer-motion";

export type MoodType = "happy" | "sad" | "none" | null;

interface AuraBackgroundProps {
  mood: MoodType;
}

export default function AuraBackground({ mood }: AuraBackgroundProps) {
  // Determine colours via mood
  let bgColor = "#000000"; 
  let orbColor1 = "rgba(42, 42, 42, 0.5)"; // Dark grey default
  let orbColor2 = "rgba(30, 30, 30, 0.5)";
  let orbColor3 = "rgba(20, 20, 20, 0.5)";

  if (mood === "happy") {
    bgColor = "#FFFFFF"; // Crisp white
    orbColor1 = "rgba(253, 222, 8, 0.6)"; // Sappy Yellow
    orbColor2 = "rgba(253, 222, 8, 0.4)";
    orbColor3 = "rgba(253, 222, 8, 0.2)";
  } else if (mood === "sad") {
    bgColor = "#000000"; // Deep black
    orbColor1 = "rgba(102, 140, 199, 0.4)"; // Sappy Blue
    orbColor2 = "rgba(102, 140, 199, 0.3)";
    orbColor3 = "rgba(102, 140, 199, 0.2)";
  }

  return (
    <div
      className="fixed inset-0 z-0 overflow-hidden transition-colors duration-[2000ms] ease-in-out"
      style={{ backgroundColor: bgColor }}
    >
      {/* 
        SVG Film Grain / Noise Overlay 
        Creates a physical, textured cinematic feel cutting through the digital gradient banding.
      */}
      <svg className="hidden">
        <filter id="noiseFilter">
          <feTurbulence
            type="fractalNoise"
            baseFrequency="0.75"
            numOctaves="3"
            stitchTiles="stitch"
          />
        </filter>
      </svg>
      <div
        className="absolute inset-0 z-10 pointer-events-none opacity-[0.25]"
        style={{ filter: "url(#noiseFilter)" }}
      ></div>

      {/* 
        Organic Plasma Orbs 
        These drift around softly in the background. The CSS blur + SVG noise makes it feel incredibly premium.
      */}
      
      {/* Top Left Orb */}
      <motion.div
        className="absolute top-[-10%] left-[-10%] w-[70vw] h-[70vw] rounded-full mix-blend-normal"
        style={{
          background: `radial-gradient(circle, ${orbColor1} 0%, transparent 70%)`,
          filter: "blur(60px)",
        }}
        animate={{
          x: ["0vw", "10vw", "-5vw", "0vw"],
          y: ["0vh", "15vh", "-5vh", "0vh"],
          scale: [1, 1.1, 0.9, 1],
        }}
        transition={{
          duration: 18,
          repeat: Infinity,
          ease: "easeInOut",
        }}
      />

      {/* Bottom Right Orb */}
      <motion.div
        className="absolute bottom-[-20%] right-[-10%] w-[80vw] h-[80vw] rounded-full mix-blend-normal"
        style={{
          background: `radial-gradient(circle, ${orbColor2} 0%, transparent 70%)`,
          filter: "blur(80px)",
        }}
        animate={{
          x: ["0vw", "-15vw", "5vw", "0vw"],
          y: ["0vh", "-20vh", "10vh", "0vh"],
          scale: [1, 1.2, 0.95, 1],
        }}
        transition={{
          duration: 22,
          repeat: Infinity,
          ease: "easeInOut",
        }}
      />

      {/* Center Roaming Orb */}
      <motion.div
        className="absolute top-[30%] left-[20%] w-[60vw] h-[60vw] rounded-full mix-blend-normal"
        style={{
          background: `radial-gradient(circle, ${orbColor3} 0%, transparent 70%)`,
          filter: "blur(70px)",
        }}
        animate={{
          x: ["0vw", "20vw", "-15vw", "0vw"],
          y: ["0vh", "-10vh", "15vh", "0vh"],
          scale: [1, 1.05, 1.15, 1],
        }}
        transition={{
          duration: 25,
          repeat: Infinity,
          ease: "easeInOut",
        }}
      />
    </div>
  );
}
