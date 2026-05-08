# Use the official Python image as the base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy requirement first for better Docker layer caching
COPY app/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

#Copy application code
COPY app/ .

# Create a non-root user
RUN addgroup --system appgroup && \
adduser --system --ingroup appgroup appuser

#Switch to non-root user
USER appuser

# Expose port 80
EXPOSE 80

# CMD to run the Python script
CMD ["python", "main.py"]