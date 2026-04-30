import type { Config } from 'tailwindcss'

const config: Config = {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      fontSize: {
        xs:   ['0.8rem',   { lineHeight: '1.4' }],
        sm:   ['1rem',     { lineHeight: '1.5' }],
        base: ['1.13rem',  { lineHeight: '1.6' }],
        lg:   ['1.38rem',  { lineHeight: '1.5' }],
        xl:   ['1.69rem',  { lineHeight: '1.4' }],
      },
      colors: {
        brand: {
          50:  '#f8f0fd',
          100: '#edd5f8',
          200: '#d8a8f0',
          300: '#be79e4',
          400: '#a96bd0',
          500: '#9561ab',
          600: '#7a4e90',
          700: '#603c72',
          800: '#472a54',
          900: '#2e1a37',
          950: '#1a0d20',
        },
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}

export default config
