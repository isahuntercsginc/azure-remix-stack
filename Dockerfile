# base node image
FROM node:16-bullseye-slim as base

# set for base and all layer that inherit from it
ENV NODE_ENV production

# Install openssl for Prisma
RUN apt-get update && apt-get install -y openssl

# Install all node_modules, including dev dependencies
FROM base as deps

WORKDIR /csgCloudLensStudio

ADD package.json package-lock.json ./
RUN npm install --omit=dev

# Setup production node_modules
FROM base as production-deps

WORKDIR /csgCloudLensStudio

COPY --from=deps //node_modules //node_modules
ADD package.json package-lock.json ./
RUN npm prune --production

# Build the app
FROM base as build

WORKDIR /csgCloudLensStudio

COPY --from=deps //node_modules //node_modules

ADD prisma .
RUN npx prisma generate

ADD . .
RUN npm run build

# Finally, build the production image with minimal footprint
FROM base

WORKDIR /csgCloudLensStudio

COPY --from=production-deps //node_modules //node_modules
COPY --from=build //node_modules/.prisma //node_modules/.prisma

COPY --from=build //build //build
COPY --from=build //public //public
ADD . .

CMD ["npm", "start"]
