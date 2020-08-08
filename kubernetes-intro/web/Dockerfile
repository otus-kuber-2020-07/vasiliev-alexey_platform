FROM python:3.8-alpine
RUN addgroup -S appuser && adduser -S appuser -G appuser -u 1001
USER appuser
WORKDIR /app
COPY app/* /app
EXPOSE 8000
CMD python -m http.server