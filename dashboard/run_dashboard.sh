#!/bin/bash

# Cloud-Native Analytics Dashboard Startup Script
# Launches the Streamlit dashboard with proper configuration

set -e

echo "🚀 Starting Cloud-Native Analytics Dashboard..."
echo "=============================================="

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📋 Installing dependencies..."
pip install -r requirements.txt

# Copy environment variables if .env doesn't exist
if [ ! -f ".env" ]; then
    echo "⚙️ Creating .env file from template..."
    cp env_example.txt .env
    echo "📝 Please edit .env file with your Redshift password if needed"
fi

# Launch Streamlit dashboard
echo "🎯 Launching dashboard on http://localhost:8501"
echo "=============================================="
echo ""
echo "📊 Dashboard Features:"
echo "   • Real-time Redshift connectivity"
echo "   • Interactive business analytics"
echo "   • KPI monitoring and trends"
echo "   • Data quality validation"
echo ""
echo "🔧 Controls:"
echo "   • Use sidebar to refresh data"
echo "   • Check connection status"
echo "   • View detailed data tables"
echo ""
echo "To stop the dashboard, press Ctrl+C"
echo "=============================================="

# Start Streamlit
streamlit run app.py \
    --server.port 8501 \
    --server.address 0.0.0.0 \
    --browser.gatherUsageStats false \
    --theme.base light 