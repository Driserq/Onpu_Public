import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Onpu - Learn Japanese Through Songs",
  description:
    "The most fun way to learn pitch accent and break the Kanji wall. Paste lyrics, see pitch accents instantly, and understand Kanji without pausing the music.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body suppressHydrationWarning>{children}</body>
    </html>
  );
}
