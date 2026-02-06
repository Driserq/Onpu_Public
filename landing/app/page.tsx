"use client";

import { useState } from "react";
import styles from "./page.module.css";

export default function Home() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  const faqs = [
    {
      q: "Does the app play the music for me?",
      a: "Nope! You play your own music in the background—Spotify, YouTube, Apple Music, whatever you like. Onpu is your study companion that sits alongside your player, showing you the lyrics breakdown while you listen.",
    },
    {
      q: "Do I need internet to look up words?",
      a: "Not at all. The entire Kanji database lives on your phone. Look up characters on the subway, on a plane, wherever. No signal required.",
    },
    {
      q: "Can I save words I want to learn?",
      a: "Yes! Long-press any Kanji to save it to your personal vocabulary list. Everything stays local on your device.",
    },
    {
      q: "How accurate is the pitch accent for songs?",
      a: "The app shows standard dictionary pitch patterns—the \"real\" pronunciation of each word. Singers often bend pitch for melody, but knowing the baseline helps you sound natural in conversation.",
    },
  ];

  return (
    <main className={styles.main}>
      {/* Navigation */}
      <nav className={styles.nav}>
        <div className={styles.navContent}>
          <a href="#" className={styles.logo}>Onpu</a>
          <div className={styles.navLinks}>
            <a href="#how-it-works">How It Works</a>
            <a href="#features">Features</a>
            <a href="#faq">FAQ</a>
          </div>
          <a href="#early-access" className={styles.navCta}>Get Early Access</a>
        </div>
      </nav>

      {/* Hero */}
      <section className={styles.hero}>
        <div className={styles.heroContent}>
          <div className={styles.badge}>🎵 Japanese Learning App</div>
          <h1 className={styles.headline}>
            The most fun way to learn pitch accent and break the{" "}
            <span className={styles.kanjiHighlight}>漢字</span> wall.
          </h1>
          <p className={styles.subheadline}>
            I love learning from songs, but pasting lyrics into three different
            apps just to understand one sentence killed the vibe.
          </p>
          <p className={styles.subheadline}>
            So I built a simple, offline tool that does it all in one place.
            Paste your lyrics, see the pitch accents instantly, and finally
            understand Kanji without pausing the music.
          </p>
          <button className={styles.cta}>Get Early Access</button>
        </div>
        <div className={styles.heroVisual}>
          <PhoneMockup />
        </div>
      </section>

      {/* How It Works */}
      <section id="how-it-works" className={styles.section}>
        <h2 className={styles.sectionTitle}>How It Works</h2>
        <div className={styles.steps}>
          <Step
            number="1"
            title="Pick a song you actually like"
            description="Forget the textbook dialogues. Grab the Japanese lyrics from that track you've had on repeat for weeks."
          />
          <Step
            number="2"
            title="Paste them in"
            description="Drop the text into the app. It instantly maps the English translation and highlights the pitch accents for you."
          />
          <Step
            number="3"
            title="Tap what confuses you"
            description="Don't know a character? Just tap it. The app breaks the Kanji down into its parts (radicals) so you can see the logic behind the scribbles."
          />
          <Step
            number="4"
            title="Sing along"
            description="Enjoy your music knowing what you're ACTUALLY singing about."
          />
        </div>
      </section>

      {/* Features */}
      <section id="features" className={`${styles.section} ${styles.featuresSection}`}>
        <h2 className={styles.sectionTitle}>Why I Built This</h2>
        <div className={styles.features}>
          <FeatureCard
            icon="🧩"
            title="Kanji that actually sticks"
            description="I hated rote memorization. It doesn't work. This tool breaks complex characters down into 'radicals'—the little building blocks—so you can turn strokes into a story you'll actually remember."
          />
          <FeatureCard
            icon="📈"
            title="Pitch accent you can see"
            description="Most resources ignore pitch accent, which is why so many of us struggle to sound natural. I built a visualizer that layers the pitch drops right over the lyrics, so you know exactly how to say it."
          />
          <FeatureCard
            icon="✈️"
            title="No loading screens"
            description="I wanted to study on the subway, so I made the whole thing work offline. The database lives on your phone. It's instant, snappy, and doesn't need a signal."
          />
          <FeatureCard
            icon="🎯"
            title='The "One-Screen" Flow'
            description="Stop switching between Spotify, Jisho, and Anki. I wanted to see the meaning, the reading, and the breakdown without losing my place in the song. Now you can too."
          />
        </div>
      </section>

      {/* FAQ */}
      <section id="faq" className={styles.section}>
        <h2 className={styles.sectionTitle}>FAQ</h2>
        <div className={styles.faqList}>
          {faqs.map((faq, i) => (
            <div
              key={i}
              className={`${styles.faqItem} ${openFaq === i ? styles.faqOpen : ""}`}
              onClick={() => setOpenFaq(openFaq === i ? null : i)}
            >
              <div className={styles.faqQuestion}>
                <span>{faq.q}</span>
                <span className={styles.faqChevron}>
                  {openFaq === i ? "−" : "+"}
                </span>
              </div>
              {openFaq === i && <p className={styles.faqAnswer}>{faq.a}</p>}
            </div>
          ))}
        </div>
      </section>

      {/* Final CTA */}
      <section id="early-access" className={styles.finalCta}>
        <h2>Ready to learn Japanese the fun way?</h2>
        <p>Join the waitlist and be the first to know when Onpu launches.</p>
        <button className={styles.cta}>Get Early Access</button>
      </section>

      {/* Footer */}
      <footer className={styles.footer}>
        <p>Made with 🎵 for Japanese learners everywhere</p>
      </footer>
    </main>
  );
}

function Step({
  number,
  title,
  description,
}: {
  number: string;
  title: string;
  description: string;
}) {
  return (
    <div className={styles.step}>
      <div className={styles.stepNumber}>{number}</div>
      <h3 className={styles.stepTitle}>{title}</h3>
      <p className={styles.stepDescription}>{description}</p>
    </div>
  );
}

function FeatureCard({
  icon,
  title,
  description,
}: {
  icon: string;
  title: string;
  description: string;
}) {
  return (
    <div className={styles.featureCard}>
      <div className={styles.featureIcon}>{icon}</div>
      <h3 className={styles.featureTitle}>{title}</h3>
      <p className={styles.featureDescription}>{description}</p>
    </div>
  );
}

function PhoneMockup() {
  return (
    <div className={styles.phoneMockup}>
      <div className={styles.phoneFrame}>
        <div className={styles.phoneNotch} />
        <div className={styles.phoneScreen}>
          {/* Mini app preview */}
          <div className={styles.previewToolbar}>
            <div className={styles.previewBack}>‹</div>
            <div className={styles.previewActions}>
              <div className={styles.previewBtn}>文</div>
              <div className={`${styles.previewBtn} ${styles.active}`}>〜</div>
            </div>
          </div>
          <div className={styles.previewContent}>
            <LyricLine
              japanese="夜に駆ける"
              reading="よるにかける"
              pitch={[1, 0, 0, 0, 0]}
              translation="Racing into the night"
              selected
            />
            <LyricLine
              japanese="君の声を"
              reading="きみのこえを"
              pitch={[0, 1, 0, 0, 0]}
              translation="Your voice"
            />
            <LyricLine
              japanese="追いかけて"
              reading="おいかけて"
              pitch={[0, 1, 1, 0, 0]}
              translation="Chasing after"
            />
          </div>
        </div>
      </div>
    </div>
  );
}

function LyricLine({
  japanese,
  reading,
  pitch,
  translation,
  selected,
}: {
  japanese: string;
  reading: string;
  pitch: number[];
  translation: string;
  selected?: boolean;
}) {
  return (
    <div className={`${styles.lyricLine} ${selected ? styles.selected : ""}`}>
      <div className={styles.lyricJapanese}>
        <div className={styles.pitchLine}>
          {pitch.map((p, i) => (
            <span
              key={i}
              className={`${styles.pitchDot} ${p ? styles.high : styles.low}`}
            />
          ))}
        </div>
        <span className={styles.lyricText}>{japanese}</span>
        <span className={styles.lyricReading}>{reading}</span>
      </div>
      {selected && (
        <div className={styles.lyricTranslation}>{translation}</div>
      )}
    </div>
  );
}
