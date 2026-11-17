FROM swipl:stable
WORKDIR /app
COPY towerofhanoiSakura.pl .
ENV PORT=10000
EXPOSE 10000
CMD ["swipl", "towerofhanoiSakura.pl"]
