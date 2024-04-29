# base stage to have pnpm installed
FROM node:18.18.2-alpine AS base
RUN npm i -g pnpm

# development stage
FROM base AS development

# Set environment variables
ARG APP
ARG NODE_ENV=development
ARG DB_HOST
ARG DB_PORT
ARG DB_NAME
ARG DB_USER
ARG DB_PASSWORD
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG GOOGLE_CLIENT_ID
ARG GOOGLE_CLIENT_SECRET

ENV NODE_ENV=${NODE_ENV}
ENV PORT 4001
WORKDIR /usr/src/app
COPY package.json pnpm-lock.yaml ./
COPY node_modules node_modules
RUN pnpm i --frozen-lockfile
COPY apps apps
COPY libs libs
COPY tsconfig.build.json tsconfig.build.json
COPY tsconfig.json tsconfig.json
COPY nest-cli.json nest-cli.json
COPY webpack.config.ts webpack.config.ts
COPY .env.docker .env
RUN pnpm run build ${APP}

# production stage
FROM base AS production
ARG APP
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
WORKDIR /usr/src/app
COPY package.json pnpm-lock.yaml ./
COPY node_modules node_modules
RUN pnpm install --production
COPY --from=development /usr/src/app/dist ./dist

# Add an env to save ARG
ENV APP_MAIN_FILE=dist/apps/${APP}/main
CMD node ${APP_MAIN_FILE}