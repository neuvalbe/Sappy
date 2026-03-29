import type { Metadata } from "next";
import { Dela_Gothic_One } from "next/font/google";
import "./globals.css";

const delaGothicOne = Dela_Gothic_One({
  subsets: ["latin"],
  weight: "400",
  variable: "--font-dela",
});

export const metadata: Metadata = {
  title: "Sappy Tracker",
  description: "Worldwide minimalist mood tracking",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${delaGothicOne.className} ${delaGothicOne.variable} bg-black text-white antialiased`}>
        {children}
      </body>
    </html>
  );
}
