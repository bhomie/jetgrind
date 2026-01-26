/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/renderer/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        // Kawaii 90s anime color palette
        primary: {
          50: '#fef1f7',
          100: '#fee5f0',
          200: '#fecce3',
          300: '#ffa2cb',
          400: '#ff69a8',
          500: '#fa3a84',
          600: '#ea1f64',
          700: '#cb1049',
          800: '#a8113e',
          900: '#8b1337',
          950: '#55031a',
        },
        secondary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#b9e5fe',
          300: '#7cd1fd',
          400: '#36bbfa',
          500: '#0ca1eb',
          600: '#0080c9',
          700: '#0166a3',
          800: '#065686',
          900: '#0b486f',
          950: '#072e4a',
        },
        accent: {
          50: '#fefce8',
          100: '#fef9c3',
          200: '#fef08a',
          300: '#fde047',
          400: '#facc15',
          500: '#eab308',
          600: '#ca8a04',
          700: '#a16207',
          800: '#854d0e',
          900: '#713f12',
          950: '#422006',
        },
        kawaii: {
          pink: '#FFB6C1',
          lavender: '#E6E6FA',
          mint: '#98FB98',
          peach: '#FFDAB9',
          sky: '#87CEEB',
          cream: '#FFFDD0',
        },
        mood: {
          ecstatic: '#FFD700',
          happy: '#98FB98',
          content: '#87CEEB',
          neutral: '#E6E6FA',
          sad: '#B0C4DE',
          worried: '#DDA0DD',
        },
      },
      fontFamily: {
        kawaii: ['Comic Sans MS', 'Chalkboard', 'cursive'],
        pixel: ['Press Start 2P', 'monospace'],
      },
      animation: {
        'bounce-slow': 'bounce 2s infinite',
        'pulse-glow': 'pulse-glow 2s ease-in-out infinite',
        'wiggle': 'wiggle 1s ease-in-out infinite',
        'float': 'float 3s ease-in-out infinite',
        'sparkle': 'sparkle 1.5s ease-in-out infinite',
      },
      keyframes: {
        'pulse-glow': {
          '0%, 100%': { boxShadow: '0 0 5px rgba(255, 105, 168, 0.5)' },
          '50%': { boxShadow: '0 0 20px rgba(255, 105, 168, 0.8)' },
        },
        'wiggle': {
          '0%, 100%': { transform: 'rotate(-3deg)' },
          '50%': { transform: 'rotate(3deg)' },
        },
        'float': {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' },
        },
        'sparkle': {
          '0%, 100%': { opacity: 1 },
          '50%': { opacity: 0.5 },
        },
      },
      boxShadow: {
        'kawaii': '0 4px 14px 0 rgba(255, 105, 168, 0.39)',
        'kawaii-lg': '0 10px 40px 0 rgba(255, 105, 168, 0.5)',
      },
      borderRadius: {
        'kawaii': '20px',
      },
    },
  },
  plugins: [],
};
