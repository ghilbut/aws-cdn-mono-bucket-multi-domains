FROM node:14.18.1-alpine3.14 as ev1-build
WORKDIR /app
COPY ev1 .
RUN yarn \
 && yarn build

FROM node:14.18.1-alpine3.14 as ev1x-build
WORKDIR /app
COPY ev1x .
RUN yarn \
 && yarn build

FROM node:14.18.1-alpine3.14 as ev1y-build
WORKDIR /app
COPY ev1y .
RUN yarn \
 && yarn build

FROM nginx:1.21.4-alpine
RUN mkdir /app
COPY nginx/docker.conf /etc/nginx/nginx.conf
COPY --from=ev1-build  /app/dist /app/ev1
COPY --from=ev1x-build /app/dist /app/ev1x
COPY --from=ev1y-build /app/dist /app/ev1y
