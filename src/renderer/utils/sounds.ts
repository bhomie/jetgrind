// Sound utility for playing audio feedback
// Uses Web Audio API for reliable playback

type SoundType = 'complete' | 'start' | 'tick' | 'levelUp' | 'coin';

// Base64 encoded simple sounds (generated procedurally)
// These are placeholder sounds - can be replaced with real audio files later
const SOUND_FREQUENCIES: Record<SoundType, number[]> = {
  complete: [523.25, 659.25, 783.99], // C5, E5, G5 - happy chord
  start: [440, 523.25], // A4, C5 - alert
  tick: [880], // A5 - short tick
  levelUp: [523.25, 659.25, 783.99, 1046.5], // C5, E5, G5, C6 - fanfare
  coin: [1318.5, 1567.98], // E6, G6 - coin collect
};

const SOUND_DURATIONS: Record<SoundType, number> = {
  complete: 0.3,
  start: 0.15,
  tick: 0.05,
  levelUp: 0.4,
  coin: 0.15,
};

let audioContext: AudioContext | null = null;

function getAudioContext(): AudioContext {
  if (!audioContext) {
    audioContext = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
  }
  return audioContext;
}

export function playSound(type: SoundType, volume: number = 0.5): void {
  try {
    const ctx = getAudioContext();
    const frequencies = SOUND_FREQUENCIES[type];
    const duration = SOUND_DURATIONS[type];

    frequencies.forEach((freq, index) => {
      const oscillator = ctx.createOscillator();
      const gainNode = ctx.createGain();

      oscillator.connect(gainNode);
      gainNode.connect(ctx.destination);

      oscillator.frequency.value = freq;
      oscillator.type = type === 'tick' ? 'square' : 'sine';

      // Stagger notes slightly for chord effect
      const startTime = ctx.currentTime + index * 0.05;
      const endTime = startTime + duration;

      gainNode.gain.setValueAtTime(0, startTime);
      gainNode.gain.linearRampToValueAtTime(volume * 0.3, startTime + 0.01);
      gainNode.gain.exponentialRampToValueAtTime(0.001, endTime);

      oscillator.start(startTime);
      oscillator.stop(endTime);
    });
  } catch (error) {
    console.warn('Failed to play sound:', error);
  }
}

export function playTimerComplete(): void {
  playSound('complete', 0.6);
}

export function playTimerStart(): void {
  playSound('start', 0.4);
}

export function playLevelUp(): void {
  playSound('levelUp', 0.7);
}

export function playCoinCollect(): void {
  playSound('coin', 0.5);
}

// Preload audio context on user interaction
export function initAudio(): void {
  try {
    getAudioContext();
  } catch {
    // Audio context will be created on first sound play
  }
}
