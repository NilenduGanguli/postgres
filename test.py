import psycopg2
import sys

# --- Connection Parameters ---
# These should match your docker run command
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "document_services"
DB_USER = "admin"
DB_PASS = "password123"
# -------------------------------

print(f"Attempting to connect to {DB_USER}@{DB_HOST}:{DB_PORT}...")

try:
    # 1. Attempt to connect
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        host=DB_HOST,
        port=DB_PORT
    )
    
    # 2. If connection is successful, create a cursor
    print("✅ Connection Successful!")
    cur = conn.cursor()
    
    # 3. Execute a test query
    print("Executing 'SELECT version();'...")
    cur.execute("SELECT version();")
    
    # 4. Fetch and print the result
    db_version = cur.fetchone()
    print("\n--- Database Version ---")
    print(db_version[0])
    print("--------------------------")
    
    # 5. Clean up and close connections
    cur.close()
    conn.close()
    
    print("\n✅ Test Passed: Successfully connected and queried the database.")

except psycopg2.OperationalError as e:
    # This block catches common connection errors
    print("\n❌ TEST FAILED: Could not connect to the database.")
    print("Error:", e)
    print("\nTroubleshooting Tips:")
    print("  1. Is the Docker container running? (Check with 'docker ps')")
    print("  2. Did you map the port correctly? (e.g., '-p 5432:5432')")
    print("  3. Are the credentials in this script exactly matching your '-e' flags?")
    sys.exit(1) # Exit with an error code

except Exception as e:
    # Catch any other unexpected errors
    print(f"\n❌ An unexpected error occurred: {e}")
    sys.exit(1)
