import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#FFF4ED',
          100: '#FFE6D5',
          200: '#FECCAA',
          300: '#FDAB74',
          400: '#FB8A3C',
          500: '#FF6B35',
          600: '#E04F12',
          700: '#B93A0E',
          800: '#932F14',
          900: '#782913',
        },
      },
    },
  },
  plugins: [],
};
export default config;
