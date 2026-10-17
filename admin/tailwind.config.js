/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          dark: '#16163A',
          indigo: '#2B2D6E',
          coral: '#FF6B4A',
          teal: '#0FB5A5',
          green: '#15803D',
          amber: '#F5A524',
          slate: '#64748B',
          surface: '#EEF1F8',
        }
      }
    },
  },
  plugins: [],
}
