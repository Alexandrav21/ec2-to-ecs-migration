"""
Legacy Flask Application
A simple Python Flask API running on EC2 behind Nginx.
This is the "before" state that students will migrate to ECS.
"""

import os
import logging
from datetime import datetime
from flask import Flask, jsonify, request
from werkzeug.exceptions import BadRequest

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# App metadata
APP_NAME = os.getenv('APP_NAME', 'legacy-api')
APP_VERSION = os.getenv('APP_VERSION', '1.0.0')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'production')

# In-memory storage (realistic legacy behavior)
products_db = {
    1: {"id": 1, "name": "Widget A", "price": 29.99, "stock": 100},
    2: {"id": 2, "name": "Widget B", "price": 39.99, "stock": 50},
    3: {"id": 3, "name": "Widget C", "price": 49.99, "stock": 75},
}

orders_db = []
order_counter = 1


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": APP_NAME,
        "version": APP_VERSION,
        "environment": ENVIRONMENT
    }), 200


@app.route('/api/v1/products', methods=['GET'])
def get_products():
    """Get all products"""
    logger.info("GET /api/v1/products")
    return jsonify({
        "products": list(products_db.values()),
        "count": len(products_db)
    }), 200


@app.route('/api/v1/products/<int:product_id>', methods=['GET'])
def get_product(product_id):
    """Get a specific product"""
    logger.info(f"GET /api/v1/products/{product_id}")
    product = products_db.get(product_id)
    if not product:
        return jsonify({"error": "Product not found"}), 404
    return jsonify(product), 200


@app.route('/api/v1/orders', methods=['GET'])
def get_orders():
    """Get all orders"""
    logger.info("GET /api/v1/orders")
    return jsonify({
        "orders": orders_db,
        "count": len(orders_db)
    }), 200


@app.route('/api/v1/orders', methods=['POST'])
def create_order():
    """Create a new order"""
    global order_counter
    logger.info("POST /api/v1/orders")
    
    try:
        data = request.get_json()
        if not data:
            raise BadRequest("No JSON data provided")
        
        product_id = data.get('product_id')
        quantity = data.get('quantity', 1)
        
        if not product_id:
            raise BadRequest("product_id is required")
        
        product = products_db.get(product_id)
        if not product:
            return jsonify({"error": "Product not found"}), 404
        
        if quantity > product['stock']:
            return jsonify({"error": "Insufficient stock"}), 400
        
        order = {
            "id": order_counter,
            "product_id": product_id,
            "product_name": product['name'],
            "quantity": quantity,
            "total_price": product['price'] * quantity,
            "created_at": datetime.utcnow().isoformat()
        }
        
        orders_db.append(order)
        products_db[product_id]['stock'] -= quantity
        order_counter += 1
        
        logger.info(f"Order created: {order['id']}")
        return jsonify(order), 201
        
    except BadRequest as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error creating order: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@app.route('/api/v1/stats', methods=['GET'])
def get_stats():
    """Get application statistics"""
    logger.info("GET /api/v1/stats")
    return jsonify({
        "total_products": len(products_db),
        "total_orders": len(orders_db),
        "total_revenue": sum(order['total_price'] for order in orders_db),
        "timestamp": datetime.utcnow().isoformat()
    }), 200


@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({"error": "Internal server error"}), 500


if __name__ == '__main__':
    # This is for development only
    # Production uses gunicorn via wsgi.py
    app.run(host='0.0.0.0', port=5000, debug=False)
