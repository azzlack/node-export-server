FROM node:18-slim as base

# Build application
FROM base as build

WORKDIR /app

COPY package.json package-lock.json .puppeteerrc.cjs ./

RUN npm ci --ignore-scripts

COPY . .

RUN npm run build

# Create runtime image with only the necessary files
FROM base as runtime

ENV NODE_ENV=production
ENV OTHER_BROWSER_SHELL_MODE=false

RUN apt update -y && \
    apt-get install --no-install-recommends -y ca-certificates fonts-liberation libappindicator3-1 libasound2 libatk-bridge2.0-0 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 lsb-release wget xdg-utils && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/package.json /app/package-lock.json /app/.puppeteerrc.cjs /app/
RUN npm ci --ignore-scripts && \
    npx puppeteer browsers install chrome

COPY --from=build /app/dist/index.esm.mjs /app/dist/index.esm.mjs
COPY --from=build /app/templates /app/templates
COPY --from=build /app/public /app/public
COPY --from=build /app/msg /app/msg
COPY --from=build /app/bin/cli.docker.mjs /app/bin/cli.docker.mjs

EXPOSE 8080

ENTRYPOINT [ "node", "./bin/cli.docker.mjs", "--enableServer", "1", "--logLevel", "2", "--port", "8080" ]