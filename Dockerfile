FROM node:22-alpine
RUN apk add --no-cache wget

#Тут можна було б ще створити non-root користувача для запуску, але це простий веб-додаток
#Вирішив залишити Dockerfile мінімалістичним (без юзерів, dev/prod стейджів, білду статичних файлів і тд)
#
#RUN addgroup -S app -g 1001 \
#    && adduser -S app -u 1001 -G app

WORKDIR /app

COPY package*.json ./
RUN npm ci

#COPY --chown=app:app . .
COPY . .

EXPOSE 5173

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:5173/ || exit 1

CMD npm run dev
