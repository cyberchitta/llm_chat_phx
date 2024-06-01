// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/llm_chat_web.ex",
    "../lib/llm_chat_web/**/*.*ex",
  ],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
      },
    },
  },
  daisyui: {
    themes: [
      {
        rosepine: {
          primary: "#c4a7e7",
          secondary: "#ebbcba",
          accent: "#f6c177",
          neutral: "#191724",
          "base-100": "#1f1d2e",
          info: "#31748f",
          success: "#9ccfd8",
          warning: "#f6c177",
          error: "#eb6f92",
        },
        "rosepine-moon": {
          primary: "#c4a7e7",
          secondary: "#ea9a97",
          accent: "#c4a7e7",
          neutral: "#2a273f",
          "base-100": "#232136",
          info: "#3e8fb0",
          success: "#9ccfd8",
          warning: "#f6c177",
          error: "#eb6f92",
        },
        "rosepine-dawn": {
          primary: "#907aa9",
          secondary: "#d7827e",
          accent: "#907aa9",
          neutral: "#faf4ed",
          "base-100": "#fffaf3",
          info: "#286983",
          success: "#56949f",
          warning: "#ea9d34",
          error: "#b4637a",
        },
      },
    ],
  },
  plugins: [
    require("daisyui"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            let size = theme("spacing.6");
            if (name.endsWith("-mini")) {
              size = theme("spacing.5");
            } else if (name.endsWith("-micro")) {
              size = theme("spacing.4");
            }
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: size,
              height: size,
            };
          },
        },
        { values }
      );
    }),
  ],
};
