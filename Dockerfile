FROM python:3.10-slim
WORKDIR /app

RUN pip install --upgrade pip
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY templates/ ./templates/
COPY . .

EXPOSE 5000
CMD ["python", "app_web.py"]