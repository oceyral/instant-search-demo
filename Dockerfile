FROM node:9.11.2-alpine

COPY --chown=node:node package.json package-lock.json /home/node/
USER node
WORKDIR /home/node

RUN npm install

COPY . /home/node/

EXPOSE 3000

CMD ["npm", "start"]
