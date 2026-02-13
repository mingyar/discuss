/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./lib/discuss_web/**/*.html.eex",
    "./lib/discuss_web/**/*.html.heex",
    "./web/templates/**/*.html.eex",
    "./web/views/**/*.ex",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
