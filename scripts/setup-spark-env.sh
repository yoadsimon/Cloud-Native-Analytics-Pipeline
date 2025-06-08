#!/bin/bash

# Setup Spark Development Environment
# Sets up Java and PySpark for local development

echo "🔧 Setting up Spark Development Environment"

# Set JAVA_HOME for OpenJDK 11
export JAVA_HOME=/opt/homebrew/opt/openjdk@11

# Add Java to PATH
export PATH="$JAVA_HOME/bin:$PATH"

# Set Spark environment variables
export SPARK_HOME=$(python3 -c "import pyspark; print(pyspark.__path__[0])")
export PYTHONPATH=$SPARK_HOME/python:$PYTHONPATH

# Configure Spark settings for local development
export SPARK_LOCAL_IP=127.0.0.1
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

echo "✅ Java version:"
java -version 2>&1 | head -1

echo ""
echo "✅ PySpark version:"
python3 -c "import pyspark; print(f'PySpark {pyspark.__version__}')"

echo ""
echo "✅ Environment variables set:"
echo "   JAVA_HOME: $JAVA_HOME"
echo "   SPARK_HOME: $SPARK_HOME"
echo "   PYSPARK_PYTHON: $PYSPARK_PYTHON"

echo ""
echo "🚀 Spark development environment is ready!"
echo "💡 To use this environment in your shell, run:"
echo "   source scripts/setup-spark-env.sh" 