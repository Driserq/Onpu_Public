export type LyricsJobStatus = 'queued' | 'running' | 'succeeded' | 'failed';

export type LyricsJobStage = 'translating' | 'lyrics_data' | 'finalizing';

export type MoraData = {
  text: string;
  isHigh: boolean;
};

export type KanjiFurigana = {
  kanji: string;
  reading: string;
};

export type WordData = {
  kanji?: string | null;
  furigana: string;
  mora: MoraData[];
  kanjiFurigana?: KanjiFurigana[];
};

export type LyricsLine = {
  words: WordData[];
};

export type LyricsJobResult = {
  translations: Record<string, string>;
  lyricsData: Record<string, LyricsLine | string>; // string for compact format
};

export type LyricsJobView = {
  jobId: string;
  status: LyricsJobStatus;
  stage?: LyricsJobStage;
  updatedAt?: number;
  result?: LyricsJobResult;
  error?: string;
};

export type JobChange = {
  jobId: string;
  status: LyricsJobStatus | string;
  stage?: LyricsJobStage;
  updatedAt: number;
  error?: string;
};

export type LongpollResponse = {
  changes: JobChange[];
  hasPending: boolean;
};

export type RecentResponse = {
  changes: JobChange[];
};
