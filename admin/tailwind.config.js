/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        indigo: {
          950: '#16163A',
          900: '#2B2D6E',
        },
        coral: {
          500: '#FF6B4A',
        },
        teal: {
          500: '#0FB5A5',
        },
        surface: '#EEF1F8',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
