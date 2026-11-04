FROM swipl:stable

WORKDIR /app

COPY . .

EXPOSE 8080

CMD ["swipl", "server.pl", "--port=8080", "--kb=data/toy/toy_kb.pl"]
