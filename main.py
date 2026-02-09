

import sys
import os

backend_path = os.path.join(os.path.dirname(__file__), 'backend')
sys.path.insert(0, backend_path)

from app import app

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)




    